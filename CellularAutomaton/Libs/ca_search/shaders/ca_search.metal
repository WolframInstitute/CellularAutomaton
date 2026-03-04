#include <metal_stdlib>
using namespace metal;

// General-purpose 1D cellular automaton search kernel
// Supports k=2,3,4 colors, r=1 radius
// Each thread tests one rule number

#define MAX_TAPE 256
#define MAX_TABLE 64  // k^3 for k=4, r=1

// Evolve CA for given steps, return final active width (span from first to last nonzero)
uint evolve_and_measure_width(
    thread const uchar* table,
    uint k,
    thread const uchar* init,
    uint tape_width,
    uint steps
) {
    uchar a[MAX_TAPE], b[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) { a[i] = init[i]; b[i] = 0; }

    uint k2 = k * k;

    for (uint step = 0; step < steps; step++) {
        thread uchar* src = (step & 1) ? b : a;
        thread uchar* dst = (step & 1) ? a : b;
        for (uint i = 0; i < tape_width; i++) {
            uint li = (i == 0) ? (tape_width - 1) : (i - 1);
            uint ri = (i + 1 >= tape_width) ? 0 : (i + 1);
            dst[i] = table[src[li] * k2 + src[i] * k + src[ri]];
        }
    }

    // After steps iterations: step 0 writes to b, step 1 to a, ...
    // Even step count → result in a; odd → result in b
    thread const uchar* final_buf = (steps & 1) ? b : a;
    uint nl = tape_width, nr = 0;
    for (uint i = 0; i < tape_width; i++) {
        if (final_buf[i] != 0) {
            if (i < nl) nl = i;
            nr = i;
        }
    }
    if (nl > nr) return 0;
    return nr - nl + 1;
}

// Check if final state matches target exactly
bool evolve_and_match(
    thread const uchar* table,
    uint k,
    thread const uchar* init,
    device const uchar* target,
    uint tape_width,
    uint steps
) {
    uchar a[MAX_TAPE], b[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) { a[i] = init[i]; b[i] = 0; }

    uint k2 = k * k;

    for (uint step = 0; step < steps; step++) {
        thread uchar* src = (step & 1) ? b : a;
        thread uchar* dst = (step & 1) ? a : b;
        for (uint i = 0; i < tape_width; i++) {
            uint li = (i == 0) ? (tape_width - 1) : (i - 1);
            uint ri = (i + 1 >= tape_width) ? 0 : (i + 1);
            dst[i] = table[src[li] * k2 + src[i] * k + src[ri]];
        }
    }

    thread const uchar* final_buf = (steps & 1) ? b : a;
    for (uint i = 0; i < tape_width; i++) {
        if (final_buf[i] != target[i]) return false;
    }
    return true;
}

// Check if max active width never exceeds bound during evolution
bool evolve_bounded(
    thread const uchar* table,
    uint k,
    thread const uchar* init,
    uint tape_width,
    uint steps,
    uint max_width
) {
    uchar a[MAX_TAPE], b[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) { a[i] = init[i]; b[i] = 0; }

    uint k2 = k * k;

    for (uint step = 0; step < steps; step++) {
        thread uchar* src = (step & 1) ? b : a;
        thread uchar* dst = (step & 1) ? a : b;
        uint nl = tape_width, nr = 0;
        for (uint i = 0; i < tape_width; i++) {
            uint li = (i == 0) ? (tape_width - 1) : (i - 1);
            uint ri = (i + 1 >= tape_width) ? 0 : (i + 1);
            uchar v = table[src[li] * k2 + src[i] * k + src[ri]];
            dst[i] = v;
            if (v != 0) { if (i < nl) nl = i; nr = i; }
        }
        if (nl <= nr) {
            uint w = nr - nl + 1;
            if (w > max_width) return false;
        }
    }
    return true;
}

// Build rule table from rule number for k colors
void build_table(uint64_t rule_number, uint k, thread uchar* table, uint table_size) {
    uint64_t val = rule_number;
    for (uint i = 0; i < table_size; i++) {
        table[i] = (uchar)(val % k);
        val /= k;
    }
}

