/// Cellular Automaton models for 1D elementary and totalistic CAs.
///
/// An elementary CA (k=2, r=1) has 2^8 = 256 possible rules.
/// A general totalistic CA with k colors and radius r has k^(k*(2r+1)) possible outer-totalistic rules,
/// or k^(2r*k + 1) for standard totalistic rules.
///
/// This module defines the core data structures and stepping logic.

use std::hash::{Hash, Hasher};

/// Represents the state of a 1D cellular automaton at a single generation.
#[derive(Clone, Debug, Eq)]
pub struct CAState {
    /// The cell values (0..k-1)
    pub cells: Vec<u8>,
    /// Number of colors (symbols)
    pub k: u32,
}

impl CAState {
    /// Create a new CA state from a cell array.
    pub fn new(cells: Vec<u8>, k: u32) -> Self {
        CAState { cells, k }
    }

    /// Create a CA state with a single 1 in the center of a given width.
    pub fn single_cell(width: usize, k: u32) -> Self {
        let mut cells = vec![0u8; width];
        cells[width / 2] = 1;
        CAState { cells, k }
    }

    /// Create a CA state from an integer encoding.
    /// The integer is decoded as base-k digits (little-endian) padded to `width`.
    pub fn from_integer(n: u64, width: usize, k: u32) -> Self {
        let mut cells = vec![0u8; width];
        let mut val = n;
        // Place digits from the right side (little-endian into the right half)
        let start = width.saturating_sub(64); // ensure we don't overflow
        for i in (start..width).rev() {
            cells[i] = (val % k as u64) as u8;
            val /= k as u64;
            if val == 0 {
                break;
            }
        }
        CAState { cells, k }
    }

    /// Convert the cell array to an integer (base-k, big-endian).
    /// Returns u64::MAX if the value overflows.
    pub fn to_integer(&self) -> u64 {
        let mut result: u64 = 0;
        for &c in &self.cells {
            match result.checked_mul(self.k as u64).and_then(|r| r.checked_add(c as u64)) {
                Some(v) => result = v,
                None => return u64::MAX,
            }
        }
        result
    }

    /// Width of the CA state.
    pub fn width(&self) -> usize {
        self.cells.len()
    }

    /// Measure the active width: the span of non-zero cells.
    /// Returns 0 if all cells are zero.
    pub fn active_width(&self) -> usize {
        let first = self.cells.iter().position(|&c| c != 0);
        let last = self.cells.iter().rposition(|&c| c != 0);
        match (first, last) {
            (Some(f), Some(l)) => l - f + 1,
            _ => 0,
        }
    }
}

impl PartialEq for CAState {
    fn eq(&self, other: &Self) -> bool {
        self.cells == other.cells && self.k == other.k
    }
}

impl Hash for CAState {
    fn hash<H: Hasher>(&self, state: &mut H) {
        self.cells.hash(state);
        self.k.hash(state);
    }
}

/// A 1D cellular automaton rule.
#[derive(Clone, Debug)]
pub struct CellularAutomaton {
    /// The rule lookup table.
    /// For an elementary CA (k=2, r=1): 8 entries indexed by 3-cell neighborhood as binary number.
    /// For general (k, r): k^(2r+1) entries indexed by neighborhood as base-k number.
    pub rule_table: Vec<u8>,
    /// Number of colors
    pub k: u32,
    /// Radius of the neighborhood
    pub r: u32,
}

impl CellularAutomaton {
    /// Decode an elementary CA rule number (k=2, r=1) into a lookup table.
    /// Rule number 0..255 maps to 8-bit lookup table.
    pub fn elementary(rule_number: u32) -> Self {
        assert!(rule_number < 256, "Elementary CA rule must be 0..255");
        let mut table = vec![0u8; 8];
        for i in 0..8u32 {
            table[i as usize] = ((rule_number >> i) & 1) as u8;
        }
        CellularAutomaton {
            rule_table: table,
            k: 2,
            r: 1,
        }
    }

