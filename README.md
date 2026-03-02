# CellularAutomaton Search

Rust + Metal GPU accelerated search tools for 1D cellular automata. Wolfram Language paclet.

## Install

```wolfram
PacletInstall["https://www.wolframcloud.com/obj/nikm/CellularAutomaton.paclet"]
Needs["WolframInstitute`CellularAutomaton`"]
```

## API

### `CellularAutomatonSearch`

Find rules matching a target pattern or output width.

```wolfram
(* Rules whose output matches a target array *)
CellularAutomatonSearch[init, steps, targetArray, {k, r}]

(* Rules whose output has exact active width *)
CellularAutomatonSearch[init, steps, targetWidth, {k, r}]

(* Multiple inits — ALL must produce targetWidth *)
CellularAutomatonSearch[{init1, init2, ...}, steps, targetWidth, {k, r}]

(* Rule range *)
CellularAutomatonSearch[init, steps, target, {k, r}, minRule ;; maxRule]
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
(* GPU-accelerated: 4288 doublers in ~12s *)
inits = Table[Join[ConstantArray[1, n], {2}], {n, 0, 6}];
CellularAutomatonWidthRatioSearch[inits, 200, 2, {3, 1}]

(* NKS-faithful 30 tests → exact 4277 count *)
inits30 = Table[Join[ConstantArray[1, n], {2}], {n, 0, 29}];
CellularAutomatonWidthRatioSearch[inits30, 200, 2, {3, 1}]

(* Multi-stage sieve *)
coarse = CellularAutomatonWidthRatioSearch[inits7, 200, 2, {3, 1}]
refined = CellularAutomatonWidthRatioSearch[inits30, 200, 2, {3, 1}, coarse]
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

### `CellularAutomatonActiveWidths`

`{maxWidth, finalWidth}` for each rule.

```wolfram
CellularAutomatonActiveWidths[k, r, init, steps]
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
└── README.md
```

## GPU Architecture

On macOS with Apple Silicon, the k=3 r=1 doubler search runs entirely on Metal GPU:

- **7 fixed digits** (analytically derived) reduce 3^27 → 3^20 search space
- **12 NKS tests** run per thread with early exit (99.9% exit at test 1)
- **Sequential-scan update** (NKS `doubleasymmi.c` algorithm, NOT standard parallel CA)
- **~12s** for 3.5B candidates on M3 Max

Standard CA searches (`CellularAutomatonSearch`, width/bounded) also use Metal GPU for k≤4, r=1.
