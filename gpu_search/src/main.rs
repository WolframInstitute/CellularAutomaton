use metal::*;
use std::time::Instant;

fn main() {
    let device = Device::system_default().expect("No Metal device found");
    println!("GPU: {}", device.name());

    let shader_src = include_str!("../ca_search.metal");
    let library = device
        .new_library_with_source(shader_src, &CompileOptions::new())
        .expect("Failed to compile Metal shader");
    let kernel = library
        .get_function("ca_find_doublers", None)
        .expect("Function not found");
    let pipeline = device
        .new_compute_pipeline_state_with_function(&kernel)
        .expect("Failed to create pipeline");
    let max_threads = pipeline.max_total_threads_per_threadgroup();

    // Search space: 3^19 = 1,162,261,467 free-digit combinations
    // 8 fixed digits + 19 free digits = 27 total
    let total: u64 = 1_162_261_467; // 3^19
    let batch_size: u64 = 100_000_000;
    let n_batches = (total + batch_size - 1) / batch_size;
    let max_output: u64 = 100_000;

    println!("Search space: 3^19 = {} ({:.2}B)", total, total as f64 / 1e9);
    println!("Batches: {} x {}M", n_batches, batch_size / 1_000_000);

    // Allocate buffers
    let params_buf = device.new_buffer(32, MTLResourceOptions::StorageModeShared);
    let counter_buf = device.new_buffer(4, MTLResourceOptions::StorageModeShared);
    let output_buf = device.new_buffer(
        max_output * 8,
        MTLResourceOptions::StorageModeShared,
    );

    let command_queue = device.new_command_queue();
    let t0 = Instant::now();
    let mut all_doublers: Vec<u64> = Vec::new();

    for batch in 0..n_batches {
        let start = batch * batch_size;
        let count = batch_size.min(total - start);

        let params: [u64; 4] = [start, count, 0, 0];
        unsafe {
            let ptr = params_buf.contents() as *mut u64;
            for i in 0..4 { *ptr.add(i) = params[i]; }
            *(counter_buf.contents() as *mut u32) = 0;
        }

        let cb = command_queue.new_command_buffer();
        let enc = cb.new_compute_command_encoder();
        enc.set_compute_pipeline_state(&pipeline);
        enc.set_buffer(0, Some(&params_buf), 0);
        enc.set_buffer(1, Some(&counter_buf), 0);
        enc.set_buffer(2, Some(&output_buf), 0);
        enc.dispatch_threads(
            MTLSize::new(count, 1, 1),
            MTLSize::new(max_threads as u64, 1, 1),
        );
        enc.end_encoding();

        let bt = Instant::now();
        cb.commit();
        cb.wait_until_completed();
        let elapsed = bt.elapsed();

        let found = unsafe { *(counter_buf.contents() as *const u32) } as u64;
        let ptr = output_buf.contents() as *const u64;
        for i in 0..found.min(max_output) as usize {
            let rule = unsafe { *ptr.add(i) };
            all_doublers.push(rule);
        }

        let rate = (count as f64) / elapsed.as_secs_f64();
        let pct = (start + count) as f64 / total as f64 * 100.0;
        println!(
            "Batch {}/{}: {} doublers in {:.2}s ({:.0}M combos/s) [{:.1}%]",
            batch + 1, n_batches, found, elapsed.as_secs_f64(),
            rate / 1e6, pct,
        );
    }

    let total_time = t0.elapsed();
    all_doublers.sort_unstable();
    all_doublers.dedup();

    println!("\n=== SEARCH COMPLETE ===");
    println!("Total doublers found: {}", all_doublers.len());
    println!("Time: {:.1}s", total_time.as_secs_f64());
    println!("Rate: {:.0}M combos/s", total as f64 / total_time.as_secs_f64() / 1e6);

    // Print all doublers
    println!("\nDoubler rules:");
    for (i, &rule) in all_doublers.iter().enumerate() {
        println!("  {}: {}", i + 1, rule);
    }

    // Save to file
    let output = all_doublers.iter()
        .map(|r| r.to_string())
        .collect::<Vec<_>>()
        .join("\n");
    std::fs::write("doublers_found.txt", &output).unwrap();
    println!("\nSaved to doublers_found.txt");
}
