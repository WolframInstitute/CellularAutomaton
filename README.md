# CellularAutomaton Search

Rust + Metal GPU accelerated search tools for 1D cellular automata. Wolfram Language paclet.

## Install

```wolfram
PacletInstall["https://www.wolframcloud.com/obj/nikm/CellularAutomaton.paclet"]
Needs["WolframInstitute`CellularAutomaton`"]
```

## API

All functions accept `Method → "Native"` to use the built-in `CellularAutomaton` instead of Rust/GPU (default: `Automatic`).

### `CellularAutomatonSearch`

Find rules matching a target pattern or output width.

```wolfram
(* Rules whose output matches a target array *)
CellularAutomatonSearch[{k, r}, init → target, steps]

(* Rules whose output has exact active width *)
CellularAutomatonSearch[{k, r}, init → targetWidth, steps]

(* Multiple inits — ALL must produce targetWidth *)
CellularAutomatonSearch[{k, r}, {init1 → target1, ...}, steps]

(* Candidate list, span, random sampling *)
CellularAutomatonSearch[{{rn1, ...}, k, r}, ...]
CellularAutomatonSearch[{min ;; max, k, r}, ...]
CellularAutomatonSearch[{seed → n, k, r}, ...]

(* Rule range *)
CellularAutomatonSearch[{k, r}, init → target, steps, minRule ;; maxRule]
```

### `CellularAutomatonWidthRatioSearch`

Find rules where output width = ratio × input width for ALL initial conditions.

```wolfram
CellularAutomatonWidthRatioSearch[inits, steps, ratio, {k, r}]

(* Sieve: filter a pre-existing list of candidate rules *)
CellularAutomatonWidthRatioSearch[inits, steps, ratio, {k, r}, candidateRules]
```

**Width-doubling rules (NKS p. 833):**

```wolfram
(* GPU-accelerated: 4341 doublers in ~12s (n=0..5) *)
CellularAutomatonWidthRatioSearch[
    Table[Append[ConstantArray[1, n], 2], {n, 0, 5}], 400, 2, {3, 1}]

(* More tests → 4278 doublers (n=0..20, ~19s) *)
CellularAutomatonWidthRatioSearch[
    Table[Append[ConstantArray[1, n], 2], {n, 0, 20}], 400, 2, {3, 1}]

(* Multi-stage sieve *)
coarse = CellularAutomatonWidthRatioSearch[inits5, 400, 2, {3, 1}]
refined = CellularAutomatonWidthRatioSearch[inits20, 400, 2, {3, 1}, coarse]
```

### `CellularAutomatonTest`

Test whether rules produce a target from an init.

```wolfram
CellularAutomatonTest[{rule, k, r}, init → target, steps]            (* True/False *)
CellularAutomatonTest[{rule1, rule2, ...}, init → target, steps]      (* filter list *)
CellularAutomatonTest[{{r1,k1,s1}, ...}, init → target, steps]       (* filter specs *)
```

### `CellularAutomatonBoundedWidthSearch`

Rules where the active region never exceeds a maximum width.

```wolfram
CellularAutomatonBoundedWidthSearch[init, steps, maxWidth, {k, r}]
```

### `CellularAutomatonOutput` / `CellularAutomatonEvolution`

```wolfram
CellularAutomatonOutput[rule, k, r, init, steps]       (* final state *)
CellularAutomatonEvolution[rule, k, r, init, steps]     (* full spacetime *)
```

### `CellularAutomatonOutputTable` / `CellularAutomatonActiveWidths`

Compute over all rules in the rule space.

```wolfram
CellularAutomatonOutputTable[k, r, init, steps]         (* outputs for all rules *)
CellularAutomatonActiveWidths[k, r, init, steps]        (* {maxWidth, finalWidth} per rule *)
```

### `CellularAutomatonRuleCount`

```wolfram
CellularAutomatonRuleCount[3, 1]  (* 7625597484987 *)
```

## Building

**Requirements:** Wolfram Language 14.3+, Rust toolchain, cross-compilation targets.

