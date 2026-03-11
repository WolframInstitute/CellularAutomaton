use wolfram_library_link::{self as wll, NumericArray, UninitNumericArray};

wll::generate_loader!(rustlink_autodiscover);

use rayon::prelude::*;

pub mod models;
#[cfg(all(target_os = "macos", feature = "gpu"))]
pub mod gpu;

use crate::models::{CAState, CellularAutomaton};

// =============================================================================
// Core functions
// =============================================================================

/// Evolve a single CA rule from a given initial state for `steps` generations.
/// Returns the evolution as a flat Vec<u8> (row-major: steps+1 rows x width columns).
pub fn run_ca(
    rule_number: u64,
    k: u32,
    r: u32,
    initial_cells: &[u8],
    steps: usize,
) -> Vec<u8> {
    let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
    let initial = CAState::new(initial_cells.to_vec(), k);
    let history = ca.evolve(&initial, steps);
    history.into_iter().flat_map(|s| s.cells).collect()
}

/// Evolve a CA and return only the final state cells.
pub fn run_ca_final(
    rule_number: u64,
    k: u32,
    r: u32,
    initial_cells: &[u8],
    steps: usize,
) -> Vec<u8> {
    let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
    let initial = CAState::new(initial_cells.to_vec(), k);
    ca.evolve_final(&initial, steps).cells
}

/// Compute the output (final state as integer) for a range of rules and a given initial condition.
/// Returns a Vec of output integers, one per rule. Parallelized with rayon.
pub fn ca_output_table_parallel(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &[u8],
    steps: usize,
) -> Vec<u64> {
    let initial = CAState::new(initial_cells.to_vec(), k);
    (min_rule..=max_rule)
        .into_par_iter()
        .map(|rule_number| {
            if wll::aborted() { return 0; }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            ca.evolve_final(&initial, steps).to_integer()
        })
        .collect()
}

/// Search for rules whose final state matches a target pattern.
/// Returns Vec of matching rule numbers. GPU-accelerated on macOS, CPU fallback.
/// Checks wll::aborted() between batches/partitions for early exit.
pub fn find_matching_rules(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &[u8],
    steps: usize,
    target_cells: &[u8],
) -> Vec<u64> {

    let initial = CAState::new(initial_cells.to_vec(), k);
    #[allow(unused_variables)]
    let target_state = CAState::new(target_cells.to_vec(), k);

    // Try GPU first
    #[cfg(all(target_os = "macos", feature = "gpu"))]
    if let Some(results) = gpu::try_find_matching_rules(
        min_rule, max_rule, k, 1, &initial, steps, &target_state,
    ) {
        return results;
    }

    let target = target_cells.to_vec();
    (min_rule..=max_rule)
        .into_par_iter()
        .filter(|&rule_number| {
            if wll::aborted() { return false; }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            let final_state = ca.evolve_final(&initial, steps);
            final_state.cells == target
        })
        .collect()
}

/// Compute evolution history for multiple rules in parallel.
/// Returns a nested Vec: outer = rules, inner = flat evolution (row-major).
pub fn ca_evolution_table_parallel(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &[u8],
    steps: usize,
) -> Vec<Vec<u8>> {
    let initial = CAState::new(initial_cells.to_vec(), k);
    (min_rule..=max_rule)
        .into_par_iter()
        .map(|rule_number| {
            if wll::aborted() { return vec![]; }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            let history = ca.evolve(&initial, steps);
            history.into_iter().flat_map(|s| s.cells).collect()
        })
        .collect()
}

/// Fully specialized bounded-width check for k=3, r=1.
/// Uses array indexing with baked-in constants (*9 + *3 +).
/// Combined step + boundary tracking in single pass per step.
#[inline(always)]
fn is_bounded_k3r1(table: &[u8; 27], initial: &[u8], steps: usize, max_width: usize) -> bool {
    const MAX: usize = 64;
    let w = initial.len().min(MAX);

    let mut a = [0u8; MAX];
    let mut b = [0u8; MAX];
    a[..w].copy_from_slice(&initial[..w]);

    let mut left = w;
    let mut right = 0usize;
    for i in 0..w {
        if a[i] != 0 {
            if i < left { left = i; }
            right = i;
        }
    }
    if left > right { return true; }

    for step in 0..steps {
        let el = if left >= 2 { left - 2 } else { 0 };
        let er = if right + 2 < w { right + 2 } else { w - 1 };

        let mut nl = w;
        let mut nr = 0usize;

        if step & 1 == 0 {
            for i in el..=er {
                let li = if i == 0 { w - 1 } else { i - 1 };
                let ri = if i + 1 >= w { 0 } else { i + 1 };
                let v = table[a[li] as usize * 9 + a[i] as usize * 3 + a[ri] as usize];
                b[i] = v;
                if v != 0 {
                    if i < nl { nl = i; }
                    nr = i;
                }
            }
        } else {
            for i in el..=er {
                let li = if i == 0 { w - 1 } else { i - 1 };
                let ri = if i + 1 >= w { 0 } else { i + 1 };
                let v = table[b[li] as usize * 9 + b[i] as usize * 3 + b[ri] as usize];
                a[i] = v;
                if v != 0 {
                    if i < nl { nl = i; }
                    nr = i;
                }
            }
        }

        if nl > nr { return true; }
        if nr - nl + 1 > max_width { return false; }

        left = nl;
        right = nr;
    }
    true
}