    /// Decode a general CA rule number for given k (colors) and r (radius).
    /// The neighborhood size is 2r+1, so there are k^(2r+1) possible neighborhoods.
    /// The rule number is decoded as base-k digits (little-endian).
    pub fn from_rule_number(rule_number: u64, k: u32, r: u32) -> Self {
        let neighborhood_size = (2 * r + 1) as usize;
        let num_neighborhoods = (k as u64).pow(neighborhood_size as u32) as usize;
        let mut table = vec![0u8; num_neighborhoods];
        let mut val = rule_number;
        for i in 0..num_neighborhoods {
            table[i] = (val % k as u64) as u8;
            val /= k as u64;
        }
        CellularAutomaton {
            rule_table: table,
            k,
            r,
        }
    }

    /// Decode a BigUint rule number for given k (colors) and r (radius).
    /// Same as from_rule_number but supports arbitrary precision.
    pub fn from_rule_number_bigint(rule_number: &num_bigint::BigUint, k: u32, r: u32) -> Self {
        use num_bigint::BigUint;
        let neighborhood_size = (2 * r + 1) as usize;
        let num_neighborhoods = (k as u64).pow(neighborhood_size as u32) as usize;
        let mut table = vec![0u8; num_neighborhoods];
        let k_big = BigUint::from(k);
        let mut val = rule_number.clone();
        let zero = BigUint::from(0u32);
        for i in 0..num_neighborhoods {
            if val == zero {
                break;
            }
            let rem = &val % &k_big;
            // rem fits in u8 since rem < k <= 255
            table[i] = rem.to_bytes_le().first().copied().unwrap_or(0);
            val /= &k_big;
        }
        CellularAutomaton {
            rule_table: table,
            k,
            r,
        }
    }

    /// Total number of possible rules for given k (colors) and r (radius).
    pub fn rule_count(k: u32, r: u32) -> u64 {
        let neighborhood_size = 2 * r + 1;
        let num_neighborhoods = (k as u64).pow(neighborhood_size);
        (k as u64).pow(num_neighborhoods as u32)
    }

    /// Convert the current rule table back to a BigUint rule number.
    pub fn to_rule_number_bigint(&self) -> num_bigint::BigUint {
        use num_bigint::BigUint;
        let k_big = BigUint::from(self.k);
        let mut result = BigUint::from(0u32);
        let mut power = BigUint::from(1u32);
        for &entry in &self.rule_table {
            result += BigUint::from(entry as u32) * &power;
            power *= &k_big;
        }
        result
    }

    /// Construct a CA directly from a random lookup table (no BigInt decode needed).
    pub fn from_table(table: Vec<u8>, k: u32, r: u32) -> Self {
        CellularAutomaton {
            rule_table: table,
            k,
            r,
        }
    }

    /// Compute the neighborhood index for position `pos` in `cells` with wrapping boundary.
    #[inline(always)]
    fn neighborhood_index(&self, cells: &[u8], pos: usize) -> usize {
        let width = cells.len();
        let r = self.r as usize;
        let mut index: usize = 0;
        for offset in 0..(2 * r + 1) {
            let neighbor_pos = (pos + width - r + offset) % width;
            index = index * self.k as usize + cells[neighbor_pos] as usize;
        }
        index
    }

    /// Evolve one step, writing result into `dst`. No allocations.
    #[inline]
    pub fn step_into(&self, src: &[u8], dst: &mut [u8]) {
        if self.r == 1 {
            self.step_into_r1(src, dst);
        } else {
            let width = src.len();
            for i in 0..width {
                let idx = self.neighborhood_index(src, i);
                dst[i] = self.rule_table[idx];
            }
        }
    }

