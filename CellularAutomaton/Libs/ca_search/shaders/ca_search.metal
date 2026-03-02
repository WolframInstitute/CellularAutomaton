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
