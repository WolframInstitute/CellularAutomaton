# DoublerB0.lean — Walkthrough

## What Was Proved

`CA/DoublerB0.lean` proves that rule 6424447839471 acts as a **width-doubler** on periodic B-patterns. Specifically, 6 `step_wave` theorems show that applying `step` to each intermediate wave state produces the next:

```
S_wave_0 → S_wave_1 → S_wave_2 → S_wave_3 → S_wave_4 → S_wave_5 → S_wave_6
```

Each wave state is a tape with:
- **Left zone** (`i < p`): all 0s
- **1-zone** (`p ≤ i < p + m + shift`): all 1s (boundary layer)
- **B-zone** (`p + m + shift ≤ i < p + m + 8k + R_shift`): periodic pattern B0/B1/B2 with period 8
- **Right zone** (`i ≥ p + m + 8k + R_shift`): all 0s

The B-patterns cycle: B0 → B1 → B2 → B0, with the left boundary shifting left and the right boundary shifting right — achieving the doubling.

## Generator

[gen_doubler_b0.py](file:///Users/swish/src/wolfram/CASearch/Proofs/gen_doubler_b0.py) generates `DoublerB0.lean` (1740 lines).

## Key Proof Techniques

### Left-End (0/1 zone)
4-way case split on `i` relative to `p`: `i < p-1 / i = p-1 / i = p / i > p`. Each branch proves `if x < p` conditions explicitly, then `decide` closes `R(0*9+0*3+0)=0` etc.

### Center Bulk (B-zone)
Proves all neighbors are in B-zone via `have` lemmas, rewrites offsets to `i - (p+m+off)`, then applies `step_B0_to_B1` / `step_B1_to_B2` / `step_B2_to_B0`.

### Right-End (B/0 boundary)
For each boundary point, Python computes concrete B-values, R-input, and R-output. Emits `have` lemmas for negative mod (`(-2) % 8 = 6`), then `simp only [B0, mod_8k, ...]` + `dsimp [R]; try rfl`.

### Right Tail (all 0s)
Proves all neighbors are outside B-zone, `simp` resolves to `R(0)=0`.

## Build Verification

```
$ lake build CA.DoublerB0
✔ [3/3] Built CA.DoublerB0
Build completed successfully.
```