    /// Specialized r=1 step with unsafe bounds elimination.
    /// Handles boundary wrapping explicitly, then uses unchecked access for the bulk.
    #[inline(always)]
    fn step_into_r1(&self, src: &[u8], dst: &mut [u8]) {
        let w = src.len();
        if w == 0 { return; }
        let k = self.k as usize;
        let table = &self.rule_table;

        // First cell: wraps left
        let idx0 = src[w - 1] as usize * k * k + src[0] as usize * k + src[1.min(w - 1)] as usize;
        dst[0] = table[idx0];

        // Middle cells: no wrapping needed, use unsafe for speed
        if w > 2 {
            unsafe {
                for i in 1..w - 1 {
                    let idx = *src.get_unchecked(i - 1) as usize * k * k
                        + *src.get_unchecked(i) as usize * k
                        + *src.get_unchecked(i + 1) as usize;
                    *dst.get_unchecked_mut(i) = *table.get_unchecked(idx);
                }
            }
        }

        // Last cell: wraps right
        if w > 1 {
            let idx_last = src[w - 2] as usize * k * k + src[w - 1] as usize * k + src[0] as usize;
            dst[w - 1] = table[idx_last];
        }
    }

    /// Evolve a CAState by one step. Returns the next generation.
    pub fn step(&self, state: &CAState) -> CAState {
        let mut next_cells = vec![0u8; state.width()];
        self.step_into(&state.cells, &mut next_cells);
        CAState { cells: next_cells, k: state.k }
    }

    /// Evolve a CAState for `steps` generations. Returns all generations (including initial).
    pub fn evolve(&self, initial: &CAState, steps: usize) -> Vec<CAState> {
        let mut history = Vec::with_capacity(steps + 1);
        history.push(initial.clone());
        let width = initial.width();
        let mut buf = vec![0u8; width];
        let mut current = initial.cells.clone();
        for _ in 0..steps {
            self.step_into(&current, &mut buf);
            history.push(CAState::new(buf.clone(), self.k));
            std::mem::swap(&mut current, &mut buf);
        }
        history
    }

    /// Evolve and return only the final state. Uses double-buffering — only 1 extra allocation.
    pub fn evolve_final(&self, initial: &CAState, steps: usize) -> CAState {
        let width = initial.width();
        let mut buf_a = initial.cells.clone();
        let mut buf_b = vec![0u8; width];
        for step in 0..steps {
            if step % 2 == 0 {
                self.step_into(&buf_a, &mut buf_b);
            } else {
                self.step_into(&buf_b, &mut buf_a);
            }
        }
        CAState::new(if steps % 2 == 0 { buf_a } else { buf_b }, self.k)
    }

    /// Compute the maximum active width across an entire evolution.
    /// Returns (max_width, final_width). Uses double-buffering.
    pub fn max_active_width(&self, initial: &CAState, steps: usize) -> (usize, usize) {
        let width = initial.width();
        let mut buf_a = initial.cells.clone();
        let mut buf_b = vec![0u8; width];
        let mut max_w = CAState::new(buf_a.clone(), self.k).active_width();
        for step in 0..steps {
            let (src, dst) = if step % 2 == 0 {
                (&buf_a as &[u8], &mut buf_b as &mut [u8])
            } else {
                (&buf_b as &[u8], &mut buf_a as &mut [u8])
            };
            self.step_into(src, dst);
            let state = CAState::new(dst.to_vec(), self.k);
            let w = state.active_width();
            if w > max_w { max_w = w; }
        }
        let final_cells = if steps % 2 == 0 { &buf_a } else { &buf_b };
        let final_w = CAState::new(final_cells.to_vec(), self.k).active_width();
        (max_w, final_w)
    }

    /// Check if the evolution has bounded width: the active region
    /// never exceeds `max_allowed_width` across `steps` generations.
    pub fn is_bounded_width(&self, initial: &CAState, steps: usize, max_allowed_width: usize) -> bool {
        self.is_bounded_width_fast(&initial.cells, steps, max_allowed_width)
    }

