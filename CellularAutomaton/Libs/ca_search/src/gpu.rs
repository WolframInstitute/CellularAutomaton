//! Metal GPU-accelerated CA search engine.
//! Only available on macOS with the `gpu` feature enabled.

use metal::*;
use std::mem;

use crate::models::CAState;
use wolfram_library_link as wll;

const SHADER_SRC: &str = include_str!("../shaders/ca_search.metal");
const MAX_OUTPUT: u64 = 1_000_000;
const BATCH_SIZE: u64 = 1_000_000_000; // 1B rules per GPU dispatch

/// Metal GPU search engine. Caches compiled pipelines for reuse.
pub struct GpuSearchEngine {
    device: Device,
    queue: CommandQueue,
    exact_width_pipeline: ComputePipelineState,
    matching_pipeline: ComputePipelineState,
    bounded_pipeline: ComputePipelineState,
    refine_pipeline: ComputePipelineState,
    test_rules_pipeline: ComputePipelineState,
    #[allow(dead_code)]
    filter_width_list_pipeline: ComputePipelineState,
    random_search_pipeline: Option<ComputePipelineState>,
    search_free_pipeline: Option<ComputePipelineState>,
}

impl GpuSearchEngine {
    /// Initialize Metal device and compile shader pipelines.
    /// Returns None if Metal is not available.
    pub fn new() -> Option<Self> {
        let device = Device::system_default()?;
        let library = device
            .new_library_with_source(SHADER_SRC, &CompileOptions::new())
            .ok()?;

        let make_pipeline = |name: &str| -> Option<ComputePipelineState> {
            let func = library.get_function(name, None).ok()?;
            device.new_compute_pipeline_state_with_function(&func).ok()
        };

        let exact_width_pipeline = make_pipeline("ca_find_exact_width")?;
        let matching_pipeline = make_pipeline("ca_find_matching")?;
        let bounded_pipeline = make_pipeline("ca_find_bounded")?;
        let refine_pipeline = make_pipeline("ca_refine_doublers")?;
        let test_rules_pipeline = make_pipeline("ca_test_rules")?;
        let filter_width_list_pipeline = make_pipeline("ca_filter_width_list")?;
        // Random search is optional — may fail if MAX_TAPE is too large for GPU
        let random_search_pipeline = make_pipeline("ca_random_search");
        let search_free_pipeline = make_pipeline("ca_search_free");

        let queue = device.new_command_queue();

        Some(Self {
            device,
            queue,
            exact_width_pipeline,
            matching_pipeline,
            bounded_pipeline,
            refine_pipeline,
            test_rules_pipeline,
            filter_width_list_pipeline,
            random_search_pipeline,
            search_free_pipeline,
        })
    }

    /// Check if the search parameters are GPU-compatible.
    /// Currently: r=1 only, k<=4, tape_width <= 256.
    fn is_supported(k: u32, r: u32, tape_width: usize) -> bool {
        r == 1 && k <= 4 && tape_width <= 512
    }

