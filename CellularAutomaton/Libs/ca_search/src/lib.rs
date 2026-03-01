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

/// Find rules whose active width stays bounded (never exceeds max_width).
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
    let initial = CAState::new(initial_cells.to_vec(), k);
    (min_rule..=max_rule)
        .into_par_iter()
        .filter(|&rule_number| {
            let ca = CellularAutomaton::from_rule_number(rule_number, k, r);
            ca.is_bounded_width(&initial, steps, max_width)
        })
        .collect()
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
}