/// Find rules whose active width stays bounded (never exceeds max_width).
/// Fully optimized for k=3, r=1:
/// - Iterates only multiples of k (3x fewer tasks)
/// - Left-right reflection symmetry (~2x fewer tests)
/// - Color permutation symmetry (1↔2) (~2x fewer tests)
/// - Combined: up to ~12x fewer evolution checks vs naive
/// Returns Vec of matching rule numbers. Parallelized with rayon.
pub fn find_bounded_width_rules(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &[u8],
    steps: usize,
    max_width: usize,
) -> Vec<u64> {
    let k64 = k as u64;

    let initial = initial_cells.to_vec();

    // Specialized fast path for k=3, r=1
    if k == 3 && r == 1 {
        // Precompute reflection permutation: reflect[i] maps index i to reflected index
        // For neighborhood (l,c,r) at index l*9+c*3+r, reflection gives (r,c,l) at r*9+c*3+l
        let mut reflect_perm = [0usize; 27];
        for l in 0..3usize {
            for c in 0..3usize {
                for r in 0..3usize {
                    reflect_perm[l * 9 + c * 3 + r] = r * 9 + c * 3 + l;
                }
            }
        }

        // Precompute color swap permutation (0→0, 1→2, 2→1)
        let color_swap: [usize; 3] = [0, 2, 1];
        let mut color_perm = [0usize; 27]; // maps old index → new index
        let mut color_output = [0u8; 3];   // maps old output → new output
        color_output[0] = 0;
        color_output[1] = 2;
        color_output[2] = 1;
        for l in 0..3usize {
            for c in 0..3usize {
                for r in 0..3usize {
                    let old_idx = l * 9 + c * 3 + r;
                    let new_idx = color_swap[l] * 9 + color_swap[c] * 3 + color_swap[r];
                    color_perm[old_idx] = new_idx;
                }
            }
        }
        // Precompute combined reflection + color swap permutation
        let mut both_perm = [0usize; 27];
        for i in 0..27usize {
            both_perm[i] = color_perm[reflect_perm[i]];
        }

        // Iterate only multiples of 3 (digit 0 = f(0,0,0) must be 0)
        let start = ((min_rule + 2) / 3) * 3;
        let end = (max_rule / 3) * 3;
        if start > end { return vec![]; }
        let count = (end - start) / 3 + 1;

        return (0..count)
            .into_par_iter()
            .filter_map(|i| {
                if wll::aborted() { return None; }
                let rule_number = start + i * 3;

                // Decode rule table with literal /3 %3
                let mut table = [0u8; 27];
                let mut val = rule_number;
                for j in 0..27usize {
                    table[j] = (val % 3) as u8;
                    val /= 3;
                }

                // Digit-level structural constraints (eliminates ~75%)
                // table[1]=1 → f(0,0,1)=1 chain reaction (always unbounded left)
                // table[9]=1 → f(1,0,0)=1 chain reaction (always unbounded right)
                if table[1] == 1 || table[9] == 1 { return None; }
                // table[1]=2 requires table[2]=0 (step-3 left boundary leak)
                if table[1] == 2 && table[2] != 0 { return None; }
                // table[9]=2 requires table[18]=0 (step-3 right boundary leak)
                if table[9] == 2 && table[18] != 0 { return None; }

                // Compute symmetry variants and check if this is canonical (smallest)
                // Variant 1: left-right reflection
                let reflected = rule_number_from_table_k3(&table, &reflect_perm, &[0, 1, 2]);
                if reflected < rule_number { return None; }

                // Variant 2: color swap (1↔2)
                let swapped = rule_number_from_table_k3(&table, &color_perm, &color_output);
                if swapped % 3 == 0 && swapped < rule_number { return None; }

                // Variant 3: reflection + color swap
                let both = rule_number_from_table_k3(&table, &both_perm, &color_output);
                if both % 3 == 0 && both < rule_number { return None; }

                // This rule is canonical — test it
                // Analytical 3-step pre-filter: for init {1} and max_width=5,
                // steps 1-2 never exceed width 5. Step 3 exceeds iff
                // boundary cells at ±3 become nonzero.
                // Step 1: [d1, d3, d9] = [table[1], table[3], table[9]]
                let d1 = table[1] as usize;
                let d3 = table[3] as usize;
                let d9 = table[9] as usize;
                if d1 == 0 && d3 == 0 && d9 == 0 {
                    // Rule kills the initial cell → trivially bounded
                    return Some(rule_number);
                }
                // Step 2: 5 cells [s2_0..s2_4]
                let s2_0 = table[d1] as usize;      // f(0,0,d1)
                let s2_4 = table[d9 * 9] as usize;  // f(d9,0,0)
                // Step 3: boundary check — do cells at ±3 activate?
                // Cell at center-3: neighborhood (0, 0, s2_0) → table[s2_0]
                // Cell at center+3: neighborhood (s2_4, 0, 0) → table[s2_4 * 9]
                if s2_0 != 0 && table[s2_0] != 0 { return None; }
                if s2_4 != 0 && table[s2_4 * 9] != 0 { return None; }

                // Stage 2: Full check on full tape
                if !is_bounded_k3r1(&table, &initial, steps, max_width) {
                    return None;
                }

                Some(rule_number)
            })
            .collect();
    }

    // Generic fallback for non-k=3 cases
    (min_rule..=max_rule)
        .into_par_iter()
        .filter(|&rule_number| {
            if wll::aborted() { return false; }
            if rule_number % k64 != 0 {
                return false;
            }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            ca.is_bounded_width_fast(&initial, steps, max_width)
        })
        .collect()
}