    /// Optimized bounded-width check using stack arrays, double-buffering,
    /// and boundary tracking. No heap allocations in the hot loop.
    pub fn is_bounded_width_fast(&self, initial_cells: &[u8], steps: usize, max_allowed_width: usize) -> bool {
        const MAX_TAPE: usize = 64;
        let width = initial_cells.len().min(MAX_TAPE);
        
        let mut buf_a = [0u8; MAX_TAPE];
        let mut buf_b = [0u8; MAX_TAPE];
        buf_a[..width].copy_from_slice(&initial_cells[..width]);

        // Find initial active boundaries
        let mut left = width;
        let mut right = 0usize;
        for i in 0..width {
            if buf_a[i] != 0 {
                if i < left { left = i; }
                if i > right { right = i; }
            }
        }
        if left > right {
            return true; // all zeros
        }

        let r = self.r as usize;
        let k = self.k as usize;
        let rule_table = &self.rule_table;

        // Use raw pointers for double-buffering without borrow issues
        let ptr_a = buf_a.as_mut_ptr();
        let ptr_b = buf_b.as_mut_ptr();
        let mut use_a = true;

        for _step in 0..steps {
            let (src, dst) = if use_a {
                (ptr_a, ptr_b)
            } else {
                (ptr_b, ptr_a)
            };

            // Expand the evaluation window by r (light cone), clamped to tape
            let eval_left = if left >= r + 1 { left - r - 1 } else { 0 };
            let eval_right = if right + r + 1 < width { right + r + 1 } else { width - 1 };

            // Zero the margin outside the eval window in dst
            unsafe {
                for i in eval_left..=eval_right {
                    // Compute neighborhood index inline for r=1
                    let idx = if r == 1 {
                        let l = if i == 0 { width - 1 } else { i - 1 };
                        let c = i;
                        let rr = if i + 1 >= width { 0 } else { i + 1 };
                        (*src.add(l)) as usize * k * k + (*src.add(c)) as usize * k + (*src.add(rr)) as usize
                    } else {
                        let mut idx = 0usize;
                        for offset in 0..(2 * r + 1) {
                            let neighbor_pos = (i + width - r + offset) % width;
                            idx = idx * k + (*src.add(neighbor_pos)) as usize;
                        }
                        idx
                    };
                    *dst.add(i) = rule_table[idx];
                }
            }

            // Update active boundaries from dst
            let mut new_left = width;
            let mut new_right = 0usize;
            unsafe {
                for i in eval_left..=eval_right {
                    if *dst.add(i) != 0 {
                        if i < new_left { new_left = i; }
                        if i > new_right { new_right = i; }
                    }
                }
            }

            if new_left > new_right {
                return true; // died out
            }

            let active_w = new_right - new_left + 1;
            if active_w > max_allowed_width {
                return false;
            }

            left = new_left;
            right = new_right;
            use_a = !use_a;
        }
        true
    }
}

// =============================================================================
// Bit-packed k=2 r=1 engine: 64 cells per u64 word, pure bitwise step
// =============================================================================

/// Pack byte-per-cell representation into bit-packed u64 words.
/// Cell 0 goes into bit 0 of word 0, cell 63 into bit 63 of word 0,
/// cell 64 into bit 0 of word 1, etc.
#[inline]
pub fn pack_cells_k2(cells: &[u8]) -> Vec<u64> {
    let num_words = (cells.len() + 63) / 64;
    let mut packed = vec![0u64; num_words];
    for (i, &c) in cells.iter().enumerate() {
        if c != 0 {
            packed[i / 64] |= 1u64 << (i % 64);
        }
    }
    packed
}

/// Unpack bit-packed u64 words back to byte-per-cell.
#[inline]
pub fn unpack_cells_k2(packed: &[u64], width: usize) -> Vec<u8> {
    let mut cells = vec![0u8; width];
    for i in 0..width {
        if packed[i / 64] & (1u64 << (i % 64)) != 0 {
            cells[i] = 1;
        }
    }
    cells
}

