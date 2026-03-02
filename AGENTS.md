# Agent Instructions — MANDATORY READING

## Critical Rules

1. **Never run `cargo build` or `CargoBuild` inside the paclet directory.** Use `./build_all_targets.sh` for compilation and `./build.wls` for paclet packaging. Running cargo inside the paclet creates a `target/` directory that pollutes the paclet archive.

2. **Use `wolframscript -c` flag for inline code, `-f` for files.** Not `-e`.

3. **Use `PacletDirectoryLoad` for loading paclet folders** with a PacletInfo file. Do not use `Get` or `Needs` without loading the paclet directory first.

## Build Workflow

```bash
# 1. Compile Rust for all platforms
./build_all_targets.sh

# 2. Package and deploy paclet
./build.wls
```

Do NOT use `CargoBuild[PacletObject[...]]` from WolframScript — this creates `target/` inside the paclet folder, bloating the paclet archive from ~4MB to ~60MB.

## Architecture

### Paclet Structure

- `CellularAutomaton/Kernel/Functions.wl` — WL API definitions, WLL bindings via `ExtensionCargo`CargoLoad`
- `CellularAutomaton/Libs/ca_search/src/lib.rs` — Core Rust functions, `#[wll::export]` WLL wrappers
- `CellularAutomaton/Libs/ca_search/src/gpu.rs` — Metal GPU engine, pipeline management, kernel dispatch
- `CellularAutomaton/Libs/ca_search/src/models.rs` — `CAState`, `CellularAutomaton` data structures
- `CellularAutomaton/Libs/ca_search/shaders/ca_search.metal` — Metal compute shaders (included via `include_str!`)

### GPU Pipeline (k=3 r=1 Doublers)

The NKS width-doubler search uses a **sequential-scan update** (in-place, left-to-right — NOT standard parallel CA). This is the algorithm from NKS `doubleasymmi.c`.

- `ca_find_doublers` kernel: broad search over 3^20 free-digit space, tests 1-12
- `ca_refine_doublers` kernel: refine candidates with additional tests (larger tape)
- 7 fixed digits derived analytically: `table[0]=0, table[1]=0, table[2]=0, table[4]=1, table[9]=0, table[12]=1, table[13]=1`
- Convergence-based check: run until no cell changes, then verify pattern

### Adding New WLL Functions

1. Add function in `lib.rs`
2. Add `#[wll::export]` wrapper with appropriate types (`Vec<i32>` for WL Integer lists, `Vec<i64>` for large integers)
3. Add binding in `Functions.wl`: `MyFuncRust := functions["my_func_wl"]`
4. Add WL-facing overload using `fromDS @ MyFuncRust[...]`
5. Rebuild with `./build_all_targets.sh`, then `./build.wls`

### GPU Considerations

- GPU code guarded by `#[cfg(all(target_os = "macos", feature = "gpu"))]`
- Metal shaders included at compile time via `include_str!("../shaders/ca_search.metal")`
- Thread-local arrays in Metal limit tape size per kernel (currently 1201 bytes for doublers)
- Use `#[allow(unused_variables)]` for variables only used inside cfg-gated GPU blocks
