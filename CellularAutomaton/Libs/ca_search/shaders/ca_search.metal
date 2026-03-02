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
// Specialized k=3 r=1 width-doubler kernel
// Uses analytical constraints: 8 fixed digits, 19 free = 3^19 search space
// Tests {1^n, 2} → {1^(2(n+1))} for n=0..6 (7 tests per candidate)
// ============================================================================

#define DTAPE 81
#define DSTEPS 200

bool check_doubling(thread const uchar* table, uint init_width, thread const uchar* init_pattern) {
    uchar a[DTAPE], b[DTAPE];
    uint center = DTAPE / 2;
    for (uint i = 0; i < DTAPE; i++) { a[i] = 0; b[i] = 0; }

    uint start = center - init_width / 2;
    for (uint i = 0; i < init_width; i++) {
        a[start + i] = init_pattern[i];
    }

    uint left_bound = start;
    uint right_bound = start + init_width - 1;
    uint expected_width = init_width * 2;

    for (uint step = 0; step < DSTEPS; step++) {
        uint el = (left_bound >= 2) ? (left_bound - 2) : 0;
        uint er = (right_bound + 2 < DTAPE) ? (right_bound + 2) : (DTAPE - 1);
        uint nl = DTAPE, nr = 0;

        if (step & 1) {
            for (uint i = el; i <= er; i++) {
                uint li = (i == 0) ? (DTAPE - 1) : (i - 1);
                uint ri = (i + 1 >= DTAPE) ? 0 : (i + 1);
                uchar v = table[b[li] * 9 + b[i] * 3 + b[ri]];
                a[i] = v;
                if (v != 0) { if (i < nl) nl = i; nr = i; }
            }
        } else {
            for (uint i = el; i <= er; i++) {
                uint li = (i == 0) ? (DTAPE - 1) : (i - 1);
                uint ri = (i + 1 >= DTAPE) ? 0 : (i + 1);
                uchar v = table[a[li] * 9 + a[i] * 3 + a[ri]];
                b[i] = v;
                if (v != 0) { if (i < nl) nl = i; nr = i; }
            }
        }

        if (nl > nr) return false;
        uint w = nr - nl + 1;
        if (w > expected_width + 2) return false;
        if (w >= DTAPE - 4) return false;
        left_bound = nl;
        right_bound = nr;
    }

    thread const uchar* final_buf = (DSTEPS & 1) ? a : b;
    uint nl = DTAPE, nr = 0;
    for (uint i = 0; i < DTAPE; i++) {
        if (final_buf[i] != 0) {
            if (i < nl) nl = i;
            nr = i;
        }
    }
    if (nl > nr) return false;
    uint final_width = nr - nl + 1;
    if (final_width != expected_width) return false;
    for (uint i = nl; i <= nr; i++) {
        if (final_buf[i] != 1) return false;
    }
    return true;
}

// params[0] = start_idx (free-digit combination index)
// params[1] = count
// params[2] = num_tests (how many doubling tests to run, default 7)
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
    if (num_tests == 0 || num_tests > 7) num_tests = 7;

    // Build rule table: 8 fixed digits, 19 free
    uchar table[27];
    table[0] = 0; table[1] = 0; table[2] = 0;
    table[4] = 1; table[6] = 1; table[9] = 0;
    table[12] = 1; table[13] = 1;

    const uint free_idx_arr[19] = {3, 5, 7, 8, 10, 11, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26};

    uint64_t val = free_idx;
    for (uint i = 0; i < 19; i++) {
        table[free_idx_arr[i]] = (uchar)(val % 3);
        val /= 3;
    }

    // Pre-filter: d3 must be 1 or 2
    if (table[3] == 0) return;

    // Tests: {1^n, 2} → {1^(2(n+1))} for n = 0..(num_tests-1)
    for (uint n = 0; n < num_tests; n++) {
        uint w = n + 1;
        uchar init[8];
        for (uint i = 0; i < n; i++) init[i] = 1;
        init[n] = 2;
        if (!check_doubling(table, w, init)) return;
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

