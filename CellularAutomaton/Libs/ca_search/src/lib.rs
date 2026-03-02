use wolfram_library_link as wll;

wll::generate_loader!(rustlink_autodiscover);

use rayon::prelude::*;

pub mod models;
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
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            ca.evolve_final(&initial, steps).to_integer()
        })
        .collect()
}

/// Search for rules whose final state matches a target pattern.
/// Returns Vec of matching rule numbers. Parallelized with rayon.
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
    let target = target_cells.to_vec();
    (min_rule..=max_rule)
        .into_par_iter()
        .filter(|&rule_number| {
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
pub fn find_exact_width_rules(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initials: &[CAState],
    steps: usize,
    target_width: usize,
) -> Vec<u64> {
    let initials: Vec<_> = initials.to_vec();

    (min_rule..=max_rule)
        .into_par_iter()
        .filter(|&rule_number| {
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

/// Run a CA evolution and return the flat spacetime grid as a list of integers.
/// Width is passed so WL can reshape: Partition[result, width].
#[wll::export]
pub fn run_ca_wl(
    rule_number: u64,
    k: u32,
    r: u32,
    initial_cells: Vec<i32>,
    steps: u64,
) -> Vec<i32> {
    let cells: Vec<u8> = initial_cells.iter().map(|&c| c as u8).collect();
    let result = run_ca(rule_number, k, r, &cells, steps as usize);
    result.into_iter().map(|c| c as i32).collect()
}

/// Run a CA and return just the final state.
#[wll::export]
pub fn run_ca_final_wl(
    rule_number: u64,
    k: u32,
    r: u32,
    initial_cells: Vec<i32>,
    steps: u64,
) -> Vec<i32> {
    let cells: Vec<u8> = initial_cells.iter().map(|&c| c as u8).collect();
    let result = run_ca_final(rule_number, k, r, &cells, steps as usize);
    result.into_iter().map(|c| c as i32).collect()
}

/// Compute output table across a range of rules (parallelized).
/// Returns a flat list of output integers (one per rule).
#[wll::export]
pub fn ca_output_table_parallel_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: Vec<i32>,
    steps: u64,
) -> Vec<u64> {
    let cells: Vec<u8> = initial_cells.iter().map(|&c| c as u8).collect();
    ca_output_table_parallel(min_rule, max_rule, k, r, &cells, steps as usize)
}

/// Search for matching rules (parallelized).
/// Returns a list of rule numbers whose final state matches the target.
#[wll::export]
pub fn find_matching_rules_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: Vec<i32>,
    steps: u64,
    target_cells: Vec<i32>,
) -> Vec<u64> {
    let cells: Vec<u8> = initial_cells.iter().map(|&c| c as u8).collect();
    let target: Vec<u8> = target_cells.iter().map(|&c| c as u8).collect();
    find_matching_rules(min_rule, max_rule, k, r, &cells, steps as usize, &target)
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
    initial_cells: Vec<i32>,
    steps: u64,
) -> Vec<i32> {
    let cells: Vec<u8> = initial_cells.iter().map(|&c| c as u8).collect();
    let table = ca_evolution_table_parallel(min_rule, max_rule, k, r, &cells, steps as usize);
    table.into_iter().flatten().map(|c| c as i32).collect()
}

/// Find rules with bounded active width (parallelized).
/// Returns a list of rule numbers where the active region never exceeds max_width.
#[wll::export]
pub fn find_bounded_width_rules_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: Vec<i32>,
    steps: u64,
    max_width: u64,
) -> Vec<u64> {
    let cells: Vec<u8> = initial_cells.iter().map(|&c| c as u8).collect();
    find_bounded_width_rules(min_rule, max_rule, k, r, &cells, steps as usize, max_width as usize)
}

/// Compute max active widths for a range of rules (parallelized).
/// Returns flat list: [max0, final0, max1, final1, ...].
/// WL side can Partition[result, 2].
#[wll::export]
pub fn max_active_widths_parallel_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    initial_cells: Vec<i32>,
    steps: u64,
) -> Vec<u64> {
    let cells: Vec<u8> = initial_cells.iter().map(|&c| c as u8).collect();
    max_active_widths_parallel(min_rule, max_rule, k, r, &cells, steps as usize)
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
    flat_inits: Vec<i32>,
    num_inits: u64,
    steps: u64,
    ratio_num: u64,
    ratio_den: u64,
    max_width: u64,
) -> Vec<u64> {
    let num = num_inits as usize;
    let tape_width = flat_inits.len() / num;
    let initials: Vec<CAState> = flat_inits
        .chunks(tape_width)
        .map(|chunk| {
            let cells: Vec<u8> = chunk.iter().map(|&c| c as u8).collect();
            CAState::new(cells, k)
        })
        .collect();
    find_width_ratio_rules(
        min_rule, max_rule, k, r, &initials, steps as usize,
        ratio_num, ratio_den, max_width as usize,
    )
}

/// Find rules where the final active width = target_width for ALL inits.
/// `flat_inits` is a flat list of all initial conditions concatenated.
/// `num_inits` tells how many are packed.
#[wll::export]
pub fn find_exact_width_rules_wl(
    min_rule: u64,
    max_rule: u64,
    k: u32,
    r: u32,
    flat_inits: Vec<i32>,
    num_inits: u64,
    steps: u64,
    target_width: u64,
) -> Vec<u64> {
    let num = num_inits as usize;
    let tape_width = flat_inits.len() / num;
    let initials: Vec<CAState> = flat_inits
        .chunks(tape_width)
        .map(|chunk| {
            let cells: Vec<u8> = chunk.iter().map(|&c| c as u8).collect();
            CAState::new(cells, k)
        })
        .collect();
    find_exact_width_rules(
        min_rule, max_rule, k, r, &initials, steps as usize,
        target_width as usize,
    )
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