/// Compute one bit-packed step for any elementary CA rule.
/// `rule` is the rule number (0-255).
/// `src` and `dst` are bit-packed u64 arrays.
/// `width` is the total number of cells (for wrapping boundary).
///
/// For each cell, the neighborhood (L, C, R) is a 3-bit index into the rule.
/// We compute ALL 64 cells per word simultaneously using bitwise ops.
#[inline]
pub fn step_bitpacked_k2r1(rule: u8, src: &[u64], dst: &mut [u64], width: usize) {
    let num_words = src.len();
    if num_words == 0 { return; }

    for w in 0..num_words {
        let center = src[w];

        // Left neighbor of cell i is cell i-1 (lower index).
        // center << 1: result bit i = source bit i-1 (cell w*64+i-1) = left neighbor ✓
        // Carry: bit 0 of result needs MSB (bit 63) of previous word
        let prev_word = if w > 0 { src[w - 1] } else { src[num_words - 1] };
        let left = (center << 1) | (prev_word >> 63);

        // Right neighbor of cell i is cell i+1 (higher index).
        // center >> 1: result bit i = source bit i+1 (cell w*64+i+1) = right neighbor ✓
        // Carry: bit 63 of result needs LSB (bit 0) of next word
        let next_word = if w + 1 < num_words { src[w + 1] } else { src[0] };
        let right = (center >> 1) | (next_word << 63);

        // Mask out padding bits in the last word
        dst[w] = bitwise_rule_k2(rule, left, center, right);
    }

    // Mask out padding bits in the last word (cells beyond `width`)
    let remainder = width % 64;
    if remainder != 0 && num_words > 0 {
        dst[num_words - 1] &= (1u64 << remainder) - 1;
    }
}

/// Evaluate an elementary CA rule for 64 cells simultaneously.
/// `l`, `c`, `r` are the left, center, right neighbor words (bit-packed).
/// Returns the next-generation word.
///
/// Each bit position has a 3-bit neighborhood (l_i, c_i, r_i) → index 4*l_i + 2*c_i + r_i.
/// The output is rule bit at that index. We compute this via boolean decomposition:
/// output = OR of (rule_bit_j AND minterm_j) for j=0..7
#[inline(always)]
fn bitwise_rule_k2(rule: u8, l: u64, c: u64, r: u64) -> u64 {
    let nl = !l;
    let nc = !c;
    let nr = !r;
    let mut result = 0u64;
    // Neighborhood 000 (index 0): !L & !C & !R
    if rule & (1 << 0) != 0 { result |= nl & nc & nr; }
    // Neighborhood 001 (index 1): !L & !C & R
    if rule & (1 << 1) != 0 { result |= nl & nc & r; }
    // Neighborhood 010 (index 2): !L & C & !R
    if rule & (1 << 2) != 0 { result |= nl & c & nr; }
    // Neighborhood 011 (index 3): !L & C & R
    if rule & (1 << 3) != 0 { result |= nl & c & r; }
    // Neighborhood 100 (index 4): L & !C & !R
    if rule & (1 << 4) != 0 { result |= l & nc & nr; }
    // Neighborhood 101 (index 5): L & !C & R
    if rule & (1 << 5) != 0 { result |= l & nc & r; }
    // Neighborhood 110 (index 6): L & C & !R
    if rule & (1 << 6) != 0 { result |= l & c & nr; }
    // Neighborhood 111 (index 7): L & C & R
    if rule & (1 << 7) != 0 { result |= l & c & r; }
    result
}

/// Bit-packed evolve_final for k=2, r=1.
/// Packs once, runs all steps with double-buffered bitpacked arrays, unpacks once.
pub fn evolve_final_bitpacked_k2r1(rule_number: u64, initial_cells: &[u8], steps: usize) -> Vec<u8> {
    let width = initial_cells.len();
    let rule = rule_number as u8;
    let mut buf_a = pack_cells_k2(initial_cells);
    let mut buf_b = vec![0u64; buf_a.len()];

    for step in 0..steps {
        if step % 2 == 0 {
            step_bitpacked_k2r1(rule, &buf_a, &mut buf_b, width);
        } else {
            step_bitpacked_k2r1(rule, &buf_b, &mut buf_a, width);
        }
    }

    unpack_cells_k2(if steps % 2 == 0 { &buf_a } else { &buf_b }, width)
}

/// Bit-packed evolve (full history) for k=2, r=1.
/// Returns flat Vec<u8> of all (steps+1) generations concatenated.
pub fn evolve_bitpacked_k2r1(rule_number: u64, initial_cells: &[u8], steps: usize) -> Vec<u8> {
    let width = initial_cells.len();
    let rule = rule_number as u8;
    let mut buf_a = pack_cells_k2(initial_cells);
    let mut buf_b = vec![0u64; buf_a.len()];

    let mut result = Vec::with_capacity(width * (steps + 1));
    result.extend_from_slice(initial_cells);

    for step in 0..steps {
        if step % 2 == 0 {
            step_bitpacked_k2r1(rule, &buf_a, &mut buf_b, width);
            result.extend_from_slice(&unpack_cells_k2(&buf_b, width));
        } else {
            step_bitpacked_k2r1(rule, &buf_b, &mut buf_a, width);
            result.extend_from_slice(&unpack_cells_k2(&buf_a, width));
        }
    }
    result
}

