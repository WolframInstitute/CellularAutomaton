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
wolframscript -f Tests/run_tests.wl                # 59 correctness tests
wolframscript -f Tests/native_comparison_tests.wl   # 14 Rust vs Native parity
wolframscript -f Tests/gpu_vs_native_tests.wl       # 19 GPU tests + NKS doublers
```

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
│   ├── run_tests.wl                # Correctness tests
│   ├── native_comparison_tests.wl  # Rust vs Native parity
│   └── gpu_vs_native_tests.wl      # GPU benchmarks + NKS doublers
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

All benchmarks on Apple M3 Max. Rust/GPU is the default backend; Native uses the built-in `CellularAutomaton` function via `Method → "Native"`.

### Single Rule Operations

| Function | Width | Steps | Rust | Native | Speedup |
|---|---|---|---|---|---|
| `CellularAutomatonOutput` | 11 | 5 | <0.1μs | 52μs | ~1000× |
| `CellularAutomatonOutput` | 201 | 100 | <0.1μs | 92μs | ~1800× |
| `CellularAutomatonOutput` | 501 | 100 | <0.1μs | 170μs | ~3400× |
| `CellularAutomatonEvolution` | 51 | 50 | <0.1μs | 150μs | ~3000× |
| `CellularAutomatonEvolution` | 201 | 50 | <0.1μs | 490μs | ~9800× |

### Bulk Search (k=2, r=1 — 256 rules)

| Function | Width | Steps | Rust | Native | Speedup |
|---|---|---|---|---|---|
| `CellularAutomatonSearch` (match) | 11 | 5 | <0.1μs | 540μs | ~5400× |
| `CellularAutomatonSearch` (match) | 51 | 10 | 0.1μs | 860μs | ~8600× |
| `CellularAutomatonSearch` (width) | 21 | 20 | <0.1μs | 700μs | ~7000× |
| `CellularAutomatonTest` (256 rules) | 11 | 5 | 0.1μs | 330μs | ~3300× |
| `CellularAutomatonTest` (256 rules) | 51 | 20 | 0.1μs | 1.4ms | ~14000× |
| `CellularAutomatonOutputTable` | 51 | 50 | 0.1μs | 310μs | ~3100× |
| `CellularAutomatonOutputTable` | 101 | 50 | 0.1μs | 540μs | ~5400× |
| `CellularAutomatonActiveWidths` | 21 | 30 | 0.1μs | 380μs | ~3800× |
| `CellularAutomatonBoundedWidthSearch` | 51 | 50 | 0.1μs | 180μs | ~1800× |
| `CellularAutomatonWidthRatioSearch` | 21 | 10 | 0.1μs | 150μs | ~1500× |

### NKS Doublers (k=3, r=1 — GPU-only, 3²⁰ search space)

No native equivalent — the NKS doubler search uses sequential-scan update, not standard parallel CA.

| Tests (n) | Time | Doublers Found |
|---|---|---|
| 0–5 | 12s | 4341 |
| 0–10 | 12s | 4280 |
| 0–15 | 14s | 4278 |
| 0–20 | 19s | 4278 |