```bash
# Build all platforms
./build_all_targets.sh

# Package + deploy paclet
./build.wls
```

## Testing

```bash
wolframscript -f Tests/run_tests.wl   # runs all tests (79 total)
```

Test files:

| File | Description |
|---|---|
| `Tests/core_tests.wl` | Core API: all public functions, edge cases, BigInt k=4 |
| `Tests/cross_validation_tests.wl` | Rust vs builtin `CellularAutomaton`, Rust vs `Method → "Native"` |
| `Tests/nks_doubler_tests.wl` | NKS GPU doubler search: 4278 count, monotonicity, sieve |

## Project Structure

```
CASearch/
├── CellularAutomaton/              # Wolfram paclet
│   ├── PacletInfo.wl
│   ├── Kernel/Functions.wl         # WL API
│   ├── Libs/ca_search/
│   │   ├── src/lib.rs              # Core functions + WLL exports
│   │   ├── src/gpu.rs              # Metal GPU dispatch
│   │   ├── src/models.rs           # CAState, CellularAutomaton structs
│   │   └── shaders/ca_search.metal # Metal compute shaders
│   └── Binaries/                   # Built native libraries
├── build_all_targets.sh            # Cross-platform Rust builds
├── build.wls                       # Paclet packaging + deploy
├── Tests/
│   ├── run_tests.wl                # Test runner
│   ├── test_helpers.wl             # Shared test infrastructure
│   ├── core_tests.wl               # Core API tests
│   ├── cross_validation_tests.wl   # Rust vs Native correctness
│   └── nks_doubler_tests.wl        # GPU doubler search tests
└── README.md
```

## GPU Architecture

On macOS with Apple Silicon, the k=3 r=1 doubler search runs entirely on Metal GPU:

- **7 fixed digits** (analytically derived) reduce 3²⁷ → 3²⁰ search space
- **12 NKS tests** run per thread with early exit (99.9% exit at test 1)
- **Sequential-scan update** (NKS `doubleasymmi.c` algorithm, NOT standard parallel CA)
- **~12s** for 3.5B candidates on M3 Max

Standard CA searches (`CellularAutomatonSearch`, width/bounded) also use Metal GPU for k≤4, r=1.

## Benchmarks

Apple M3 Max, 16 cores. Rust uses Rayon thread-pool parallelism + bitpacked k=2 engine + NumericArray zero-copy. `Method → "Native"` uses the built-in sequential `CellularAutomaton`.

### k=2, r=1 — 256 Rules

| Function | Width | Steps | Rust | Native | Speedup |
|---|---|---|---|---|---|
| `CellularAutomatonSearch` | 51 | 10 | 167μs | 819μs | **4.9×** |
| `CellularAutomatonTest` (256 rules) | 201 | 100 | 209μs | 5.0ms | **24×** |
| `CellularAutomatonActiveWidths` | 51 | 50 | 271μs | 294μs | **1.1×** |
| `CellularAutomatonBoundedWidthSearch` | 51 | 50 | 139μs | 164μs | **1.2×** |

### k=3, r=1 — Large Rule Space

Rayon parallel Rust vs sequential WL — the advantage scales with rule count.

| Function | Rules | Width | Steps | Rust | Native | Speedup |
|---|---|---|---|---|---|---|
| `CellularAutomatonSearch` | 10K | 23 | 10 | 1.1ms | 249ms | **232×** |
| `CellularAutomatonTest` | 10K | 23 | 10 | 1.5ms | 230ms | **158×** |
| `CellularAutomatonSearch` | 1K | 23 | 10 | 232μs | 22.5ms | **97×** |
| `CellularAutomatonTest` | 1K | 23 | 10 | 290μs | 23.2ms | **80×** |

### NKS Doublers (k=3, r=1 — GPU, 3²⁰ search space)

No native equivalent — uses GPU sequential-scan update (NKS `doubleasymmi.c`).

| Tests (n) | Time | Doublers Found |
|---|---|---|
| 0–5 | 12s | 4341 |
| 0–10 | 12s | 4280 |
| 0–20 | 18s | 4278 |
