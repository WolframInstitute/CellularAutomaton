#include <metal_stdlib>
using namespace metal;

// Two-pass GPU search:
// Pass 1: Count bounded rules (just atomic counter, no output)
// Pass 2: Detect width-doubling rules among bounded ones (rare, save these)
//
// Width doubler detection: run 200 steps on larger tape,
// record width at each step. Check if width grows and
// the growth pattern shows periodic doubling.

#define TAPE_SIZE 201  // 200 steps max expansion + center
#define MAX_STEPS 200

kernel void ca_count_bounded(
    device const uint64_t* params [[buffer(0)]],  // [start_rule, count, steps, max_width]
    device atomic_uint* bounded_count [[buffer(1)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t start_rule = params[0];
    uint64_t count = params[1];
    uint steps = (uint)params[2];
    uint max_width = (uint)params[3];

    if (tid >= count) return;

    uint64_t rule_number = start_rule + (uint64_t)tid * 3;

    // Decode rule table
    uchar table[27];
    uint64_t val = rule_number;
    for (uint j = 0; j < 27; j++) {
        table[j] = (uchar)(val % 3);
        val /= 3;
    }

    // Digit-level constraints
    if (table[1] == 1 || table[9] == 1) return;
    if (table[1] == 2 && table[2] != 0) return;
    if (table[9] == 2 && table[18] != 0) return;

    // Analytical 3-step pre-filter
    uint d1 = table[1], d3 = table[3], d9 = table[9];
    if (d1 == 0 && d3 == 0 && d9 == 0) {
        atomic_fetch_add_explicit(bounded_count, 1, memory_order_relaxed);
        return;
    }
    uint s2_0 = table[d1], s2_4 = table[d9 * 9];
    if (s2_0 != 0 && table[s2_0] != 0) return;
    if (s2_4 != 0 && table[s2_4 * 9] != 0) return;

    // Full evolution on 41-cell tape
    uchar a[41], b[41];
    for (uint i = 0; i < 41; i++) { a[i] = 0; b[i] = 0; }
    a[20] = 1;
    uint left_bound = 20, right_bound = 20;

    for (uint step = 0; step < steps; step++) {
        uint el = (left_bound >= 2) ? (left_bound - 2) : 0;
        uint er = (right_bound + 2 < 41) ? (right_bound + 2) : 40;
        uint nl = 41, nr = 0;

        if (step & 1) {
            for (uint i = el; i <= er; i++) {
                uint li = (i == 0) ? 40 : (i - 1);
                uint ri = (i + 1 >= 41) ? 0 : (i + 1);
                uchar v = table[b[li] * 9 + b[i] * 3 + b[ri]];
                a[i] = v;
                if (v != 0) { if (i < nl) nl = i; nr = i; }
            }
        } else {
            for (uint i = el; i <= er; i++) {
                uint li = (i == 0) ? 40 : (i - 1);
                uint ri = (i + 1 >= 41) ? 0 : (i + 1);
                uchar v = table[a[li] * 9 + a[i] * 3 + a[ri]];
                b[i] = v;
                if (v != 0) { if (i < nl) nl = i; nr = i; }
            }
        }

        if (nl > nr) { break; }
        if (nr - nl + 1 > max_width) return;
        left_bound = nl;
        right_bound = nr;
    }

    atomic_fetch_add_explicit(bounded_count, 1, memory_order_relaxed);
}


// Width-doubling detection kernel
// Runs longer evolution (200 steps) on larger tape and checks for doubling pattern
kernel void ca_find_doublers(
    device const uint64_t* params [[buffer(0)]],  // [start_rule, count, check_steps, initial_max_width]
    device atomic_uint* doubler_count [[buffer(1)]],
    device uint64_t* doubler_output [[buffer(2)]],
    device atomic_uint* bounded_count [[buffer(3)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t start_rule = params[0];
    uint64_t count = params[1];
    uint check_steps = (uint)params[2];   // e.g. 200
    uint initial_max = (uint)params[3];   // e.g. 5 (initial bounded check)

    if (tid >= count) return;

    uint64_t rule_number = start_rule + (uint64_t)tid * 3;

    // Decode rule table
    uchar table[27];
    uint64_t val = rule_number;
    for (uint j = 0; j < 27; j++) {
        table[j] = (uchar)(val % 3);
        val /= 3;
    }

    // Digit constraints
    if (table[1] == 1 || table[9] == 1) return;
    if (table[1] == 2 && table[2] != 0) return;
    if (table[9] == 2 && table[18] != 0) return;

    // Analytical 3-step pre-filter
    uint d1 = table[1], d3 = table[3], d9 = table[9];
    if (d1 == 0 && d3 == 0 && d9 == 0) {
        // trivially bounded (dies) — not a doubler
        atomic_fetch_add_explicit(bounded_count, 1, memory_order_relaxed);
        return;
    }
    uint s2_0 = table[d1], s2_4 = table[d9 * 9];
    if (s2_0 != 0 && table[s2_0] != 0) return;
    if (s2_4 != 0 && table[s2_4 * 9] != 0) return;

    // Full evolution on TAPE_SIZE tape for check_steps
    uchar a[TAPE_SIZE], b[TAPE_SIZE];
    uint center = TAPE_SIZE / 2;
    for (uint i = 0; i < TAPE_SIZE; i++) { a[i] = 0; b[i] = 0; }
    a[center] = 1;

    uint left_bound = center, right_bound = center;

    // Track widths at each step (for doubling detection)
    uchar widths[MAX_STEPS + 1];
    widths[0] = 1;

    bool bounded_at_initial = true;

    for (uint step = 0; step < check_steps; step++) {
        uint el = (left_bound >= 2) ? (left_bound - 2) : 0;
        uint er = (right_bound + 2 < TAPE_SIZE) ? (right_bound + 2) : (TAPE_SIZE - 1);
        uint nl = TAPE_SIZE, nr = 0;

        if (step & 1) {
            for (uint i = el; i <= er; i++) {
                uint li = (i == 0) ? (TAPE_SIZE - 1) : (i - 1);
                uint ri = (i + 1 >= TAPE_SIZE) ? 0 : (i + 1);
                uchar v = table[b[li] * 9 + b[i] * 3 + b[ri]];
                a[i] = v;
                if (v != 0) { if (i < nl) nl = i; nr = i; }
            }
        } else {
            for (uint i = el; i <= er; i++) {
                uint li = (i == 0) ? (TAPE_SIZE - 1) : (i - 1);
                uint ri = (i + 1 >= TAPE_SIZE) ? 0 : (i + 1);
                uchar v = table[a[li] * 9 + a[i] * 3 + a[ri]];
                b[i] = v;
                if (v != 0) { if (i < nl) nl = i; nr = i; }
            }
        }

        uint w;
        if (nl > nr) {
            w = 0; // pattern died
        } else {
            w = nr - nl + 1;
        }

        if (step < 20 && w > initial_max) {
            bounded_at_initial = false;
        }

        // Clamp width to fit in uchar (max 201)
        widths[step + 1] = (w < 255) ? (uchar)w : 255;

        if (w == 0) break; // died
        if (w >= TAPE_SIZE - 2) return; // hit tape edge — inconclusive, skip

        left_bound = nl;
        right_bound = nr;
    }

    // Count bounded rules
    if (bounded_at_initial) {
        atomic_fetch_add_explicit(bounded_count, 1, memory_order_relaxed);
    }

    // Width-doubling detection:
    // A doubler has width that grows but with a specific periodic pattern.
    // Check: find a period P where width(t+P) ≈ 2*width(t) for multiple t values
    // Also: width must actually grow (not stay fixed or die)

    // Simple approach: check if there exists a period P (2..50) where
    // for at least 3 consecutive periods, width roughly doubles
    uint final_step = check_steps;
    for (uint s = check_steps; s > 0; s--) {
        if (widths[s] > 0) { final_step = s; break; }
    }

    // Must have non-trivial width growth
    if (widths[final_step] <= widths[1]) return;  // no growth
    if (widths[final_step] <= 3) return;           // trivially small

    // Check for periodic doubling: find smallest period P where
    // width(t+P) is approximately 2*width(t)
    bool is_doubler = false;
    for (uint p = 1; p <= 50 && !is_doubler; p++) {
        uint doubles = 0;
        uint checks = 0;
        for (uint t = p; t + p <= final_step; t += p) {
            uint w1 = widths[t];
            uint w2 = widths[t + p];
            if (w1 >= 2 && w2 >= 2) {
                checks++;
                // Check if w2 ≈ 2*w1 (within 20%)
                if (w2 >= w1 * 2 - w1 / 5 && w2 <= w1 * 2 + w1 / 5) {
                    doubles++;
                }
            }
        }
        // Need at least 3 checks with >80% showing doubling
        if (checks >= 3 && doubles * 5 >= checks * 4) {
            is_doubler = true;
        }
    }

    if (is_doubler) {
        uint pos = atomic_fetch_add_explicit(doubler_count, 1, memory_order_relaxed);
        if (pos < 10000000) { // cap output at 10M
            doubler_output[pos] = rule_number;
        }
    }
}
