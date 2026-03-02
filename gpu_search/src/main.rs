use metal::*;
use std::fs;
use std::io::Write;
use std::time::Instant;

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let mode = args.get(1).map(|s| s.as_str()).unwrap_or("benchmark");

    let device = Device::system_default().expect("No Metal device found");
    println!("GPU: {}", device.name());

    // Compile shader
    let shader_src = include_str!("../ca_search.metal");
    let library = device
        .new_library_with_source(shader_src, &CompileOptions::new())
        .expect("Failed to compile Metal shader");
    let kernel = library
        .get_function("ca_bounded_search", None)
        .expect("Function not found");
    let pipeline = device
        .new_compute_pipeline_state_with_function(&kernel)
        .expect("Failed to create pipeline");

    let max_threads = pipeline.max_total_threads_per_threadgroup();
    println!("Max threads per threadgroup: {}", max_threads);

    match mode {
        "benchmark" => run_benchmark(&device, &pipeline, max_threads),
        "search" => run_full_search(&device, &pipeline, max_threads),
        _ => {
            eprintln!("Usage: gpu_benchmark [benchmark|search]");
            std::process::exit(1);
        }
    }
}

fn run_benchmark(device: &Device, pipeline: &ComputePipelineState, max_threads: u64) {
    let steps: u64 = 20;
    let max_width: u64 = 5;
    // Max bounded per batch (generous upper bound)
    let max_output: u64 = 50_000_000;

    for &batch_size in &[1_000_000u64, 10_000_000, 100_000_000, 333_333_333] {
        let start_rule: u64 = 0;
        let count = batch_size;

        // Params buffer
        let params: [u64; 4] = [start_rule, count, steps, max_width];
        let params_buf = device.new_buffer_with_data(
            params.as_ptr() as *const _,
            (4 * std::mem::size_of::<u64>()) as u64,
            MTLResourceOptions::StorageModeShared,
        );

        // Atomic counter buffer (single u32)
        let counter_buf = device.new_buffer(
            std::mem::size_of::<u32>() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        unsafe {
            *(counter_buf.contents() as *mut u32) = 0;
        }

        // Output buffer for bounded rule numbers
        let output_buf = device.new_buffer(
            max_output * std::mem::size_of::<u64>() as u64,
            MTLResourceOptions::StorageModeShared,
        );

        let command_queue = device.new_command_queue();
        let command_buffer = command_queue.new_command_buffer();
        let encoder = command_buffer.new_compute_command_encoder();
        encoder.set_compute_pipeline_state(pipeline);
        encoder.set_buffer(0, Some(&params_buf), 0);
        encoder.set_buffer(1, Some(&counter_buf), 0);
        encoder.set_buffer(2, Some(&output_buf), 0);
        let threadgroup_size = MTLSize::new(max_threads, 1, 1);
        let grid_size = MTLSize::new(count, 1, 1);
        encoder.dispatch_threads(grid_size, threadgroup_size);
        encoder.end_encoding();

        let t0 = Instant::now();
        command_buffer.commit();
        command_buffer.wait_until_completed();
        let elapsed = t0.elapsed();

        // Read atomic counter for bounded count
        let bounded_count = unsafe { *(counter_buf.contents() as *const u32) } as u64;

        let effective_rules = count * 3;
        let rate = effective_rules as f64 / elapsed.as_secs_f64();
        let full_search_hours = 7625597484987.0 / rate / 3600.0;

        println!(
            "\n=== GPU Benchmark: {}M effective rules ===",
            effective_rules / 1_000_000
        );
        println!("GPU time: {:.3}s", elapsed.as_secs_f64());
        println!("Bounded found: {}", bounded_count);
        println!("Rate: {:.1}M rules/s", rate / 1e6);
        println!("Estimated full search: {:.1} hours", full_search_hours);
    }
}

fn run_full_search(device: &Device, pipeline: &ComputePipelineState, max_threads: u64) {
    let steps: u64 = 20;
    let max_width: u64 = 5;
    let total_rules: u64 = 7625597484987; // 3^27
    let total_multiples_of_3 = (total_rules + 2) / 3;

    // GPU batch size: 200M rules per dispatch (600M effective)
    let batch_size: u64 = 200_000_000;
    let max_output_per_batch: u64 = 60_000_000; // upper bound for bounded per batch

    let n_batches = (total_multiples_of_3 + batch_size - 1) / batch_size;

    // Output directory
    let out_dir = "search_results_gpu";
    fs::create_dir_all(out_dir).expect("Failed to create output directory");

    // Check for resume
    let mut start_batch: u64 = 0;
    let mut total_bounded: u64 = 0;
    for b in 0..n_batches {
        let path = format!("{}/batch_{:06}.bin", out_dir, b);
        if std::path::Path::new(&path).exists() {
            let data = fs::read(&path).unwrap_or_default();
            total_bounded += (data.len() / 8) as u64; // u64 per rule
            start_batch = b + 1;
        } else {
            break;
        }
    }

    if start_batch > 0 {
        println!("Resuming from batch {}/{} ({} bounded so far)", start_batch, n_batches, total_bounded);
    }

    println!("Full search: {} total rules, {} multiples of 3", total_rules, total_multiples_of_3);
    println!("Batches: {} x {}M GPU threads = {}M effective per batch", n_batches, batch_size / 1_000_000, batch_size * 3 / 1_000_000);
    println!("Output: {}/\n", out_dir);

    let command_queue = device.new_command_queue();

    // Double buffer: create two sets of buffers for ping-pong
    let params_bufs: Vec<Buffer> = (0..2).map(|_| {
        device.new_buffer(
            (4 * std::mem::size_of::<u64>()) as u64,
            MTLResourceOptions::StorageModeShared,
        )
    }).collect();

    let counter_bufs: Vec<Buffer> = (0..2).map(|_| {
        device.new_buffer(
            std::mem::size_of::<u32>() as u64,
            MTLResourceOptions::StorageModeShared,
        )
    }).collect();

    let output_bufs: Vec<Buffer> = (0..2).map(|_| {
        device.new_buffer(
            max_output_per_batch * std::mem::size_of::<u64>() as u64,
            MTLResourceOptions::StorageModeShared,
        )
    }).collect();

    let search_start = Instant::now();
    let mut batch_start_time = Instant::now();

    // Track which buffer slot is being used for GPU vs CPU
    let mut gpu_slot = 0usize;
    let mut pending_batch: Option<u64> = None; // batch_idx being computed on GPU

    for batch_idx in start_batch..=n_batches {
        // Collect results from previous GPU dispatch (if any)
        if let Some(prev_batch) = pending_batch {
            // Wait for GPU to finish (should already be done if double-buffered well)
            // The command buffer commit/wait happened implicitly

            let cpu_slot = gpu_slot ^ 1; // previous slot
            let batch_elapsed = batch_start_time.elapsed();

            // Read atomic counter
            let bounded_count = unsafe {
                *(counter_bufs[cpu_slot].contents() as *const u32)
            } as u64;
            total_bounded += bounded_count;

            // Save bounded rules as binary (u64 array)
            if bounded_count > 0 {
                let output_ptr = output_bufs[cpu_slot].contents() as *const u64;
                let rules: Vec<u64> = (0..bounded_count as usize)
                    .map(|i| unsafe { *output_ptr.add(i) })
                    .collect();

                let path = format!("{}/batch_{:06}.bin", out_dir, prev_batch);
                let bytes: Vec<u8> = rules.iter()
                    .flat_map(|r| r.to_le_bytes())
                    .collect();
                fs::write(&path, bytes).expect("Failed to write batch");
            } else {
                // Write empty file to mark complete
                let path = format!("{}/batch_{:06}.bin", out_dir, prev_batch);
                fs::write(&path, &[]).expect("Failed to write batch");
            }

            // Progress
            let batches_done = prev_batch - start_batch + 1;
            let elapsed_total = search_start.elapsed().as_secs_f64();
            let eta_seconds = elapsed_total / batches_done as f64 * (n_batches - prev_batch - 1) as f64;
            let rules_this = batch_size.min(total_multiples_of_3 - prev_batch * batch_size) * 3;
            let rate = rules_this as f64 / batch_elapsed.as_secs_f64();
            let pct = (prev_batch + 1) as f64 / n_batches as f64 * 100.0;

            println!(
                "Batch {}/{} ({:.2}%): {} bounded in {:.2}s | Total: {} | Rate: {:.0}M/s | ETA: {:.1}h",
                prev_batch + 1, n_batches, pct,
                bounded_count, batch_elapsed.as_secs_f64(),
                total_bounded, rate / 1e6,
                eta_seconds / 3600.0,
            );
        }

        // Dispatch next batch (if not past the end)
        if batch_idx < n_batches {
            let batch_start_rule = batch_idx * batch_size * 3;
            let rules_this_batch = batch_size.min(total_multiples_of_3 - batch_idx * batch_size);

            // Set params in current GPU slot
            let params: [u64; 4] = [batch_start_rule, rules_this_batch, steps, max_width];
            unsafe {
                let ptr = params_bufs[gpu_slot].contents() as *mut u64;
                for i in 0..4 {
                    *ptr.add(i) = params[i];
                }
                // Zero the counter
                *(counter_bufs[gpu_slot].contents() as *mut u32) = 0;
            }

            // Dispatch
            let command_buffer = command_queue.new_command_buffer();
            let encoder = command_buffer.new_compute_command_encoder();
            encoder.set_compute_pipeline_state(pipeline);
            encoder.set_buffer(0, Some(&params_bufs[gpu_slot]), 0);
            encoder.set_buffer(1, Some(&counter_bufs[gpu_slot]), 0);
            encoder.set_buffer(2, Some(&output_bufs[gpu_slot]), 0);
            let threadgroup_size = MTLSize::new(max_threads, 1, 1);
            let grid_size = MTLSize::new(rules_this_batch, 1, 1);
            encoder.dispatch_threads(grid_size, threadgroup_size);
            encoder.end_encoding();

            batch_start_time = Instant::now();
            command_buffer.commit();
            command_buffer.wait_until_completed();

            pending_batch = Some(batch_idx);
            gpu_slot ^= 1; // swap slots for next iteration
        }
    }

    let total_time = search_start.elapsed();
    println!("\n=== SEARCH COMPLETE ===");
    println!("Total bounded rules: {}", total_bounded);
    println!("Total time: {:.1}h ({:.0}s)", total_time.as_secs_f64() / 3600.0, total_time.as_secs_f64());
    println!("Average rate: {:.0}M rules/s", total_rules as f64 / total_time.as_secs_f64() / 1e6);
    println!("Results in: {}/", out_dir);
}
