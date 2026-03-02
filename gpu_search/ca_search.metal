#include <metal_stdlib>
using namespace metal;

// Each GPU thread processes one rule.
// Bounded rules are appended to output buffer via atomic counter.
// This eliminates the CPU-side 100M-element scan.

kernel void ca_bounded_search(
    device const uint64_t* params [[buffer(0)]],  // [start_rule, count, steps, max_width]
    device atomic_uint* counter [[buffer(1)]],     // atomic counter for output position
    device uint64_t* output [[buffer(2)]],         // output: bounded rule numbers
    uint tid [[thread_position_in_grid]]
) {
    uint64_t start_rule = params[0];
    uint64_t count = params[1];
    uint steps = (uint)params[2];
    uint max_width = (uint)params[3];

    if (tid >= count) return;

    uint64_t rule_number = start_rule + (uint64_t)tid * 3;

    // Decode rule table: 27 base-3 digits
    uchar table[27];
    uint64_t val = rule_number;
    for (uint j = 0; j < 27; j++) {
        table[j] = (uchar)(val % 3);
        val /= 3;
    }

    // Digit-level structural constraints
    if (table[1] == 1 || table[9] == 1) return;
    if (table[1] == 2 && table[2] != 0) return;
    if (table[9] == 2 && table[18] != 0) return;

    // Analytical 3-step pre-filter
    uint d1 = table[1];
    uint d3 = table[3];
    uint d9 = table[9];

    bool trivially_bounded = (d1 == 0 && d3 == 0 && d9 == 0);

    if (!trivially_bounded) {
        uint s2_0 = table[d1];
        uint s2_4 = table[d9 * 9];
        if (s2_0 != 0 && table[s2_0] != 0) return;
        if (s2_4 != 0 && table[s2_4 * 9] != 0) return;

        // Full bounded-width evolution on 41-cell tape
        uchar a[41];
        uchar b[41];
        for (uint i = 0; i < 41; i++) { a[i] = 0; b[i] = 0; }
        a[20] = 1;

        uint left_bound = 20;
        uint right_bound = 20;

        for (uint step = 0; step < steps; step++) {
            uint el = (left_bound >= 2) ? (left_bound - 2) : 0;
            uint er = (right_bound + 2 < 41) ? (right_bound + 2) : 40;

            uint nl = 41;
            uint nr = 0;

            if (step & 1) {
                for (uint i = el; i <= er; i++) {
                    uint li = (i == 0) ? 40 : (i - 1);
                    uint ri = (i + 1 >= 41) ? 0 : (i + 1);
                    uchar v = table[b[li] * 9 + b[i] * 3 + b[ri]];
                    a[i] = v;
                    if (v != 0) {
                        if (i < nl) nl = i;
                        nr = i;
                    }
                }
            } else {
                for (uint i = el; i <= er; i++) {
                    uint li = (i == 0) ? 40 : (i - 1);
                    uint ri = (i + 1 >= 41) ? 0 : (i + 1);
                    uchar v = table[a[li] * 9 + a[i] * 3 + a[ri]];
                    b[i] = v;
                    if (v != 0) {
                        if (i < nl) nl = i;
                        nr = i;
                    }
                }
            }

            if (nl > nr) { break; } // died → bounded
            if (nr - nl + 1 > max_width) return; // too wide → not bounded

            left_bound = nl;
            right_bound = nr;
        }
    }

    // Bounded! Atomic append to output buffer
    uint pos = atomic_fetch_add_explicit(counter, 1, memory_order_relaxed);
    output[pos] = rule_number;
}