/// Compute a rule number from a table after applying index permutation and output mapping.
/// new_table[i] = output_map[old_table[index_perm[i]]]
/// Returns the base-3 encoded rule number.
#[inline(always)]
fn rule_number_from_table_k3(
    table: &[u8; 27],
    index_perm: &[usize; 27],
    output_map: &[u8; 3],
) -> u64 {
    let mut number: u64 = 0;
    let mut power: u64 = 1;
    for i in 0..27usize {
        let src = index_perm[i];
        let v = output_map[table[src] as usize];
        number += v as u64 * power;
        power *= 3;
    }
    number
}

/// Compute the max active width for each rule in a range.
/// Returns Vec of (max_width, final_width) pairs flattened: [max0, fin0, max1, fin1, ...].
pub fn max_active_widths_parallel(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &[u8],
    steps: usize,
) -> Vec<u64> {
    let initial = CAState::new(initial_cells.to_vec(), k);
    (min_rule..=max_rule)
        .into_par_iter()
        .flat_map(|rule_number| {
            if wll::aborted() { return vec![0, 0]; }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            let (max_w, fin_w) = ca.max_active_width(&initial, steps);
            vec![max_w as u64, fin_w as u64]
        })
        .collect()
}

/// Find rules where the final active width equals `ratio * input_active_width`
/// for ALL provided initial conditions. Fully parallelized with rayon.
/// `initials` is a slice of initial conditions (each a CAState).
/// `ratio_num` / `ratio_den` encodes the ratio as a fraction to allow integer checking.
/// e.g. ratio_num=2, ratio_den=1 checks for exact doubling.
pub fn find_width_ratio_rules(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initials: &[CAState],
    steps: usize,
    ratio_num: u64,
    ratio_den: u64,
    max_width: usize,
) -> Vec<u64> {
    let initials: Vec<_> = initials.to_vec();
    let input_widths: Vec<usize> = initials.iter().map(|s| s.active_width()).collect();

    (min_rule..=max_rule)
        .into_par_iter()
        .filter(|&rule_number| {
            if wll::aborted() { return false; }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            initials.iter().zip(input_widths.iter()).all(|(init, &iw)| {
                // Quick bounded-width check first (early exit)
                if !ca.is_bounded_width(init, steps, max_width) {
                    return false;
                }
                let final_state = ca.evolve_final(init, steps);
                let fw = final_state.active_width();
                // Check: fw * ratio_den == iw * ratio_num
                (fw as u64) * ratio_den == (iw as u64) * ratio_num
            })
        })
        .collect()
}

/// Find rules where the final active width equals exactly `target_width`.
/// Supports multiple initial conditions: ALL must produce the target width.
/// GPU-accelerated for single-init on macOS.
pub fn find_exact_width_rules(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initials: &[CAState],
    steps: usize,
    target_width: usize,
) -> Vec<u64> {
    // Try GPU for single-init case
    #[cfg(all(target_os = "macos", feature = "gpu"))]
    if initials.len() == 1 {
        if let Some(results) = gpu::try_find_exact_width_rules(
            min_rule, max_rule, k, 1, &initials[0], steps, target_width,
        ) {
            return results;
        }
    }

    let initials: Vec<_> = initials.to_vec();
    (min_rule..=max_rule)
        .into_par_iter()
        .filter(|&rule_number| {
            if wll::aborted() { return false; }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            initials.iter().all(|init| {
                let final_state = ca.evolve_final(init, steps);
                final_state.active_width() == target_width
            })
        })
        .collect()
}

// =============================================================================
// Wolfram LibraryLink wrappers
// =============================================================================

/// Helper: extract u8 cells from a NumericArray<i32>.
#[inline]
fn na_to_cells(na: &NumericArray<i32>) -> Vec<u8> {
    na.as_slice().iter().map(|&c| c as u8).collect()
}

/// Helper: create a NumericArray<i64> from a Vec<u64>.
#[inline]
fn vec_u64_to_na(v: Vec<u64>) -> NumericArray<i64> {
    let mut out = UninitNumericArray::<i64>::from_dimensions(&[v.len()]);
    for (src, dst) in v.iter().zip(out.as_slice_mut()) {
        dst.write(*src as i64);
    }
    unsafe { out.assume_init() }
}

/// Helper: create a NumericArray<i32> from a Vec<u8>.
#[inline]
fn vec_u8_to_na_i32(v: Vec<u8>) -> NumericArray<i32> {
    let mut out = UninitNumericArray::<i32>::from_dimensions(&[v.len()]);
    for (src, dst) in v.iter().zip(out.as_slice_mut()) {
        dst.write(*src as i32);
    }
    unsafe { out.assume_init() }
}

/// Run a CA evolution and return the flat spacetime grid.
#[wll::export]
pub fn run_ca_wl(
    rule_number: u64,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
) -> NumericArray<i32> {
    let cells = na_to_cells(initial_cells);
    let result = run_ca(rule_number, k, r, &cells, steps as usize);
    vec_u8_to_na_i32(result)
}

/// Run a CA and return just the final state.
#[wll::export]
pub fn run_ca_final_wl(
    rule_number: u64,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
) -> NumericArray<i32> {
    let cells = na_to_cells(initial_cells);
    let result = run_ca_final(rule_number, k, r, &cells, steps as usize);
    vec_u8_to_na_i32(result)
}

/// Compute output table across a range of rules (parallelized).
#[wll::export]
pub fn ca_output_table_parallel_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
) -> NumericArray<i64> {
    let cells = na_to_cells(initial_cells);
    vec_u64_to_na(ca_output_table_parallel(min_rule, max_rule, k, r, &cells, steps as usize))
}