// ============================================================================
// Kernel: find rules with exact final active width
// ============================================================================
// params[0] = start_rule, params[1] = count, params[2] = k, params[3] = tape_width
// params[4] = steps, params[5] = target_width
kernel void ca_find_exact_width(
    device const uint64_t* params [[buffer(0)]],
    device const uchar* init_cells [[buffer(1)]],
    device atomic_uint* result_count [[buffer(2)]],
    device uint64_t* result_rules [[buffer(3)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t count = params[1];
    if (tid >= count) return;

    uint64_t rule_number = params[0] + (uint64_t)tid;
    uint k = (uint)params[2];
    uint tape_width = (uint)params[3];
    uint steps = (uint)params[4];
    uint target_width = (uint)params[5];

    uchar table[MAX_TABLE];
    uint table_size = k * k * k; // k^(2r+1) for r=1
    build_table(rule_number, k, table, table_size);

    // Copy init to thread-local
    uchar init[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) init[i] = init_cells[i];

    uint w = evolve_and_measure_width(table, k, init, tape_width, steps);
    if (w == target_width) {
        uint pos = atomic_fetch_add_explicit(result_count, 1, memory_order_relaxed);
        if (pos < 1000000) {
            result_rules[pos] = rule_number;
        }
    }
}

// ============================================================================
// Kernel: find rules matching exact target array
// ============================================================================
kernel void ca_find_matching(
    device const uint64_t* params [[buffer(0)]],
    device const uchar* init_cells [[buffer(1)]],
    device atomic_uint* result_count [[buffer(2)]],
    device uint64_t* result_rules [[buffer(3)]],
    device const uchar* target_cells [[buffer(4)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t count = params[1];
    if (tid >= count) return;

    uint64_t rule_number = params[0] + (uint64_t)tid;
    uint k = (uint)params[2];
    uint tape_width = (uint)params[3];
    uint steps = (uint)params[4];

    uchar table[MAX_TABLE];
    uint table_size = k * k * k;
    build_table(rule_number, k, table, table_size);

    uchar init[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) init[i] = init_cells[i];

    if (evolve_and_match(table, k, init, target_cells, tape_width, steps)) {
        uint pos = atomic_fetch_add_explicit(result_count, 1, memory_order_relaxed);
        if (pos < 1000000) {
            result_rules[pos] = rule_number;
        }
    }
}

// ============================================================================
// Kernel: find rules with bounded active width
// ============================================================================
kernel void ca_find_bounded(
    device const uint64_t* params [[buffer(0)]],
    device const uchar* init_cells [[buffer(1)]],
    device atomic_uint* result_count [[buffer(2)]],
    device uint64_t* result_rules [[buffer(3)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t count = params[1];
    if (tid >= count) return;

    uint64_t rule_number = params[0] + (uint64_t)tid;
    uint k = (uint)params[2];
    uint tape_width = (uint)params[3];
    uint steps = (uint)params[4];
    uint max_width = (uint)params[5];

    uchar table[MAX_TABLE];
    uint table_size = k * k * k;
    build_table(rule_number, k, table, table_size);

    uchar init[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) init[i] = init_cells[i];

    if (evolve_bounded(table, k, init, tape_width, steps, max_width)) {
        uint pos = atomic_fetch_add_explicit(result_count, 1, memory_order_relaxed);
        if (pos < 1000000) {
            result_rules[pos] = rule_number;
        }
    }
}

// ============================================================================
// NKS-faithful k=3 r=1 width-doubler kernel
// Matches doubleasymmi.c from NKS BookConstructionPrograms:
// - Convergence-based check (evolve until unchanged, then verify)
// - Init: {1^(n-1), 2} for test n, expected output: {0...0, 1^(2n), 0...0}
// - 6 fixed digits, 21 free = 3^21 search space
// ============================================================================

// NKS step counts per test (from doubleasymmi.c steparray)
constant int nks_steps[] = {6, 15, 30, 62, 68, 78, 152, 230, 252, 338, 428, 582};

// Returns 1 if doubler, 0 if not, -1 if didn't converge
int check_doubling_nks(thread const uchar* table, uint nin, int steps) {
    int w = 2 * steps + 1;

    // Thread-local array for up to test 12 (582 steps, tape=1165)
    uchar a[1201];
    if (w > 1201) return -1;

    for (int i = 0; i < w; i++) a[i] = 0;

    // Init: {1^(nin-1), 2} placed at center
    for (int i = 0; i < (int)nin - 1; i++) a[steps + i] = 1;
    a[steps + nin - 1] = 2;

    for (int t = 0; t < steps; t++) {
        int changed = 0;
        uchar b = a[0];
        for (int i = 1; i < w - 1; i++) {
            uchar bp = a[i];
            uchar bx = table[b * 9 + bp * 3 + a[i + 1]];
            a[i] = bx;
            b = bp;
            if (bx != bp) changed = 1;
        }
        if (!changed) {
            // Converged — verify: left zeros, 2*nin ones, right zeros
            for (int i = 1; i < steps; i++)
                if (a[i] != 0) return 0;
            for (int i = 0; i < (int)(2 * nin); i++)
                if (a[steps + i] != 1) return 0;
            for (int i = steps + 2 * nin; i < w; i++)
                if (a[i] != 0) return 0;
            return 1;
        }
    }
    return -1; // didn't converge
}

// params[0] = start_idx (free-digit combination index)
// params[1] = count
// params[2] = num_tests (how many doubling tests to run, max 12)
kernel void ca_find_doublers(
    device const uint64_t* params [[buffer(0)]],
    device atomic_uint* result_count [[buffer(1)]],
    device uint64_t* result_rules [[buffer(2)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t count = params[1];
    if (tid >= count) return;

    uint64_t free_idx = params[0] + (uint64_t)tid;
    uint num_tests = (uint)params[2];
    if (num_tests == 0 || num_tests > 12) num_tests = 7;

    // Build rule table: 7 fixed digits, 20 free
    uchar table[27];
    table[0] = 0;   // rule[0][0][0] = 0
    table[1] = 0;   // rule[0][0][1] = 0
    table[2] = 0;   // rule[0][0][2] = 0 (universal across all NKS doublers)
    table[4] = 1;   // rule[0][1][1] = 1
    table[9] = 0;   // rule[1][0][0] = 0
    table[12] = 1;  // rule[1][1][0] = 1
    table[13] = 1;  // rule[1][1][1] = 1

    // 20 free positions
    const uint free_idx_arr[20] = {3, 5, 6, 7, 8, 10, 11, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26};

    uint64_t val = free_idx;
    for (uint i = 0; i < 20; i++) {
        table[free_idx_arr[i]] = (uchar)(val % 3);
        val /= 3;
    }

    // Tests: for nin = 1..num_tests, check {1^(nin-1), 2} → {1^(2*nin)}
    for (uint nin = 1; nin <= num_tests; nin++) {
        int steps = (nin <= 12) ? nks_steps[nin - 1] : (int)(nin * 200);
        int result = check_doubling_nks(table, nin, steps);
        if (result != 1) return;
    }

    // All tests passed — compute rule number
    uint64_t rule_number = 0;
    uint64_t pow3 = 1;
    for (uint d = 0; d < 27; d++) {
        rule_number += (uint64_t)table[d] * pow3;
        pow3 *= 3;
    }

    uint pos = atomic_fetch_add_explicit(result_count, 1, memory_order_relaxed);
    if (pos < 1000000) {
        result_rules[pos] = rule_number;
    }
}

// Large-tape convergence check for refine pass (supports up to ~600 steps)
int check_doubling_large(thread const uchar* table, uint nin, int steps) {
    int w = 2 * steps + 1;
    uchar a[1201];
    if (w > 1201) return -1;

    for (int i = 0; i < w; i++) a[i] = 0;
    for (int i = 0; i < (int)nin - 1; i++) a[steps + i] = 1;
    a[steps + nin - 1] = 2;

    for (int t = 0; t < steps; t++) {
        int changed = 0;
        uchar b = a[0];
        for (int i = 1; i < w - 1; i++) {
            uchar bp = a[i];
            uchar bx = table[b * 9 + bp * 3 + a[i + 1]];
            a[i] = bx;
            b = bp;
            if (bx != bp) changed = 1;
        }
        if (!changed) {
            for (int i = 1; i < steps; i++)
                if (a[i] != 0) return 0;
            for (int i = 0; i < (int)(2 * nin); i++)
                if (a[steps + i] != 1) return 0;
            for (int i = steps + 2 * nin; i < w; i++)
                if (a[i] != 0) return 0;
            return 1;
        }
    }
    return -1;
}

// Refine kernel: takes rule numbers as input, runs tests start_test..end_test.
// params[0] = count (number of candidate rules)
// params[1] = start_test (nin to start from)
// params[2] = end_test (nin to end at, inclusive)
kernel void ca_refine_doublers(
    device const uint64_t* params [[buffer(0)]],
    device const uint64_t* input_rules [[buffer(1)]],
    device atomic_uint* result_count [[buffer(2)]],
    device uint64_t* result_rules [[buffer(3)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t count = params[0];
    if (tid >= count) return;

    uint64_t rule_number = input_rules[tid];
    uint start_test = (uint)params[1];
    uint end_test = (uint)params[2];

    // Decode rule number to table
    uchar table[27];
    uint64_t val = rule_number;
    for (uint d = 0; d < 27; d++) {
        table[d] = (uchar)(val % 3);
        val /= 3;
    }

    for (uint nin = start_test; nin <= end_test; nin++) {
        int steps = (nin <= 12) ? nks_steps[nin - 1] : (int)(nin * 50);
        int result = check_doubling_large(table, nin, steps);
        if (result != 1) return;
    }

    uint pos = atomic_fetch_add_explicit(result_count, 1, memory_order_relaxed);
    if (pos < 1000000) {
        result_rules[pos] = rule_number;
    }
}

// ============================================================================
// General-purpose kernel: test list of rules against init→target
// ============================================================================
// params[0] = count, params[1] = k, params[2] = tape_width, params[3] = steps
// input_rules: list of rule numbers to test
// init_cells: initial state
// target_cells: expected final state
// output: 0/1 per rule (same length as input_rules)
kernel void ca_test_rules(
    device const uint64_t* params [[buffer(0)]],
    device const uint64_t* input_rules [[buffer(1)]],
    device const uchar* init_cells [[buffer(2)]],
    device const uchar* target_cells [[buffer(3)]],
    device uchar* output [[buffer(4)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t count = params[0];
    if (tid >= count) return;

    uint64_t rule_number = input_rules[tid];
    uint k = (uint)params[1];
    uint tape_width = (uint)params[2];
    uint steps = (uint)params[3];

    uchar table[MAX_TABLE];
    uint table_size = k * k * k;
    build_table(rule_number, k, table, table_size);

    uchar init[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) init[i] = init_cells[i];

    output[tid] = evolve_and_match(table, k, init, target_cells, tape_width, steps) ? 1 : 0;
}

// ============================================================================
// General-purpose kernel: filter list of rules by exact width
// ============================================================================
// params[0] = count, params[1] = k, params[2] = tape_width,
// params[3] = steps, params[4] = target_width
kernel void ca_filter_width_list(
    device const uint64_t* params [[buffer(0)]],
    device const uint64_t* input_rules [[buffer(1)]],
    device const uchar* init_cells [[buffer(2)]],
    device atomic_uint* result_count [[buffer(3)]],
    device uint64_t* result_rules [[buffer(4)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t count = params[0];
    if (tid >= count) return;

    uint64_t rule_number = input_rules[tid];
    uint k = (uint)params[1];
    uint tape_width = (uint)params[2];
    uint steps = (uint)params[3];
    uint target_width = (uint)params[4];

    uchar table[MAX_TABLE];
    uint table_size = k * k * k;
    build_table(rule_number, k, table, table_size);

    uchar init[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) init[i] = init_cells[i];

    uint w = evolve_and_measure_width(table, k, init, tape_width, steps);
    if (w == target_width) {
        uint pos = atomic_fetch_add_explicit(result_count, 1, memory_order_relaxed);
        if (pos < 1000000) {
            result_rules[pos] = rule_number;
        }
    }
}

// ============================================================================
// Random search kernel: generate random rule tables on GPU
// For k>=4 where rule numbers exceed uint64.
// Each thread generates a random lookup table via hash-based PRNG,
// tests against init→target, and writes matching tables to output.
// ============================================================================

// PCG hash for per-thread random state
uint pcg_hash(uint state) {
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737u;
    return (word >> 22u) ^ word;
}

// params[0] = n (total threads), params[1] = seed_lo, params[2] = seed_hi
// params[3] = k, params[4] = tape_width, params[5] = steps
// params[6] = table_size (k^(2r+1))
kernel void ca_random_search(
    device const uint64_t* params [[buffer(0)]],
    device const uchar* init_cells [[buffer(1)]],
    device const uchar* target_cells [[buffer(2)]],
    device atomic_uint* result_count [[buffer(3)]],
    device uchar* result_tables [[buffer(4)]],  // MAX_OUTPUT * table_size bytes
    uint tid [[thread_position_in_grid]]
) {
    uint64_t n = params[0];
    if (tid >= n) return;

    uint64_t seed = params[1] | (params[2] << 32);
    uint k = (uint)params[3];
    uint tape_width = (uint)params[4];
    uint steps = (uint)params[5];
    uint table_size = (uint)params[6];

    // Generate random table using PCG hash chain
    uint state = pcg_hash((uint)(seed ^ (uint64_t)tid));
    state = pcg_hash(state ^ (uint)(seed >> 32));

    uchar table[MAX_TABLE];
    for (uint i = 0; i < table_size; i++) {
        state = pcg_hash(state);
        table[i] = (uchar)(state % k);
    }

    // Copy init
    uchar init[MAX_TAPE];
    for (uint i = 0; i < tape_width; i++) init[i] = init_cells[i];

    // Test
    if (evolve_and_match(table, k, init, target_cells, tape_width, steps)) {
        uint pos = atomic_fetch_add_explicit(result_count, 1, memory_order_relaxed);
        if (pos < 1000000) {
            // Write matching table to output
            for (uint i = 0; i < table_size; i++) {
                result_tables[pos * table_size + i] = table[i];
            }
        }
    }
}