/// Bit-packed bounded-width check for k=2, r=1.
/// Returns true if the active width never exceeds max_allowed_width.
pub fn is_bounded_bitpacked_k2r1(
    rule_number: u64, initial_cells: &[u8], steps: usize, max_allowed_width: usize
) -> bool {
    let width = initial_cells.len();
    let rule = rule_number as u8;
    let mut buf_a = pack_cells_k2(initial_cells);
    let mut buf_b = vec![0u64; buf_a.len()];

    for step in 0..steps {
        let (src, dst) = if step % 2 == 0 {
            (&buf_a, &mut buf_b)
        } else {
            (&buf_b, &mut buf_a)
        };
        step_bitpacked_k2r1(rule, src, dst, width);

        // Check active width from the packed representation
        let cells = unpack_cells_k2(dst, width);
        let first = cells.iter().position(|&c| c != 0);
        let last = cells.iter().rposition(|&c| c != 0);
        if let (Some(f), Some(l)) = (first, last) {
            if l - f + 1 > max_allowed_width {
                return false;
            }
        }
    }
    true
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_elementary_rule_30() {
        let ca = CellularAutomaton::elementary(30);
        // Rule 30: 00011110 in binary
        assert_eq!(ca.rule_table, vec![0, 1, 1, 1, 1, 0, 0, 0]);
        assert_eq!(ca.k, 2);
        assert_eq!(ca.r, 1);
    }

    #[test]
    fn test_elementary_rule_110() {
        let ca = CellularAutomaton::elementary(110);
        // Rule 110: 01101110 in binary
        assert_eq!(ca.rule_table, vec![0, 1, 1, 1, 0, 1, 1, 0]);
    }

    #[test]
    fn test_step_rule_30() {
        let ca = CellularAutomaton::elementary(30);
        // Start with a single cell in 7-wide tape
        let state = CAState::single_cell(7, 2);
        assert_eq!(state.cells, vec![0, 0, 0, 1, 0, 0, 0]);

        let next = ca.step(&state);
        // Rule 30 with wrapping: 001->1, 010->1, 100->1, rest->0
        assert_eq!(next.cells, vec![0, 0, 1, 1, 1, 0, 0]);
    }

    #[test]
    fn test_evolve_returns_correct_length() {
        let ca = CellularAutomaton::elementary(30);
        let state = CAState::single_cell(11, 2);
        let history = ca.evolve(&state, 5);
        assert_eq!(history.len(), 6); // initial + 5 steps
    }

    #[test]
    fn test_rule_count() {
        // Elementary CA: k=2, r=1 -> 2^8 = 256 rules
        assert_eq!(CellularAutomaton::rule_count(2, 1), 256);
    }

    #[test]
    fn test_ca_state_integer_roundtrip() {
        let state = CAState::from_integer(42, 8, 2);
        let val = state.to_integer();
        assert_eq!(val, 42);
    }

    #[test]
    fn test_active_width() {
        let state = CAState::new(vec![0, 0, 1, 1, 1, 0, 0], 2);
        assert_eq!(state.active_width(), 3);

        let zero = CAState::new(vec![0, 0, 0, 0, 0], 2);
        assert_eq!(zero.active_width(), 0);

        let single = CAState::new(vec![0, 0, 1, 0, 0], 2);
        assert_eq!(single.active_width(), 1);
    }

    #[test]
    fn test_bounded_width_rule_0() {
        // Rule 0: all cells die → trivially bounded
        let ca = CellularAutomaton::elementary(0);
        let init = CAState::single_cell(21, 2);
        assert!(ca.is_bounded_width(&init, 10, 5));
    }
}
