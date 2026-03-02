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

    match mode {
        "benchmark" => {
            let kernel = library.get_function("ca_count_bounded", None).unwrap();
            let pipeline = device.new_compute_pipeline_state_with_function(&kernel).unwrap();
            run_benchmark(&device, &pipeline);
        }
        "search" => {
            let kernel = library.get_function("ca_find_doublers", None).unwrap();
            let pipeline = device.new_compute_pipeline_state_with_function(&kernel).unwrap();
            run_full_search(&device, &pipeline);
        }
        _ => {
            eprintln!("Usage: gpu_benchmark [benchmark|search]");
            std::process::exit(1);
        }
    }
}

fn run_benchmark(device: &Device, pipeline: &ComputePipelineState) {
    let max_threads = pipeline.max_total_threads_per_threadgroup();
    let steps: u64 = 20;
    let max_width: u64 = 5;

    for &batch_size in &[1_000_000u64, 10_000_000, 100_000_000, 333_333_333] {
        let params: [u64; 4] = [0, batch_size, steps, max_width];
        let params_buf = device.new_buffer_with_data(
            params.as_ptr() as *const _,
            (4 * std::mem::size_of::<u64>()) as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let counter_buf = device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        unsafe { *(counter_buf.contents() as *mut u32) = 0; }

        let command_queue = device.new_command_queue();
        let command_buffer = command_queue.new_command_buffer();
        let encoder = command_buffer.new_compute_command_encoder();
        encoder.set_compute_pipeline_state(pipeline);
        encoder.set_buffer(0, Some(&params_buf), 0);
        encoder.set_buffer(1, Some(&counter_buf), 0);
        encoder.dispatch_threads(
            MTLSize::new(batch_size, 1, 1),
            MTLSize::new(max_threads as u64, 1, 1),
        );
        encoder.end_encoding();

        let t0 = Instant::now();
        command_buffer.commit();
        command_buffer.wait_until_completed();
        let elapsed = t0.elapsed();

        let bounded = unsafe { *(counter_buf.contents() as *const u32) } as u64;
        let effective = batch_size * 3;
        let rate = effective as f64 / elapsed.as_secs_f64();
        println!(
            "\n=== {}M effective: {:.3}s | {} bounded | {:.0}M/s | est {:.1}h ===",
            effective / 1_000_000, elapsed.as_secs_f64(), bounded,
            rate / 1e6, 7625597484987.0 / rate / 3600.0,
        );
    }
}

fn run_full_search(device: &Device, pipeline: &ComputePipelineState) {
    let max_threads = pipeline.max_total_threads_per_threadgroup();
    let total_rules: u64 = 7625597484987;
    let total_mult3 = (total_rules + 2) / 3;

    // check_steps=200, initial_max_width=5
    let check_steps: u64 = 200;
    let initial_max: u64 = 5;

    // GPU batch: 200M rules per dispatch
    let batch_size: u64 = 200_000_000;
    let max_doublers_per_batch: u64 = 10_000_000;
    let n_batches = (total_mult3 + batch_size - 1) / batch_size;

    let out_dir = "search_results_gpu";
    fs::create_dir_all(out_dir).unwrap();

    // Resume support
    let progress_file = format!("{}/progress.txt", out_dir);
    let mut start_batch: u64 = 0;
    let mut total_bounded: u64 = 0;
    let mut total_doublers: u64 = 0;
    if let Ok(content) = fs::read_to_string(&progress_file) {
        for line in content.lines() {
            let parts: Vec<&str> = line.split_whitespace().collect();
            if parts.len() >= 3 {
                start_batch = parts[0].parse().unwrap_or(0);
                total_bounded = parts[1].parse().unwrap_or(0);
                total_doublers = parts[2].parse().unwrap_or(0);
            }
        }
        if start_batch > 0 {
            println!("Resuming from batch {}/{} ({} bounded, {} doublers so far)",
                start_batch, n_batches, total_bounded, total_doublers);
        }
    }

    println!("Full doubler search: {} rules, {} multiples of 3", total_rules, total_mult3);
    println!("Batches: {} x {}M threads ({}M effective), {} steps",
        n_batches, batch_size / 1_000_000, batch_size * 3 / 1_000_000, check_steps);
    println!("Output: {}/\n", out_dir);

    // Allocate GPU buffers
    let params_buf = device.new_buffer(
        (4 * std::mem::size_of::<u64>()) as u64,
        MTLResourceOptions::StorageModeShared,
    );
    let doubler_count_buf = device.new_buffer(4, MTLResourceOptions::StorageModeShared);
    let doubler_output_buf = device.new_buffer(
        max_doublers_per_batch * 8,
        MTLResourceOptions::StorageModeShared,
    );
    let bounded_count_buf = device.new_buffer(4, MTLResourceOptions::StorageModeShared);

    let command_queue = device.new_command_queue();
    let search_start = Instant::now();

    // Doubler output file (append mode)
    let doublers_path = format!("{}/doublers.txt", out_dir);
    let mut doublers_file = fs::OpenOptions::new()
        .create(true)
        .append(true)
        .open(&doublers_path)
        .expect("Cannot open doublers file");

    for batch_idx in start_batch..n_batches {
        let batch_start_rule = batch_idx * batch_size * 3;
        let rules_this_batch = batch_size.min(total_mult3 - batch_idx * batch_size);

        // Set params: [start_rule, count, check_steps, initial_max_width]
        let params: [u64; 4] = [batch_start_rule, rules_this_batch, check_steps, initial_max];
        unsafe {
            let ptr = params_buf.contents() as *mut u64;
            for i in 0..4 { *ptr.add(i) = params[i]; }
            *(doubler_count_buf.contents() as *mut u32) = 0;
            *(bounded_count_buf.contents() as *mut u32) = 0;
        }

        let command_buffer = command_queue.new_command_buffer();
        let encoder = command_buffer.new_compute_command_encoder();
        encoder.set_compute_pipeline_state(pipeline);
        encoder.set_buffer(0, Some(&params_buf), 0);
        encoder.set_buffer(1, Some(&doubler_count_buf), 0);
        encoder.set_buffer(2, Some(&doubler_output_buf), 0);
        encoder.set_buffer(3, Some(&bounded_count_buf), 0);
        encoder.dispatch_threads(
            MTLSize::new(rules_this_batch, 1, 1),
            MTLSize::new(max_threads as u64, 1, 1),
        );
        encoder.end_encoding();

        let t0 = Instant::now();
        command_buffer.commit();
        command_buffer.wait_until_completed();
        let gpu_time = t0.elapsed();

        // Read results
        let batch_bounded = unsafe { *(bounded_count_buf.contents() as *const u32) } as u64;
        let batch_doublers = unsafe { *(doubler_count_buf.contents() as *const u32) } as u64;
        total_bounded += batch_bounded;
        total_doublers += batch_doublers;

        // Save doublers (rare — small output)
        if batch_doublers > 0 {
            let ptr = doubler_output_buf.contents() as *const u64;
            for i in 0..batch_doublers.min(max_doublers_per_batch) as usize {
                let rule = unsafe { *ptr.add(i) };
                writeln!(doublers_file, "{}", rule).unwrap();
            }
            doublers_file.flush().unwrap();
        }

        // Save progress
        {
            let next_batch = batch_idx + 1;
            fs::write(&progress_file, format!("{} {} {}\n", next_batch, total_bounded, total_doublers)).unwrap();
        }

        // Progress
        let batches_done = (batch_idx - start_batch + 1) as f64;
        let elapsed_total = search_start.elapsed().as_secs_f64();
        let batches_remaining = (n_batches - batch_idx - 1) as f64;
        let eta_s = elapsed_total / batches_done * batches_remaining;
        let rate = (rules_this_batch * 3) as f64 / gpu_time.as_secs_f64();
        let pct = (batch_idx + 1) as f64 / n_batches as f64 * 100.0;

        println!(
            "Batch {}/{} ({:.2}%): {} bnd +{} dbl in {:.2}s | Tot: {} bnd {} dbl | {:.0}M/s | ETA: {:.1}h",
            batch_idx + 1, n_batches, pct,
            batch_bounded, batch_doublers, gpu_time.as_secs_f64(),
            total_bounded, total_doublers, rate / 1e6,
            eta_s / 3600.0,
        );
    }

    let total_time = search_start.elapsed();
    println!("\n=== SEARCH COMPLETE ===");
    println!("Total bounded: {}", total_bounded);
    println!("Total doublers: {}", total_doublers);
    println!("Time: {:.1}h ({:.0}s)", total_time.as_secs_f64() / 3600.0, total_time.as_secs_f64());
    println!("Rate: {:.0}M rules/s", total_rules as f64 / total_time.as_secs_f64() / 1e6);
    println!("Doublers saved to: {}", doublers_path);
}
