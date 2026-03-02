# CellularAutomaton Search

Rust-accelerated search tools for 1D cellular automata, packaged as a Wolfram Language paclet.

## Quick Start

```wolfram
PacletDirectoryLoad["CellularAutomaton"]
Needs["WolframInstitute`CellularAutomaton`"]
```

## Building

### Requirements

- Wolfram Language 14.3+
- Rust toolchain (`rustup`)
- Cross-compilation targets (for multi-platform builds)

### Development Build (local only)

Build from Wolfram Language — this compiles the Rust code and copies the resulting
library into `CellularAutomaton/Binaries/`:

```wolfram
<< ExtensionCargo`
PacletDirectoryLoad["CellularAutomaton"]
CargoBuild[PacletObject["WolframInstitute/CellularAutomaton"]]
```

> **Important**: After rebuilding, restart the kernel before loading the paclet.
> The Rust function table is cached on first load.
>
> Never run `cargo build` directly inside the paclet folder — it creates a
> `target/` directory that pollutes the paclet structure.

### Cross-Platform Build

```bash
./build_all_targets.sh
```

Builds for: `MacOSX-x86-64`, `MacOSX-ARM64`, `Linux-x86-64`, `Linux-ARM64`, `Windows-x86-64`.

### Full Paclet Package

```bash
wolframscript -f build.wl
```

This runs `CargoBuild`, collects binaries into `CellularAutomaton/Binaries/`, and creates a `.paclet` archive.

## API Reference

### `CellularAutomatonSearch`

Find CA rules matching a target pattern or output width.

```wolfram
(* Find rules whose output matches a target array *)
CellularAutomatonSearch[init, steps, targetArray]
CellularAutomatonSearch[init, steps, targetArray, {k, r}]
CellularAutomatonSearch[init, steps, targetArray, {k, r}, minRule ;; maxRule]

(* Find rules whose output has exact active width *)
CellularAutomatonSearch[init, steps, targetWidth]
CellularAutomatonSearch[init, steps, targetWidth, {k, r}]
CellularAutomatonSearch[init, steps, targetWidth, {k, r}, minRule ;; maxRule]

(* Multiple inits — ALL must produce targetWidth *)
CellularAutomatonSearch[{init1, init2, ...}, steps, targetWidth, {k, r}]
```

**Examples:**

```wolfram
(* All elementary rules producing width 5 from single cell after 10 steps *)
CellularAutomatonSearch[CenterArray[{1}, 21], 10, 5]

(* k=3, r=1 rules producing exact target from {1,2} input *)
init = CenterArray[{1, 2}, 31];
CellularAutomatonSearch[init, 30, {0,0,0,...,1,1,1,1,...,0,0,0}, {3, 1}]

(* Search a rule range *)
CellularAutomatonSearch[init, 30, 4, {3, 1}, 1920106430 ;; 1920106432]
```

### `CellularAutomatonBoundedWidthSearch`

Find rules where the active region never exceeds a maximum width.

```wolfram
CellularAutomatonBoundedWidthSearch[init, steps, maxWidth]
CellularAutomatonBoundedWidthSearch[init, steps, maxWidth, {k, r}]
CellularAutomatonBoundedWidthSearch[init, steps, maxWidth, {k, r}, minRule ;; maxRule]
```

### `CellularAutomatonWidthRatioSearch`

Find rules where the output width is a fixed ratio of the input width, across multiple initial conditions.

```wolfram
CellularAutomatonWidthRatioSearch[{init1, init2, ...}, steps, ratio, {k, r}]
CellularAutomatonWidthRatioSearch[{init1, init2, ...}, steps, ratio, {k, r}, minRule ;; maxRule]
```

**Example — find width-doubling rules (NKS p. 833):**

```wolfram
inits = Table[CenterArray[Append[ConstantArray[1, n], 2], 31], {n, 0, 6}];
CellularAutomatonWidthRatioSearch[inits, 50, 2, {3, 1}]
```

### `CellularAutomatonOutput`

Run a CA and return the final state.

```wolfram
CellularAutomatonOutput[rule, init, steps]
CellularAutomatonOutput[rule, k, r, init, steps]
```

### `CellularAutomatonEvolution`

Return the full spacetime evolution as a matrix.

```wolfram
CellularAutomatonEvolution[rule, init, steps]
CellularAutomatonEvolution[rule, k, r, init, steps]
```

### `CellularAutomatonActiveWidths`

Compute `{maxWidth, finalWidth}` for each rule in a range.

```wolfram
CellularAutomatonActiveWidths[k, r, init, steps]
CellularAutomatonActiveWidths[k, r, init, steps, minRule ;; maxRule]
```

### `CellularAutomatonRuleCount`

Total number of rules for a given `{k, r}`.

```wolfram
CellularAutomatonRuleCount[3, 1]  (* 7625597484987 *)
```

## Project Structure

```
CASearch/
├── CellularAutomaton/          # Wolfram paclet
│   ├── PacletInfo.wl           # Paclet metadata
│   ├── Kernel/Functions.wl     # WL API definitions
│   ├── Libs/ca_search/         # Rust source
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs          # Core functions + WLL exports
│   │       └── models.rs       # CAState, CellularAutomaton structs
│   └── Binaries/               # Built dylibs + manifest (auto-generated)
├── gpu_search/                 # Metal GPU accelerated search
│   ├── ca_search.metal         # Metal compute shader
│   └── src/main.rs             # GPU search driver
├── build.wl                    # Full paclet build + deploy
├── build_all_targets.sh        # Cross-platform Rust builds
└── README.md
```

## GPU Search (Width-Doubling Rules)

A separate Metal GPU search for NKS width-doubling rules (`gpu_search/`):

```bash
cd gpu_search && cargo build --release
../target/release/gpu_benchmark
```

Searches 3^19 ≈ 1.16B constrained rule candidates in ~12s on Apple M3 Max. Results in `doublers_found.txt`.
