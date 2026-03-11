(* Cross-validation tests *)
(* Verifies Rust results match WL's builtin CellularAutomaton *)
(* and that Rust path produces identical results to Method -> "Native" path *)

print["--- Rust vs builtin CellularAutomaton ---"];

With[{init = {0,0,0,0,0,1,0,0,0,0,0}},
    Scan[Function[rule,
        test["CrossVal: rule " <> ToString[rule],
            CellularAutomatonOutput[rule, init, 5],
            Last @ CellularAutomaton[rule, init, 5]];
    ], {30, 90, 110, 150, 184, 210}];
];

test["CrossVal: k=3 rule 123456",
    CellularAutomatonOutput[123456, 3, 1, Join[ConstantArray[0,10],{1,2,0},ConstantArray[0,10]], 3],
    Last @ CellularAutomaton[{123456, 3, 1}, Join[ConstantArray[0,10],{1,2,0},ConstantArray[0,10]], 3]];

print[""];
print["--- Rust vs Native: CellularAutomatonOutput ---"];

test["RustVsNative: Output rule 30 w=7 s=10",
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 10],
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 10, Method -> "Native"]];
test["RustVsNative: Output k=3",
    CellularAutomatonOutput[123456, 3, 1, Join[ConstantArray[0,10],{1,2,0},ConstantArray[0,10]], 5],
    CellularAutomatonOutput[123456, 3, 1, Join[ConstantArray[0,10],{1,2,0},ConstantArray[0,10]], 5, Method -> "Native"]];

print[""];
print["--- Rust vs Native: CellularAutomatonEvolution ---"];

test["RustVsNative: Evolution rule 110 w=21 s=20",
    CellularAutomatonEvolution[110, 2, 1, CenterArray[{1}, 21], 20],
    CellularAutomatonEvolution[110, 2, 1, CenterArray[{1}, 21], 20, Method -> "Native"]];

print[""];
print["--- Rust vs Native: CellularAutomatonSearch ---"];

With[{init = CenterArray[{1}, 11], target = Last @ CellularAutomaton[30, CenterArray[{1}, 11], 3]},
    test["RustVsNative: Search k=2",
        CellularAutomatonSearch[{2,1}, init -> target, 3],
        CellularAutomatonSearch[{2,1}, init -> target, 3, Method -> "Native"]];
];
test["RustVsNative: ExactWidth k=2",
    CellularAutomatonSearch[{2,1}, CenterArray[{1}, 11] -> 3, 2],
    CellularAutomatonSearch[{2,1}, CenterArray[{1}, 11] -> 3, 2, Method -> "Native"]];

print[""];
print["--- Rust vs Native: bulk operations ---"];

test["RustVsNative: OutputTable k=2",
    CellularAutomatonOutputTable[{0,0,0,1,0,0,0}, 1],
    CellularAutomatonOutputTable[{0,0,0,1,0,0,0}, 1, Method -> "Native"]];
test["RustVsNative: BoundedWidth k=2",
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5],
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5, Method -> "Native"]];
test["RustVsNative: ActiveWidths k=2",
    CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10],
    CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10, Method -> "Native"]];

With[{init = {0,0,0,1,0,0,0}, target = Last @ CellularAutomaton[30, {0,0,0,1,0,0,0}, 1]},
    test["RustVsNative: Test batch k=2",
        CellularAutomatonTest[Range[0,255], init -> target, 1],
        CellularAutomatonTest[Range[0,255], init -> target, 1, {2,1}, Method -> "Native"]];
];

test["RustVsNative: WidthRatio k=3",
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3,1}, 54200 ;; 54300, 15],
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3,1}, 54200 ;; 54300, 15, Method -> "Native"]];

With[{candidates = CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 10, 2, {3,1}, 54230 ;; 54250, 15]},
    If[Length[candidates] > 0,
        test["RustVsNative: Sieve filter",
            CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1,1}, 41]}, 10, 2, {3,1}, candidates],
            CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1,1}, 41]}, 10, 2, {3,1}, candidates, Method -> "Native"]];
    ];
];
