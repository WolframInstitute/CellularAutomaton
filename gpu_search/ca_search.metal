#include <metal_stdlib>
using namespace metal;

// Width-doubling detection: tests the universal doubling pattern
// {1,...,1,2} (n ones + 2) → {1,...,1} (2n ones)
// 7 tests: n=0..6 → widths 1→2, 2→4, 3→6, 4→8, 5→10, 6→12, 7→14
// ALL outputs must be solid blocks of 1s.

#define TAPE 81
#define STEPS 200

// Evolve CA and check if final state is exactly a solid block of 1s with given width
bool check_doubling(thread const uchar* table, uint init_width, thread const uchar* init_pattern) {
    uchar a[TAPE], b[TAPE];
    uint center = TAPE / 2;
    for (uint i = 0; i < TAPE; i++) { a[i] = 0; b[i] = 0; }
    
    // Place initial pattern centered-left
    uint start = center - init_width / 2;
    for (uint i = 0; i < init_width; i++) {
        a[start + i] = init_pattern[i];
    }
    
    uint left_bound = start;
    uint right_bound = start + init_width - 1;
    uint expected_width = init_width * 2;
    
    for (uint step = 0; step < STEPS; step++) {
        uint el = (left_bound >= 2) ? (left_bound - 2) : 0;
        uint er = (right_bound + 2 < TAPE) ? (right_bound + 2) : (TAPE - 1);
        uint nl = TAPE, nr = 0;
        
        if (step & 1) {
            for (uint i = el; i <= er; i++) {
                uint li = (i == 0) ? (TAPE - 1) : (i - 1);
                uint ri = (i + 1 >= TAPE) ? 0 : (i + 1);
                uchar v = table[b[li] * 9 + b[i] * 3 + b[ri]];
                a[i] = v;
                if (v != 0) { if (i < nl) nl = i; nr = i; }
            }
        } else {
            for (uint i = el; i <= er; i++) {
                uint li = (i == 0) ? (TAPE - 1) : (i - 1);
                uint ri = (i + 1 >= TAPE) ? 0 : (i + 1);
                uchar v = table[a[li] * 9 + a[i] * 3 + a[ri]];
                b[i] = v;
                if (v != 0) { if (i < nl) nl = i; nr = i; }
            }
        }
        
        if (nl > nr) return false; // died
        uint w = nr - nl + 1;
        if (w > expected_width + 2) return false; // grows too much
        if (w >= TAPE - 4) return false; // hit tape edge
        left_bound = nl;
        right_bound = nr;
    }
    
    // Check final state: must be exactly expected_width cells, all 1s
    // Read from the last-written buffer
    thread const uchar* final_buf = (STEPS & 1) ? a : b;
    
    // Find nonzero cells
    uint nl = TAPE, nr = 0;
    for (uint i = 0; i < TAPE; i++) {
        if (final_buf[i] != 0) {
            if (i < nl) nl = i;
            nr = i;
        }
    }
    if (nl > nr) return false;
    uint final_width = nr - nl + 1;
    if (final_width != expected_width) return false;
    
    // All nonzero cells must be exactly 1
    for (uint i = nl; i <= nr; i++) {
        if (final_buf[i] != 1) return false;
    }
    
    return true;
}

kernel void ca_find_doublers(
    device const uint64_t* params [[buffer(0)]],
    device atomic_uint* doubler_count [[buffer(1)]],
    device uint64_t* doubler_output [[buffer(2)]],
    uint tid [[thread_position_in_grid]]
) {
    uint64_t start_idx = params[0];
    uint64_t count = params[1];
    
    if (tid >= count) return;
    
    uint64_t free_idx = start_idx + (uint64_t)tid;
    
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
    
    // Tests: {1^n, 2} → {1^(2(n+1))} for n = 0..6
    // i.e., widths 1→2, 2→4, 3→6, 4→8, 5→10, 6→12, 7→14
    for (uint n = 0; n <= 6; n++) {
        uint w = n + 1;
        uchar init[7];
        for (uint i = 0; i < n; i++) init[i] = 1;
        init[n] = 2;
        if (!check_doubling(table, w, init)) return;
    }
    
    // All 7 tests passed — this is a doubler!
    uint64_t rule_number = 0;
    uint64_t pow3 = 1;
    for (uint d = 0; d < 27; d++) {
        rule_number += (uint64_t)table[d] * pow3;
        pow3 *= 3;
    }
    
    uint pos = atomic_fetch_add_explicit(doubler_count, 1, memory_order_relaxed);
    if (pos < 100000) {
        doubler_output[pos] = rule_number;
    }
}
