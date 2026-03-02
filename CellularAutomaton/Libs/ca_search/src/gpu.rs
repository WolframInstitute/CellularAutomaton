//! Metal GPU-accelerated CA search engine.
//! Only available on macOS with the `gpu` feature enabled.

use metal::*;
use std::mem;

use crate::models::CAState;

const SHADER_SRC: &str = include_str!("../shaders/ca_search.metal");
const MAX_OUTPUT: u64 = 1_000_000;
const BATCH_SIZE: u64 = 50_000_000; // 50M rules per GPU dispatch

/// Metal GPU search engine. Caches compiled pipelines for reuse.
pub struct GpuSearchEngine {
    device: Device,
    queue: CommandQueue,
    exact_width_pipeline: ComputePipelineState,
    matching_pipeline: ComputePipelineState,
    bounded_pipeline: ComputePipelineState,
    refine_pipeline: ComputePipelineState,
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

        let queue = device.new_command_queue();

        Some(Self {
            device,
            queue,
            exact_width_pipeline,
            matching_pipeline,
            bounded_pipeline,
            refine_pipeline,
        })
    }

    /// Check if the search parameters are GPU-compatible.
    /// Currently: r=1 only, k<=4, tape_width <= 256.
    fn is_supported(k: u32, r: u32, tape_width: usize) -> bool {
        r == 1 && k <= 4 && tape_width <= 256
    }

    /// Dispatch a batched GPU search and collect results.
    fn dispatch_search(
        &self,
        pipeline: &ComputePipelineState,
        min_rule: u64,
        max_rule: u64,
        params: &[u64],
        init_buf: &Buffer,
        extra_buf: Option<&Buffer>,
    ) -> Vec<u64> {
        let total = max_rule - min_rule + 1;
        let n_batches = (total + BATCH_SIZE - 1) / BATCH_SIZE;
        let max_threads = pipeline.max_total_threads_per_threadgroup();

        let params_buf = self.device.new_buffer(
            (params.len() * mem::size_of::<u64>()) as u64,
            MTLResourceOptions::StorageModeShared,
        );
        let counter_buf = self.device.new_buffer(4, MTLResourceOptions::StorageModeShared);
        let output_buf = self.device.new_buffer(
            MAX_OUTPUT * 8,
            MTLResourceOptions::StorageModeShared,
        );

        let mut all_results: Vec<u64> = Vec::new();

        for batch in 0..n_batches {
            let start = min_rule + batch * BATCH_SIZE;
            let count = BATCH_SIZE.min(max_rule + 1 - start);

            // Update params: params[0] = start_rule, params[1] = count
            let mut batch_params = params.to_vec();
            batch_params[0] = start;
            batch_params[1] = count;

            unsafe {
                let ptr = params_buf.contents() as *mut u64;
                for (i, &v) in batch_params.iter().enumerate() {
                    *ptr.add(i) = v;
                }
                *(counter_buf.contents() as *mut u32) = 0;
            }

            let cb = self.queue.new_command_buffer();
            let enc = cb.new_compute_command_encoder();
            enc.set_compute_pipeline_state(pipeline);
            enc.set_buffer(0, Some(&params_buf), 0);
            enc.set_buffer(1, Some(init_buf), 0);
            enc.set_buffer(2, Some(&counter_buf), 0);
            enc.set_buffer(3, Some(&output_buf), 0);
            if let Some(extra) = extra_buf {
                enc.set_buffer(4, Some(extra), 0);
            }
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
        all_results
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

        let init_buf = self.make_init_buffer(init);
        // params: start_rule, count, k, tape_width, steps, target_width
        let params = vec![0u64, 0, k as u64, init.cells.len() as u64, steps as u64, target_width as u64];

        Some(self.dispatch_search(
            &self.exact_width_pipeline,
            min_rule, max_rule,
            &params,
            &init_buf,
            None,
        ))
    }

    /// Find rules where final state matches target exactly.
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

        let init_buf = self.make_init_buffer(init);
        let target_cells = &target.cells;
        let target_buf = self.device.new_buffer(
            target_cells.len() as u64,
            MTLResourceOptions::StorageModeShared,
        );
        unsafe {
            let ptr = target_buf.contents() as *mut u8;
            for (i, &c) in target_cells.iter().enumerate() {
                *ptr.add(i) = c;
            }
        }

        let params = vec![0u64, 0, k as u64, init.cells.len() as u64, steps as u64];

        Some(self.dispatch_search(
            &self.matching_pipeline,
            min_rule, max_rule,
            &params,
            &init_buf,
            Some(&target_buf),
        ))
    }

    /// Find rules where max active width never exceeds max_width.
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

        let init_buf = self.make_init_buffer(init);
        let params = vec![0u64, 0, k as u64, init.cells.len() as u64, steps as u64, max_width as u64];

        Some(self.dispatch_search(
            &self.bounded_pipeline,
            min_rule, max_rule,
            &params,
            &init_buf,
            None,
        ))
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