/// Search for matching rules (parallelized).
#[wll::export]
pub fn find_matching_rules_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
    target_cells: &NumericArray<i32>,
) -> NumericArray<i64> {
    let cells = na_to_cells(initial_cells);
    let target = na_to_cells(target_cells);
    vec_u64_to_na(find_matching_rules(min_rule, max_rule, k, r, &cells, steps as usize, &target))
}

/// Compute the total number of rules for given k and r.
#[wll::export]
pub fn rule_count_wl(k: u32, r: u32) -> u64 {
    CellularAutomaton::rule_count(k, r)
}

/// Compute evolution table for multiple rules (parallelized).
/// Returns a flat list: concatenation of all evolutions.
/// Each evolution is (steps+1) * width cells long.
/// WL side can Partition[result, width] then Partition[%, steps+1].
#[wll::export]
pub fn ca_evolution_table_parallel_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
) -> NumericArray<i32> {
    let cells = na_to_cells(initial_cells);
    let table = ca_evolution_table_parallel(min_rule, max_rule, k, r, &cells, steps as usize);
    let flat: Vec<u8> = table.into_iter().flatten().collect();
    vec_u8_to_na_i32(flat)
}

/// Find rules with bounded active width (parallelized).
/// Returns a list of rule numbers where the active region never exceeds max_width.
#[wll::export]
pub fn find_bounded_width_rules_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
    max_width: u64,
) -> NumericArray<i64> {
    let cells = na_to_cells(initial_cells);
    vec_u64_to_na(find_bounded_width_rules(min_rule, max_rule, k, r, &cells, steps as usize, max_width as usize))
}

/// Compute max active widths for a range of rules (parallelized).
/// Returns flat list: [max0, final0, max1, final1, ...].
#[wll::export]
pub fn max_active_widths_parallel_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
) -> NumericArray<i64> {
    let cells = na_to_cells(initial_cells);
    vec_u64_to_na(max_active_widths_parallel(min_rule, max_rule, k, r, &cells, steps as usize))
}

/// Find rules whose final active width = (ratio_num/ratio_den) * input width
/// for ALL provided initial conditions. Fully parallelized.
/// `flat_inits` is a flat list of all initial conditions concatenated.
/// `num_inits` tells how many initial conditions are packed.
/// tape_width = len(flat_inits) / num_inits.
#[wll::export]
pub fn find_width_ratio_rules_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    flat_inits: &NumericArray<i32>,
    num_inits: u64,
    steps: u64,
    ratio_num: u64,
    ratio_den: u64,
    max_width: u64,
) -> NumericArray<i64> {
    let num = num_inits as usize;
    let sl = flat_inits.as_slice();
    let tape_width = sl.len() / num;
    let initials: Vec<CAState> = sl
        .chunks(tape_width)
        .map(|chunk| {
            let cells: Vec<u8> = chunk.iter().map(|&c| c as u8).collect();
            CAState::new(cells, k)
        })
        .collect();
    vec_u64_to_na(find_width_ratio_rules(
        min_rule, max_rule, k, r, &initials, steps as usize,
        ratio_num, ratio_den, max_width as usize,
    ))
}

/// Find rules where the final active width = target_width for ALL inits.
#[wll::export]
pub fn find_exact_width_rules_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    flat_inits: &NumericArray<i32>,
    num_inits: u64,
    steps: u64,
    target_width: u64,
) -> NumericArray<i64> {
    let num = num_inits as usize;
    let sl = flat_inits.as_slice();
    let tape_width = sl.len() / num;
    let initials: Vec<CAState> = sl
        .chunks(tape_width)
        .map(|chunk| {
            let cells: Vec<u8> = chunk.iter().map(|&c| c as u8).collect();
            CAState::new(cells, k)
        })
        .collect();
    vec_u64_to_na(find_exact_width_rules(
        min_rule, max_rule, k, r, &initials, steps as usize,
        target_width as usize,
    ))
}

/// Sequential-scan doubler check (matches NKS doubleasymmi.c algorithm).
/// Uses in-place update (left neighbor already updated) — NOT standard parallel CA.
/// Returns true if rule doubles width for init {1^(nin-1), 2} → {1^(2*nin)}.
fn check_doubling_sequential(rule_number: u64, nin: usize) -> bool {
    let table: Vec<u8> = (0..27)
        .map(|i| ((rule_number / 3u64.pow(i as u32)) % 3) as u8)
        .collect();

    let max_steps = 50 * nin * nin; // generous convergence cap
    let w = 2 * max_steps + 1;
    let mut a = vec![0u8; w];

    // Init: {1^(nin-1), 2} placed at center
    let center = max_steps;
    for i in 0..nin.saturating_sub(1) {
        a[center + i] = 1;
    }
    a[center + nin - 1] = 2;

    for _t in 0..max_steps {
        let mut changed = false;
        let mut b = a[0];
        for i in 1..(w - 1) {
            let bp = a[i];
            let bx = table[(b as usize) * 9 + (bp as usize) * 3 + (a[i + 1] as usize)];
            a[i] = bx;
            b = bp;
            if bx != bp {
                changed = true;
            }
        }
        if !changed {
            // Converged — verify: left zeros, 2*nin ones, right zeros
            for i in 1..center {
                if a[i] != 0 { return false; }
            }
            for i in 0..(2 * nin) {
                if a[center + i] != 1 { return false; }
            }
            for i in (center + 2 * nin)..w {
                if a[i] != 0 { return false; }
            }
            return true;
        }
    }
    false
}

