use metal::*;
use std::time::Instant;

fn main() {
    let device = Device::system_default().expect("No Metal device found");
    println!("GPU: {}", device.name());
    println!("Max threads per threadgroup: {}", device.max_threads_per_threadgroup().width);

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
    println!("Max threads per threadgroup (pipeline): {}", max_threads);

    // Benchmark parameters
    let steps: u64 = 20;
    let max_width: u64 = 5;

    for &batch_size in &[1_000_000u64, 10_000_000, 100_000_000, 333_333_333] {
        let start_rule: u64 = 0; // first multiple of 3
        let count = batch_size;

        // Create params buffer: [start_rule, count, steps, max_width]
        let params: [u64; 4] = [start_rule, count, steps, max_width];
        let params_buf = device.new_buffer_with_data(
            params.as_ptr() as *const _,
            (4 * std::mem::size_of::<u64>()) as u64,
            MTLResourceOptions::StorageModeShared,
        );

        // Create results buffer
        let results_size = (count as usize) * std::mem::size_of::<u32>();
        let results_buf = device.new_buffer(
            results_size as u64,
            MTLResourceOptions::StorageModeShared,
        );

        // Dispatch GPU compute
        let command_queue = device.new_command_queue();
        let command_buffer = command_queue.new_command_buffer();
        let encoder = command_buffer.new_compute_command_encoder();

        encoder.set_compute_pipeline_state(&pipeline);
        encoder.set_buffer(0, Some(&params_buf), 0);
        encoder.set_buffer(1, Some(&results_buf), 0);

        let threadgroup_size = MTLSize::new(max_threads as u64, 1, 1);
        let grid_size = MTLSize::new(count, 1, 1);
        encoder.dispatch_threads(grid_size, threadgroup_size);
        encoder.end_encoding();

        let t0 = Instant::now();
        command_buffer.commit();
        command_buffer.wait_until_completed();
        let elapsed = t0.elapsed();

        // Count bounded rules
        let results_ptr = results_buf.contents() as *const u32;
        let mut bounded_count: u64 = 0;
        for i in 0..count as usize {
            unsafe {
                if *results_ptr.add(i) != 0 {
                    bounded_count += 1;
                }
            }
        }

        // Report (count is rules tested on GPU, effective = count*3 total rules covered)
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