    /// Create a Metal buffer from init cells.
    fn make_init_buffer(&self, init: &CAState) -> Buffer {
        let cells = &init.cells;
        let buf = self.device.new_buffer(
            cells.len() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        unsafe {
            let ptr = buf.contents() as *mut u8;
            for (i, &c) in cells.iter().enumerate() {
                *ptr.add(i) = c;
            }
        }
        buf
    }

    /// Find rules where final active width == target_width.
    /// Optimized: pre-allocates all buffers once, reuses across batches.
    pub fn find_exact_width_rules(
        &self,
        min_rule: u64,
        max_rule: u64,
        k: u32,
        r: u32,
        init: &CAState,
        steps: usize,
        target_width: usize,
    ) -> Option<Vec<u64>> {
        if !Self::is_supported(k, r, init.cells.len()) {
            return None;
        }

        let pipeline = &self.exact_width_pipeline;
        let max_threads = pipeline.max_total_threads_per_threadgroup();

        let total = max_rule - min_rule + 1;
        let n_batches = (total + BATCH_SIZE - 1) / BATCH_SIZE;

        let init_buf = self.make_init_buffer(init);
        // params: [start_rule, count, k, tape_width, steps, target_width]
        let params_buf = self.device.new_buffer(
            6 * mem::size_of::<u64>() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let counter_buf = self.device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        let output_buf = self.device.new_buffer(
            MAX_OUTPUT * 8,
            MTLResourceOptions::StorageModeShared,
        );

        let mut all_results: Vec<u64> = Vec::new();

        for batch in 0..n_batches {
            if wll::aborted() { break; }
            let start = min_rule + batch * BATCH_SIZE;
            let count = BATCH_SIZE.min(max_rule + 1 - start);

            unsafe {
                let ptr = params_buf.contents() as *mut u64;
                *ptr.add(0) = start;
                *ptr.add(1) = count;
                *ptr.add(2) = k as u64;
                *ptr.add(3) = init.cells.len() as u64;
                *ptr.add(4) = steps as u64;
                *ptr.add(5) = target_width as u64;
                *(counter_buf.contents() as *mut u32) = 0;
            }

            let cb = self.queue.new_command_buffer();
            let enc = cb.new_compute_command_encoder();
            enc.set_compute_pipeline_state(pipeline);
            enc.set_buffer(0, Some(&params_buf), 0);
            enc.set_buffer(1, Some(&init_buf), 0);
            enc.set_buffer(2, Some(&counter_buf), 0);
            enc.set_buffer(3, Some(&output_buf), 0);
            enc.dispatch_threads(
                MTLSize::new(count, 1, 1),
                MTLSize::new(max_threads as u64, 1, 1),
            );
            enc.end_encoding();

            cb.commit();
            cb.wait_until_completed();

            let found = unsafe { *(counter_buf.contents() as *const u32) } as u64;
            let ptr = output_buf.contents() as *const u64;
            for i in 0..found.min(MAX_OUTPUT) as usize {
                let rule = unsafe { *ptr.add(i) };
                all_results.push(rule);
            }
        }

        all_results.sort_unstable();
        all_results.dedup();
        Some(all_results)
    }

    /// Find rules where final state matches target exactly.
    /// Optimized: pre-allocates all buffers once, reuses across batches.
    pub fn find_matching_rules(
        &self,
        min_rule: u64,
        max_rule: u64,
        k: u32,
        r: u32,
        init: &CAState,
        steps: usize,
        target: &CAState,
    ) -> Option<Vec<u64>> {
        if !Self::is_supported(k, r, init.cells.len()) {
            return None;
        }

        let pipeline = &self.matching_pipeline;
        let max_threads = pipeline.max_total_threads_per_threadgroup();

        let total = max_rule - min_rule + 1;
        let n_batches = (total + BATCH_SIZE - 1) / BATCH_SIZE;

        // Pre-allocate all buffers once
        let init_buf = self.make_init_buffer(init);
        let target_buf = self.device.new_buffer(
            target.cells.len() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        unsafe {
            let ptr = target_buf.contents() as *mut u8;
            for (i, &c) in target.cells.iter().enumerate() {
                *ptr.add(i) = c;
            }
        }

        // params: [start_rule, count, k, tape_width, steps]
        let params_buf = self.device.new_buffer(
            5 * mem::size_of::<u64>() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let counter_buf = self.device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        let output_buf = self.device.new_buffer(
            MAX_OUTPUT * 8,
            MTLResourceOptions::StorageModeShared,
        );

        let mut all_results: Vec<u64> = Vec::new();

        for batch in 0..n_batches {
            if wll::aborted() { break; }
            let start = min_rule + batch * BATCH_SIZE;
            let count = BATCH_SIZE.min(max_rule + 1 - start);

            // Only update params and reset counter per batch
            unsafe {
                let ptr = params_buf.contents() as *mut u64;
                *ptr.add(0) = start;
                *ptr.add(1) = count;
                *ptr.add(2) = k as u64;
                *ptr.add(3) = init.cells.len() as u64;
                *ptr.add(4) = steps as u64;
                *(counter_buf.contents() as *mut u32) = 0;
            }

            let cb = self.queue.new_command_buffer();
            let enc = cb.new_compute_command_encoder();
            enc.set_compute_pipeline_state(pipeline);
            enc.set_buffer(0, Some(&params_buf), 0);
            enc.set_buffer(1, Some(&init_buf), 0);
            enc.set_buffer(2, Some(&counter_buf), 0);
            enc.set_buffer(3, Some(&output_buf), 0);
            enc.set_buffer(4, Some(&target_buf), 0);
            enc.dispatch_threads(
                MTLSize::new(count, 1, 1),
                MTLSize::new(max_threads as u64, 1, 1),
            );
            enc.end_encoding();

            cb.commit();
            cb.wait_until_completed();

            let found = unsafe { *(counter_buf.contents() as *const u32) } as u64;
            let ptr = output_buf.contents() as *const u64;
            for i in 0..found.min(MAX_OUTPUT) as usize {
                let rule = unsafe { *ptr.add(i) };
                all_results.push(rule);
            }
        }

        all_results.sort_unstable();
        all_results.dedup();
        Some(all_results)
    }

    /// Find rules where max active width never exceeds max_width.
    /// Optimized: pre-allocates all buffers once, reuses across batches.
    pub fn find_bounded_width_rules(
        &self,
        min_rule: u64,
        max_rule: u64,
        k: u32,
        r: u32,
        init: &CAState,
        steps: usize,
        max_width: usize,
    ) -> Option<Vec<u64>> {
        if !Self::is_supported(k, r, init.cells.len()) {
            return None;
        }

        let pipeline = &self.bounded_pipeline;
        let max_threads = pipeline.max_total_threads_per_threadgroup();

        let total = max_rule - min_rule + 1;
        let n_batches = (total + BATCH_SIZE - 1) / BATCH_SIZE;

        let init_buf = self.make_init_buffer(init);
        // params: [start_rule, count, k, tape_width, steps, max_width]
        let params_buf = self.device.new_buffer(
            6 * mem::size_of::<u64>() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let counter_buf = self.device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        let output_buf = self.device.new_buffer(
            MAX_OUTPUT * 8,
            MTLResourceOptions::StorageModeShared,
        );

        let mut all_results: Vec<u64> = Vec::new();

        for batch in 0..n_batches {
            if wll::aborted() { break; }
            let start = min_rule + batch * BATCH_SIZE;
            let count = BATCH_SIZE.min(max_rule + 1 - start);

            unsafe {
                let ptr = params_buf.contents() as *mut u64;
                *ptr.add(0) = start;
                *ptr.add(1) = count;
                *ptr.add(2) = k as u64;
                *ptr.add(3) = init.cells.len() as u64;
                *ptr.add(4) = steps as u64;
                *ptr.add(5) = max_width as u64;
                *(counter_buf.contents() as *mut u32) = 0;
            }

            let cb = self.queue.new_command_buffer();
            let enc = cb.new_compute_command_encoder();
            enc.set_compute_pipeline_state(pipeline);
            enc.set_buffer(0, Some(&params_buf), 0);
            enc.set_buffer(1, Some(&init_buf), 0);
            enc.set_buffer(2, Some(&counter_buf), 0);
            enc.set_buffer(3, Some(&output_buf), 0);
            enc.dispatch_threads(
                MTLSize::new(count, 1, 1),
                MTLSize::new(max_threads as u64, 1, 1),
            );
            enc.end_encoding();

            cb.commit();
            cb.wait_until_completed();

            let found = unsafe { *(counter_buf.contents() as *const u32) } as u64;
            let ptr = output_buf.contents() as *const u64;
            for i in 0..found.min(MAX_OUTPUT) as usize {
                let rule = unsafe { *ptr.add(i) };
                all_results.push(rule);
            }
        }

        all_results.sort_unstable();
        all_results.dedup();
        Some(all_results)
    }

    /// Find k=3 r=1 width-doublers using specialized kernel with analytical constraints.
    /// Searches 3^19 free-digit combinations (8 digits fixed analytically).
    /// num_tests = number of doubling tests (widths 1→2, 2→4, ..., up to 7→14).
    pub fn find_doublers_k3r1(&self, num_tests: u32) -> Option<Vec<u64>> {
        let pipeline = {
            let library = self.device
                .new_library_with_source(SHADER_SRC, &CompileOptions::new())
                .ok()?;
            let func = library.get_function("ca_find_doublers", None).ok()?;
            self.device.new_compute_pipeline_state_with_function(&func).ok()?
        };
        let max_threads = pipeline.max_total_threads_per_threadgroup();

        let total: u64 = 3_486_784_401; // 3^20 (7 fixed digits, 20 free)
        let batch_size: u64 = 100_000_000;
        let n_batches = (total + batch_size - 1) / batch_size;

        let params_buf = self.device.new_buffer(24, MTLResourceOptions::StorageModeShared);
        let counter_buf = self.device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        let output_buf = self.device.new_buffer(
            MAX_OUTPUT * 8,
            MTLResourceOptions::StorageModeShared,
        );

        let mut all_results: Vec<u64> = Vec::new();

        for batch in 0..n_batches {
            if wll::aborted() { break; }
            let start = batch * batch_size;
            let count = batch_size.min(total - start);

            unsafe {
                let ptr = params_buf.contents() as *mut u64;
                *ptr.add(0) = start;
                *ptr.add(1) = count;
                *ptr.add(2) = num_tests as u64;
                *(counter_buf.contents() as *mut u32) = 0;
            }

            let cb = self.queue.new_command_buffer();
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

            cb.commit();
            cb.wait_until_completed();

            let found = unsafe { *(counter_buf.contents() as *const u32) } as u64;
            let ptr = output_buf.contents() as *const u64;
            for i in 0..found.min(MAX_OUTPUT) as usize {
                let rule = unsafe { *ptr.add(i) };
                all_results.push(rule);
            }
        }

        all_results.sort_unstable();
        all_results.dedup();
        Some(all_results)
    }

    /// Refine doubler candidates: run additional NKS tests on a list of rule numbers.
    fn refine_doublers(&self, candidates: &[u64], start_test: u32, end_test: u32) -> Option<Vec<u64>> {
        if candidates.is_empty() { return Some(vec![]); }

        let pipeline = &self.refine_pipeline;
        let count = candidates.len() as u64;

        // Params: [count, start_test, end_test]
        let params_buf = self.device.new_buffer(24, MTLResourceOptions::StorageModeShared);
        let input_buf = self.device.new_buffer(count * 8, MTLResourceOptions::StorageModeShared);
        let counter_buf = self.device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        let output_buf = self.device.new_buffer(count * 8, MTLResourceOptions::StorageModeShared);

        unsafe {
            let p = params_buf.contents() as *mut u64;
            *p = count;
            *p.add(1) = start_test as u64;
            *p.add(2) = end_test as u64;

            let inp = input_buf.contents() as *mut u64;
            for (i, &rule) in candidates.iter().enumerate() {
                *inp.add(i) = rule;
            }
            *(counter_buf.contents() as *mut u32) = 0;
        }

        let max_threads = pipeline.max_total_threads_per_threadgroup();
        let cb = self.queue.new_command_buffer();
        let enc = cb.new_compute_command_encoder();
        enc.set_compute_pipeline_state(&pipeline);
        enc.set_buffer(0, Some(&params_buf), 0);
        enc.set_buffer(1, Some(&input_buf), 0);
        enc.set_buffer(2, Some(&counter_buf), 0);
        enc.set_buffer(3, Some(&output_buf), 0);
        enc.dispatch_threads(
            MTLSize::new(count, 1, 1),
            MTLSize::new(max_threads as u64, 1, 1),
        );
        enc.end_encoding();
        cb.commit();
        cb.wait_until_completed();

        let found = unsafe { *(counter_buf.contents() as *const u32) } as usize;
        let ptr = output_buf.contents() as *const u64;
        let mut results: Vec<u64> = (0..found).map(|i| unsafe { *ptr.add(i) }).collect();
        results.sort_unstable();
        Some(results)
    }
}

// Thread-local GPU engine singleton for reuse across calls.
thread_local! {
    static GPU_ENGINE: Option<GpuSearchEngine> = GpuSearchEngine::new();
}

/// Try to run exact width search on GPU. Returns None if GPU unavailable or unsupported params.
pub fn try_find_exact_width_rules(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    init: &CAState,
    steps: usize,
    target_width: usize,
) -> Option<Vec<u64>> {
    GPU_ENGINE.with(|engine| {
        engine.as_ref()?.find_exact_width_rules(min_rule, max_rule, k, r, init, steps, target_width)
    })
}

/// Try to run matching search on GPU.
pub fn try_find_matching_rules(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    init: &CAState,
    steps: usize,
    target: &CAState,
) -> Option<Vec<u64>> {
    GPU_ENGINE.with(|engine| {
        engine.as_ref()?.find_matching_rules(min_rule, max_rule, k, r, init, steps, target)
    })
}

/// Try to run bounded width search on GPU.
pub fn try_find_bounded_width_rules(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    init: &CAState,
    steps: usize,
    max_width: usize,
) -> Option<Vec<u64>> {
    GPU_ENGINE.with(|engine| {
        engine.as_ref()?.find_bounded_width_rules(min_rule, max_rule, k, r, init, steps, max_width)
    })
}

/// Try to run specialized k=3 r=1 doubler search on GPU.
pub fn try_find_doublers_k3r1(num_tests: u32) -> Option<Vec<u64>> {
    GPU_ENGINE.with(|engine| {
        engine.as_ref()?.find_doublers_k3r1(num_tests)
    })
}

/// Refine doubler candidates with additional GPU tests.
pub fn try_refine_doublers(candidates: &[u64], start_test: u32, end_test: u32) -> Option<Vec<u64>> {
    GPU_ENGINE.with(|engine| {
        engine.as_ref()?.refine_doublers(candidates, start_test, end_test)
    })
}

/// GPU-accelerated test: check each rule in candidates against init→target.
/// Returns Vec<u8> of 0/1 (one per candidate).
pub fn try_test_rules(
    candidates: &[u64],
    k: u32,
    r: u32,
    init: &CAState,
    steps: usize,
    target: &CAState,
) -> Option<Vec<u8>> {
    if r != 1 || k > 4 || init.cells.len() > 512 || candidates.is_empty() {
        return None;
    }
    GPU_ENGINE.with(|engine| {
        let engine = engine.as_ref()?;
        let count = candidates.len() as u64;
        let max_threads = engine.test_rules_pipeline.max_total_threads_per_threadgroup();

        // Buffers
        let params: Vec<u64> = vec![count, k as u64, init.cells.len() as u64, steps as u64];
        let params_buf = engine.device.new_buffer_with_data(
            params.as_ptr() as *const _,
            (params.len() * mem::size_of::<u64>()) as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let rules_buf = engine.device.new_buffer_with_data(
            candidates.as_ptr() as *const _,
            (candidates.len() * mem::size_of::<u64>()) as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let init_buf = engine.make_init_buffer(init);
        let target_buf = engine.device.new_buffer_with_data(
            target.cells.as_ptr() as *const _,
            target.cells.len() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let output_buf = engine.device.new_buffer(
            count,
            MTLResourceOptions::StorageModeShared,
        );

        let cb = engine.queue.new_command_buffer();
        let enc = cb.new_compute_command_encoder();
        enc.set_compute_pipeline_state(&engine.test_rules_pipeline);
        enc.set_buffer(0, Some(&params_buf), 0);
        enc.set_buffer(1, Some(&rules_buf), 0);
        enc.set_buffer(2, Some(&init_buf), 0);
        enc.set_buffer(3, Some(&target_buf), 0);
        enc.set_buffer(4, Some(&output_buf), 0);
        enc.dispatch_threads(
            MTLSize::new(count, 1, 1),
            MTLSize::new(max_threads as u64, 1, 1),
        );
        enc.end_encoding();
        cb.commit();
        cb.wait_until_completed();

        let ptr = output_buf.contents() as *const u8;
        let results: Vec<u8> = (0..candidates.len()).map(|i| unsafe { *ptr.add(i) }).collect();
        Some(results)
    })
}

const GPU_RANDOM_BATCH: u64 = 100_000_000; // 100M per GPU dispatch

/// GPU-accelerated random search: generate random rule tables on GPU, test against init→target.
/// Returns matching rule numbers as BigUint strings.
pub fn try_random_search(
    n: u64,
    seed: u64,
    k: u32,
    r: u32,
    init: &CAState,
    steps: usize,
    target: &CAState,
) -> Option<Vec<String>> {
    if r != 1 || k > 4 || init.cells.len() > 512 {
        return None;
    }

    GPU_ENGINE.with(|engine| {
        let engine = engine.as_ref()?;
        let pipeline = engine.random_search_pipeline.as_ref()?;
        let table_size = (k as u64).pow((2 * r + 1) as u32) as usize;
        let max_threads = pipeline.max_total_threads_per_threadgroup();

        let n_batches = (n + GPU_RANDOM_BATCH - 1) / GPU_RANDOM_BATCH;
        let mut all_results: Vec<String> = Vec::new();

        // Pre-allocate buffers
        // params: [n, seed_lo, seed_hi, k, tape_width, steps, table_size]
        let params_buf = engine.device.new_buffer(
            7 * mem::size_of::<u64>() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let init_buf = engine.make_init_buffer(init);
        let target_buf = engine.device.new_buffer_with_data(
            target.cells.as_ptr() as *const _,
            target.cells.len() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let counter_buf = engine.device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        // Output buffer: up to MAX_OUTPUT matching tables, each table_size bytes
        let output_buf = engine.device.new_buffer(
            MAX_OUTPUT * table_size as u64,
            MTLResourceOptions::StorageModeShared,
        );

        for batch in 0..n_batches {
            if wll::aborted() { break; }
            let batch_start = batch * GPU_RANDOM_BATCH;
            let count = GPU_RANDOM_BATCH.min(n - batch_start);
            let batch_seed = seed.wrapping_add(batch * GPU_RANDOM_BATCH);

            unsafe {
                let ptr = params_buf.contents() as *mut u64;
                *ptr.add(0) = count;
                *ptr.add(1) = batch_seed & 0xFFFF_FFFF;
                *ptr.add(2) = batch_seed >> 32;
                *ptr.add(3) = k as u64;
                *ptr.add(4) = init.cells.len() as u64;
                *ptr.add(5) = steps as u64;
                *ptr.add(6) = table_size as u64;
                *(counter_buf.contents() as *mut u32) = 0;
            }

            let cb = engine.queue.new_command_buffer();
            let enc = cb.new_compute_command_encoder();
            enc.set_compute_pipeline_state(pipeline);
            enc.set_buffer(0, Some(&params_buf), 0);
            enc.set_buffer(1, Some(&init_buf), 0);
            enc.set_buffer(2, Some(&target_buf), 0);
            enc.set_buffer(3, Some(&counter_buf), 0);
            enc.set_buffer(4, Some(&output_buf), 0);
            enc.dispatch_threads(
                MTLSize::new(count, 1, 1),
                MTLSize::new(max_threads as u64, 1, 1),
            );
            enc.end_encoding();
            cb.commit();
            cb.wait_until_completed();

            let found = unsafe { *(counter_buf.contents() as *const u32) } as usize;
            if found > 0 {
                let ptr = output_buf.contents() as *const u8;
                for i in 0..found.min(MAX_OUTPUT as usize) {
                    // Read table from GPU output
                    let table: Vec<u8> = (0..table_size)
                        .map(|j| unsafe { *ptr.add(i * table_size + j) })
                        .collect();
                    let ca = crate::models::CellularAutomaton::from_table(table, k, r);
                    let rule_num = ca.to_rule_number_bigint();
                    all_results.push(rule_num.to_string());
                }
            }
        }

        Some(all_results)
    })
}

const GPU_FREE_BATCH: u64 = 100_000_000; // 100M per GPU dispatch

/// GPU-accelerated search over the free-digit space.
/// fixed_digits: Vec<(u8, u8)> = (position, value) for each fixed table entry
/// free_positions: Vec<u8> = positions of free table entries
/// Returns rule numbers (u64) for rules where ALL pairs match.
pub fn try_search_free(
    k: u32,
    r: u32,
    fixed_digits: &[(u8, u8)],
    free_positions: &[u8],
    pairs: &[(CAState, CAState)],  // (init, target) pairs, already padded to same width
    steps: usize,
) -> Option<Vec<u64>> {
    if r != 1 || k > 4 || pairs.is_empty() {
        return None;
    }
    let tape_width = pairs[0].0.cells.len();
    if tape_width > 512 {
        return None;
    }

    let table_size = (k as u64).pow((2 * r + 1) as u32) as usize;
    let num_free = free_positions.len();
    let total: u64 = (k as u64).pow(num_free as u32);

    GPU_ENGINE.with(|engine| {
        let engine = engine.as_ref()?;
        let pipeline = engine.search_free_pipeline.as_ref()?;
        let max_threads = pipeline.max_total_threads_per_threadgroup();

        // Prepare fixed digits buffer: [pos0, val0, pos1, val1, ...]
        let fixed_flat: Vec<u8> = fixed_digits.iter()
            .flat_map(|&(pos, val)| vec![pos, val])
            .collect();
        let fixed_buf = engine.device.new_buffer_with_data(
            fixed_flat.as_ptr() as *const _,
            std::cmp::max(fixed_flat.len() as u64, 1),
            MTLResourceOptions::StorageModeShared,
        );

        // Free positions buffer
        let free_buf = engine.device.new_buffer_with_data(
            free_positions.as_ptr() as *const _,
            free_positions.len() as u64,
            MTLResourceOptions::StorageModeShared,
        );

        // Concatenate all init and target cells
        let mut all_init: Vec<u8> = Vec::new();
        let mut all_target: Vec<u8> = Vec::new();
        for (init, target) in pairs {
            all_init.extend_from_slice(&init.cells);
            all_target.extend_from_slice(&target.cells);
        }
        let init_buf = engine.device.new_buffer_with_data(
            all_init.as_ptr() as *const _,
            all_init.len() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let target_buf = engine.device.new_buffer_with_data(
            all_target.as_ptr() as *const _,
            all_target.len() as u64,
            MTLResourceOptions::StorageModeShared,
        );

        // params: [start_idx, count, k, table_size, num_free, tape_width, steps, num_pairs]
        let params_buf = engine.device.new_buffer(
            8 * mem::size_of::<u64>() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let counter_buf = engine.device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        let result_buf = engine.device.new_buffer(
            1_000_000 * mem::size_of::<u64>() as u64,
            MTLResourceOptions::StorageModeShared,
        );

        let n_batches = (total + GPU_FREE_BATCH - 1) / GPU_FREE_BATCH;
        let mut all_results: Vec<u64> = Vec::new();

        for batch in 0..n_batches {
            if wll::aborted() { break; }
            let batch_start = batch * GPU_FREE_BATCH;
            let count = GPU_FREE_BATCH.min(total - batch_start);

            unsafe {
                let ptr = params_buf.contents() as *mut u64;
                *ptr.add(0) = batch_start;
                *ptr.add(1) = count;
                *ptr.add(2) = k as u64;
                *ptr.add(3) = table_size as u64;
                *ptr.add(4) = num_free as u64;
                *ptr.add(5) = tape_width as u64;
                *ptr.add(6) = steps as u64;
                *ptr.add(7) = pairs.len() as u64;
                *(counter_buf.contents() as *mut u32) = 0;
            }

            let cb = engine.queue.new_command_buffer();
            let enc = cb.new_compute_command_encoder();
            enc.set_compute_pipeline_state(pipeline);
            enc.set_buffer(0, Some(&params_buf), 0);
            enc.set_buffer(1, Some(&fixed_buf), 0);
            enc.set_buffer(2, Some(&free_buf), 0);
            enc.set_buffer(3, Some(&init_buf), 0);
            enc.set_buffer(4, Some(&target_buf), 0);
            enc.set_buffer(5, Some(&counter_buf), 0);
            enc.set_buffer(6, Some(&result_buf), 0);
            enc.dispatch_threads(
                MTLSize::new(count, 1, 1),
                MTLSize::new(max_threads as u64, 1, 1),
            );
            enc.end_encoding();
            cb.commit();
            cb.wait_until_completed();

            let found = unsafe { *(counter_buf.contents() as *const u32) };
            if found > 0 {
                let n = (found as usize).min(1_000_000);
                let ptr = result_buf.contents() as *const u64;
                for i in 0..n {
                    all_results.push(unsafe { *ptr.add(i) });
                }
            }
        }

        Some(all_results)
    })
}