/// Find k=3, r=1 width-doubling rules.
/// GPU handles all tests in a single pass (3^20 search space).
pub fn find_doublers_k3r1(num_tests: u32) -> Vec<u64> {
    #[cfg(all(target_os = "macos", feature = "gpu"))]
    {
        if let Some(candidates) = gpu::try_find_doublers_k3r1(num_tests) {
            return candidates;
        }
    }

    // CPU-only fallback
    let max_rule = 3u64.pow(27) - 1;
    (0..=max_rule)
        .into_par_iter()
        .filter(|&rule| {
            if wll::aborted() { return false; }
            if rule % 3 != 0 { return false; }
            (1..=num_tests as usize).all(|nin| check_doubling_sequential(rule, nin))
        })
        .collect()
}

/// WLL wrapper for find_doublers_k3r1.
#[wll::export]
pub fn find_doublers_k3r1_wl(num_tests: u64) -> NumericArray<i64> {
    vec_u64_to_na(find_doublers_k3r1(num_tests as u32))
}

/// Filter candidate rules using NKS sequential-scan doubler check.
pub fn filter_doublers_k3r1(candidates: &[u64], num_tests: u32) -> Vec<u64> {
    filter_doublers_k3r1_range(candidates, 1, num_tests)
}

/// Filter candidate rules testing only constraints start_test..=end_test.
/// Uses GPU refine for tests ≤ 12 (tape limit), CPU for larger tests.
pub fn filter_doublers_k3r1_range(candidates: &[u64], start_test: u32, end_test: u32) -> Vec<u64> {
    if candidates.is_empty() || start_test > end_test { return vec![]; }
    
    let mut current = candidates.to_vec();
    
    // GPU refine for tests that fit in the 1201-cell tape (≤ 12)
    let gpu_end = end_test.min(12);
    if start_test <= gpu_end {
        #[cfg(all(target_os = "macos", feature = "gpu"))]
        {
            if let Some(results) = gpu::try_refine_doublers(&current, start_test, gpu_end) {
                current = results;
            } else {
                // GPU unavailable, use CPU for this range
                current = current.par_iter().copied()
                    .filter(|&rule| {
                        if wll::aborted() { return false; }
                        (start_test as usize..=gpu_end as usize)
                            .all(|nin| check_doubling_sequential(rule, nin))
                    })
                    .collect();
            }
        }
        #[cfg(not(all(target_os = "macos", feature = "gpu")))]
        {
            current = current.par_iter().copied()
                .filter(|&rule| {
                    if wll::aborted() { return false; }
                    (start_test as usize..=gpu_end as usize)
                        .all(|nin| check_doubling_sequential(rule, nin))
                })
                .collect();
        }
    }
    
    // CPU for tests > 12 (tape too large for GPU)
    if end_test > 12 {
        let cpu_start = start_test.max(13);
        current = current.par_iter().copied()
            .filter(|&rule| {
                if wll::aborted() { return false; }
                (cpu_start as usize..=end_test as usize)
                    .all(|nin| check_doubling_sequential(rule, nin))
            })
            .collect();
    }
    
    current
}

/// WLL wrapper for filter_doublers_k3r1.
#[wll::export]
pub fn filter_doublers_k3r1_wl(candidate_rules: Vec<i64>, num_tests: u64) -> Vec<u64> {
    let candidates: Vec<u64> = candidate_rules.iter().map(|&r| r as u64).collect();
    filter_doublers_k3r1(&candidates, num_tests as u32)
}

/// WLL wrapper for filter_doublers_k3r1_range.
#[wll::export]
pub fn filter_doublers_k3r1_range_wl(candidate_rules: &NumericArray<i64>, start_test: u64, end_test: u64) -> NumericArray<i64> {
    let candidates: Vec<u64> = candidate_rules.as_slice().iter().map(|&r| r as u64).collect();
    vec_u64_to_na(filter_doublers_k3r1_range(&candidates, start_test as u32, end_test as u32))
}

/// Test a list of candidate rules: which ones produce target from init after steps?
/// Returns a Vec of 0/1 (one per candidate). GPU-accelerated on macOS, CPU fallback.
pub fn test_rules(
    candidates: &[u64],
    k: u32,
    r: u32,
    initial: &CAState,
    steps: usize,
    target: &[u8],
) -> Vec<u8> {
    // Try GPU first
    #[cfg(all(target_os = "macos", feature = "gpu"))]
    {
        let target_state = CAState::new(target.to_vec(), k);
        if let Some(results) = gpu::try_test_rules(candidates, k, r, initial, steps, &target_state) {
            return results;
        }
    }

    candidates
        .par_iter()
        .map(|&rule_number| {
            if wll::aborted() { return 0u8; }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            let final_state = ca.evolve_final(initial, steps);
            if final_state.cells == target { 1u8 } else { 0u8 }
        })
        .collect()
}

/// WLL wrapper for test_rules.
#[wll::export]
pub fn test_rules_wl(
    candidate_rules: &NumericArray<i64>,
    k: u32,
    r: u32,
    init: &NumericArray<i32>,
    steps: u64,
    target: &NumericArray<i32>,
) -> NumericArray<i32> {
    let candidates: Vec<u64> = candidate_rules.as_slice().iter().map(|&r| r as u64).collect();
    let init_cells = na_to_cells(init);
    let target_cells = na_to_cells(target);
    let initial = CAState::new(init_cells, k);
    let results = test_rules(&candidates, k, r, &initial, steps as usize, &target_cells);
    vec_u8_to_na_i32(results)
}

/// Filter a list of candidate rules by width ratio.
/// Same logic as find_width_ratio_rules but operates on a provided list instead of a range.
pub fn filter_width_ratio_rules(
    candidates: &[u64],
    k: u32,
    r: u32,
    initials: &[CAState],
    steps: usize,
    ratio_num: u64,
    ratio_den: u64,
    max_width: usize,
) -> Vec<u64> {
    let input_widths: Vec<usize> = initials.iter().map(|s| s.active_width()).collect();

    candidates
        .par_iter()
        .copied()
        .filter(|&rule_number| {
            if wll::aborted() { return false; }
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            initials.iter().zip(input_widths.iter()).all(|(init, &iw)| {
                if !ca.is_bounded_width(init, steps, max_width) {
                    return false;
                }
                let final_state = ca.evolve_final(init, steps);
                let fw = final_state.active_width();
                (fw as u64) * ratio_den == (iw as u64) * ratio_num
            })
        })
        .collect()
}

/// WLL wrapper for filter_width_ratio_rules.
#[wll::export]
pub fn filter_width_ratio_rules_wl(
    candidate_rules: &NumericArray<i64>,
    k: u32,
    r: u32,
    flat_inits: &NumericArray<i32>,
    num_inits: u64,
    steps: u64,
    ratio_num: u64,
    ratio_den: u64,
    max_width: u64,
) -> NumericArray<i64> {
    let candidates: Vec<u64> = candidate_rules.as_slice().iter().map(|&r| r as u64).collect();
    let num = num_inits as usize;
    let sl = flat_inits.as_slice();
    let tape_width = sl.len() / num;
    let initials: Vec<CAState> = sl
        .chunks(tape_width)
        .map(|chunk| {
            let cells: Vec<u8> = chunk.iter().map(|&c| c as u8).collect();
            CAState::new(cells, k)
        })
        .collect();
    vec_u64_to_na(filter_width_ratio_rules(
        &candidates, k, r, &initials, steps as usize,
        ratio_num, ratio_den, max_width as usize,
    ))
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_run_ca_elementary() {
        // Rule 30, single cell in width 7, 1 step
        let result = run_ca(30, 2, 1, &[0, 0, 0, 1, 0, 0, 0], 1);
        // Should be 2 rows of 7 cells = 14 cells
        assert_eq!(result.len(), 14);
        // First row is the initial state
        assert_eq!(&result[0..7], &[0, 0, 0, 1, 0, 0, 0]);
        // Second row is step 1
        assert_eq!(&result[7..14], &[0, 0, 1, 1, 1, 0, 0]);
    }

    #[test]
    fn test_output_table_parallel() {
        let init = vec![0, 0, 0, 1, 0, 0, 0];
        let outputs = ca_output_table_parallel(0, 255, 2, 1, &init, 3);
        assert_eq!(outputs.len(), 256);
    }

    #[test]
    fn test_find_matching_rules() {
        let init = vec![0, 0, 0, 1, 0, 0, 0];
        // Evolve rule 30 for 1 step to get target
        let target = run_ca_final(30, 2, 1, &init, 1);
        let matches = find_matching_rules(0, 255, 2, 1, &init, 1, &target);
        assert!(matches.contains(&30));
    }

    #[test]
    fn test_find_bounded_width_rules() {
        // Rule 0 (all die) should be bounded
        let init = vec![0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        let bounded = find_bounded_width_rules(0, 0, 2, 1, &init, 10, 5);
        assert!(bounded.contains(&0));
    }

    #[test]
    fn test_max_active_widths() {
        let init = vec![0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        let widths = max_active_widths_parallel(30, 30, 2, 1, &init, 5);
        // Should return [max_width, final_width]
        assert_eq!(widths.len(), 2);
        assert!(widths[0] > 0); // Rule 30 expands
    }

    #[test]
    fn test_find_width_ratio_rules() {
        // k=3, r=1: search a small range for width-doublers
        let w = 41;
        let mut init1 = vec![0u8; w];
        init1[w / 2] = 1;
        let mut init3 = vec![0u8; w];
        init3[w / 2 - 1] = 1;
        init3[w / 2] = 2;
        init3[w / 2 + 1] = 1;

        let initials = vec![
            CAState::new(init1, 3),
            CAState::new(init3, 3),
        ];

        // Search a range that contains known doublers (54240)
        let doublers = find_width_ratio_rules(54240, 54240, 3, 1, &initials, 15, 2, 1, 15);
        assert!(doublers.contains(&54240), "doublers: {:?}", doublers);
    }
}

// =============================================================================
// BigInt WLL exports (for k >= 4 where rule numbers exceed u64)
// =============================================================================

/// Run a CA with a BigInt rule number (passed as string) and return flat spacetime grid.
/// WL reshapes with Partition[result, width].
#[wll::export]
pub fn run_ca_bigint_wl(
    rule_number_str: String,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
) -> NumericArray<i32> {
    use num_bigint::BigUint;
    let rule_number: BigUint = match rule_number_str.parse::<BigUint>() {
        Ok(v) => v,
        Err(_) => return vec_u8_to_na_i32(Vec::new()),
    };
    let cells = na_to_cells(initial_cells);
    let ca = CellularAutomaton::from_rule_number_bigint(&rule_number, k, r);
    let initial = CAState::new(cells, k);
    let history = ca.evolve(&initial, steps as usize);
    let flat: Vec<u8> = history.into_iter().flat_map(|s| s.cells).collect();
    vec_u8_to_na_i32(flat)
}

/// Run a CA with a BigInt rule number (passed as string) and return just the final state.
#[wll::export]
pub fn run_ca_final_bigint_wl(
    rule_number_str: String,
    k: u32,
    r: u32,
    initial_cells: &NumericArray<i32>,
    steps: u64,
) -> NumericArray<i32> {
    use num_bigint::BigUint;
    let rule_number: BigUint = match rule_number_str.parse::<BigUint>() {
        Ok(v) => v,
        Err(_) => return vec_u8_to_na_i32(Vec::new()),
    };
    let cells = na_to_cells(initial_cells);
    let ca = CellularAutomaton::from_rule_number_bigint(&rule_number, k, r);
    let initial = CAState::new(cells, k);
    let final_state = ca.evolve_final(&initial, steps as usize);
    vec_u8_to_na_i32(final_state.cells)
}

/// Test a batch of BigInt candidate rules (passed as strings) against init/target.
/// Returns a Vec<i32> of 0/1 flags (1 = match, 0 = no match), same as test_rules_wl.
#[wll::export]
pub fn test_rules_bigint_wl(
    candidate_rule_strs: Vec<String>,
    k: u32,
    r: u32,
    init: &NumericArray<i32>,
    steps: u64,
    target: &NumericArray<i32>,
) -> NumericArray<i32> {
    use num_bigint::BigUint;
    use rayon::prelude::*;

    let init_cells = na_to_cells(init);
    let target_cells = na_to_cells(target);
    let initial = CAState::new(init_cells, k);

    let results: Vec<u8> = candidate_rule_strs
        .par_iter()
        .map(|rule_str| {
            if wll::aborted() { return 0u8; }
            let rule_number: BigUint = match rule_str.parse::<BigUint>() {
                Ok(v) => v,
                Err(_) => return 0u8,
            };
            let ca = CellularAutomaton::from_rule_number_bigint(&rule_number, k, r);
            let final_state = ca.evolve_final(&initial, steps as usize);
            if final_state.cells == target_cells { 1u8 } else { 0u8 }
        })
        .collect();
    vec_u8_to_na_i32(results)
}

/// Generate n random CA rules for given k, r directly as lookup tables,
/// test each against init→target, return matching rule numbers as BigUint strings.
/// GPU-accelerated on macOS, CPU fallback otherwise.
#[wll::export]
pub fn random_search_wl(
    n: u64,
    seed: u64,
    k: u32,
    r: u32,
    init: &NumericArray<i32>,
    steps: u64,
    target: &NumericArray<i32>,
) -> Vec<String> {
    let init_cells = na_to_cells(init);
    let target_cells = na_to_cells(target);
    let initial = CAState::new(init_cells.clone(), k);
    let target_state = CAState::new(target_cells.clone(), k);

    // For rules that fit in u64: generate random u64s, use existing GPU test_rules kernel
    let max_rule = CellularAutomaton::rule_count(k, r);
    let rules_fit_u64 = max_rule > 0; // rule_count returns u64, so if > 0 it fits

    #[cfg(all(target_os = "macos", feature = "gpu"))]
    if rules_fit_u64 {
        use rand::prelude::*;
        // Generate random rule numbers as u64, batch to GPU
        let gpu_batch = 1_000_000u64; // 1M per GPU dispatch
        let mut all_results: Vec<String> = Vec::new();
        let mut rng = StdRng::seed_from_u64(seed);
        let mut remaining = n;

        while remaining > 0 && !wll::aborted() {
            let batch = std::cmp::min(remaining, gpu_batch);
            let candidates: Vec<u64> = (0..batch).map(|_| rng.gen_range(0..max_rule)).collect();

            if let Some(flags) = gpu::try_test_rules(&candidates, k, r, &initial, steps as usize, &target_state) {
                for (i, &flag) in flags.iter().enumerate() {
                    if flag == 1 {
                        all_results.push(candidates[i].to_string());
                    }
                }
            } else {
                // GPU unavailable, break out and use CPU fallback below
                break;
            }
            remaining -= batch;
        }

        if remaining == 0 {
            return all_results;
        }
        // If we broke out due to GPU unavailability, fall through to CPU
    }

    // Try BigInt GPU random search (for k>=4)
    #[cfg(all(target_os = "macos", feature = "gpu"))]
    if !rules_fit_u64 {
        if let Some(results) = gpu::try_random_search(n, seed, k, r, &initial, steps as usize, &target_state) {
            return results;
        }
    }

    // CPU fallback
    use rayon::prelude::*;

    let neighborhood_size = (2 * r + 1) as u32;
    let table_size = (k as u64).pow(neighborhood_size) as usize;

    let chunk_size = 10000u64;
    let num_chunks = (n + chunk_size - 1) / chunk_size;

    (0..num_chunks)
        .into_par_iter()
        .flat_map(|chunk_idx| {
            if wll::aborted() { return Vec::new(); }
            use rand::prelude::*;
            let chunk_start = chunk_idx * chunk_size;
            let chunk_end = std::cmp::min(chunk_start + chunk_size, n);
            let mut rng = StdRng::seed_from_u64(seed.wrapping_add(chunk_idx));
            let mut results = Vec::new();

            for _ in chunk_start..chunk_end {
                if wll::aborted() { break; }
                let table: Vec<u8> = (0..table_size).map(|_| rng.gen_range(0..k as u8)).collect();
                let ca = CellularAutomaton::from_table(table, k, r);
                let final_state = ca.evolve_final(&initial, steps as usize);
                if final_state.cells == target_cells {
                    let rule_num = ca.to_rule_number_bigint();
                    results.push(rule_num.to_string());
                }
            }
            results
        })
        .collect()
}

/// Multi-pair random sieve: generate n random rules, sieve through all init→target pairs.
/// Returns rule numbers (as BigUint strings) that pass ALL pairs.
#[wll::export]
pub fn random_sieve_wl(
    n: u64,
    seed: u64,
    k: u32,
    r: u32,
    inits: Vec<Vec<i32>>,
    steps: u64,
    targets: Vec<Vec<i32>>,
) -> Vec<String> {
    use rayon::prelude::*;

    let neighborhood_size = (2 * r + 1) as u32;
    let table_size = (k as u64).pow(neighborhood_size) as usize;

    let pairs: Vec<(CAState, Vec<u8>)> = inits.iter().zip(targets.iter()).map(|(init, target)| {
        let init_cells: Vec<u8> = init.iter().map(|&c| c as u8).collect();
        let target_cells: Vec<u8> = target.iter().map(|&c| c as u8).collect();
        (CAState::new(init_cells, k), target_cells)
    }).collect();

    let chunk_size = 10000u64;
    let num_chunks = (n + chunk_size - 1) / chunk_size;

    (0..num_chunks)
        .into_par_iter()
        .flat_map(|chunk_idx| {
            if wll::aborted() { return Vec::new(); }
            use rand::prelude::*;
            let chunk_start = chunk_idx * chunk_size;
            let chunk_end = std::cmp::min(chunk_start + chunk_size, n);
            let mut rng = StdRng::seed_from_u64(seed.wrapping_add(chunk_idx));
            let mut results = Vec::new();

            for _ in chunk_start..chunk_end {
                if wll::aborted() { break; }
                let table: Vec<u8> = (0..table_size).map(|_| rng.gen_range(0..k as u8)).collect();
                let ca = CellularAutomaton::from_table(table, k, r);

                let matches_all = pairs.iter().all(|(init, target)| {
                    let final_state = ca.evolve_final(init, steps as usize);
                    final_state.cells == *target
                });

                if matches_all {
                    let rule_num = ca.to_rule_number_bigint();
                    results.push(rule_num.to_string());
                }
            }
            results
        })
        .collect()
}

/// GPU free-digit search: search the free-digit CA rule space exhaustively.
/// fixed_digits_flat: [pos0, val0, pos1, val1, ...] flattened fixed digit pairs
/// free_positions: [pos0, pos1, ...] free digit positions
/// init_cells_flat: concatenated padded init cells for all pairs
/// target_cells_flat: concatenated padded target cells for all pairs
/// tape_width: width of each padded tape
/// num_pairs: number of init→target pairs
#[wll::export]
pub fn search_free_wl(
    fixed_digits_flat: &NumericArray<i32>,
    free_positions: &NumericArray<i32>,
    k: u32,
    r: u32,
    init_cells_flat: &NumericArray<i32>,
    target_cells_flat: &NumericArray<i32>,
    tape_width: u64,
    steps: u64,
    num_pairs: u64,
) -> NumericArray<i64> {
    let fd_sl = fixed_digits_flat.as_slice();
    let fixed_digits: Vec<(u8, u8)> = fd_sl
        .chunks(2)
        .map(|c| (c[0] as u8, c[1] as u8))
        .collect();
    let free_pos: Vec<u8> = free_positions.as_slice().iter().map(|&p| p as u8).collect();

    let tw = tape_width as usize;
    let np = num_pairs as usize;
    let init_sl = init_cells_flat.as_slice();
    let target_sl = target_cells_flat.as_slice();
    let mut pairs: Vec<(CAState, CAState)> = Vec::new();
    for i in 0..np {
        let init_cells: Vec<u8> = init_sl[i * tw..(i + 1) * tw].iter().map(|&c| c as u8).collect();
        let target_cells: Vec<u8> = target_sl[i * tw..(i + 1) * tw].iter().map(|&c| c as u8).collect();
        pairs.push((CAState::new(init_cells, k), CAState::new(target_cells, k)));
    }

    #[cfg(all(target_os = "macos", feature = "gpu"))]
    if let Some(results) = gpu::try_search_free(k, r, &fixed_digits, &free_pos, &pairs, steps as usize) {
        return vec_u64_to_na(results);
    }

    // CPU fallback: exhaustive search over free-digit space
    use rayon::prelude::*;
    let table_size = (k as u64).pow((2 * r + 1) as u32) as usize;
    let num_free = free_pos.len();
    let total: u64 = (k as u64).pow(num_free as u32);

    let results: Vec<u64> = (0..total)
        .into_par_iter()
        .filter_map(|idx| {
            if wll::aborted() { return None; }
            let mut table = vec![0u8; table_size];
            for &(pos, val) in &fixed_digits {
                table[pos as usize] = val;
            }
            let mut val = idx;
            for &pos in &free_pos {
                table[pos as usize] = (val % k as u64) as u8;
                val /= k as u64;
            }
            let ca = CellularAutomaton::from_table(table.clone(), k, r);
            for (init, target) in &pairs {
                let final_state = ca.evolve_final(init, steps as usize);
                if final_state.cells != target.cells {
                    return None;
                }
            }
            // Compute rule number as u64
            let mut rule_num: u64 = 0;
            let mut pow_k: u64 = 1;
            for &d in &table {
                rule_num += d as u64 * pow_k;
                pow_k *= k as u64;
            }
            Some(rule_num)
        })
        .collect();
    vec_u64_to_na(results)
}
