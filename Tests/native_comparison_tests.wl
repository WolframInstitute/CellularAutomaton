#!/usr/bin/env wolframscript

(* Native vs Rust Comparison Tests *)
(* Run with: wolframscript -f Tests/native_comparison_tests.wl *)

print[a___] := WriteString["stdout", a, "\n"];

print["=== Native vs Rust Comparison Tests ==="];
print[""];

(* Load paclet *)
print["Loading paclet..."];
PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName, 2], "CellularAutomaton"}]];
Needs["WolframInstitute`CellularAutomaton`"];
print["Paclet loaded."];
print[""];

$testCount = 0;
$passCount = 0;
$failCount = 0;
$failures = {};

SetAttributes[runTest, HoldAll];
runTest[name_String, expr_, expected_] := (
    $testCount++;
    With[{result = expr},
        If[ result === expected,
            $passCount++;
            print["  \[Checkmark] ", name];
            ,
            $failCount++;
            AppendTo[$failures, name];
            print["  \[Times] ", name];
            print["    Expected: ", Short[expected, 2]];
            print["    Got:      ", Short[result, 2]];
        ]
    ]
)

(* Compare Rust vs Native results and print timings *)
SetAttributes[timeCompare, HoldRest];
timeCompare[name_String, rustExpr_, nativeExpr_] := Module[{rustResult, nativeResult, tRust, tNative},
    {tRust, rustResult} = AbsoluteTiming[rustExpr];
    {tNative, nativeResult} = AbsoluteTiming[nativeExpr];
    $testCount++;
    If[rustResult === nativeResult,
        $passCount++;
        print["  \[Checkmark] ", name];
        ,
        $failCount++;
        AppendTo[$failures, name];
        print["  \[Times] ", name];
        print["    Rust:   ", Short[rustResult, 2]];
        print["    Native: ", Short[nativeResult, 2]];
    ];
    print["    Rust: ", NumberForm[tRust, 4], "s  |  Native: ", NumberForm[tNative, 4], "s  |  ",
        If[tRust > 0, "Speedup: " <> ToString[NumberForm[tNative / tRust, 3]] <> "x", ""]];
]

(* ---- Tests ---- *)

print["--- CellularAutomatonOutput ---"];

timeCompare["Rule 30, width 7, 1 step",
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 1],
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 1, Method -> "Native"]];
timeCompare["Rule 30, width 7, 10 steps",
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 10],
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 10, Method -> "Native"]];
timeCompare["Rule 110, width 21, 20 steps",
    CellularAutomatonOutput[110, 2, 1, CenterArray[{1}, 21], 20],
    CellularAutomatonOutput[110, 2, 1, CenterArray[{1}, 21], 20, Method -> "Native"]];
timeCompare["k=3 rule, width 23, 5 steps",
    CellularAutomatonOutput[123456, 3, 1, Join[ConstantArray[0,10], {1,2,0}, ConstantArray[0,10]], 5],
    CellularAutomatonOutput[123456, 3, 1, Join[ConstantArray[0,10], {1,2,0}, ConstantArray[0,10]], 5, Method -> "Native"]];

print[""];
print["--- CellularAutomatonEvolution ---"];

timeCompare["Rule 30, width 7, 2 steps",
    CellularAutomatonEvolution[30, 2, 1, {0,0,0,1,0,0,0}, 2],
    CellularAutomatonEvolution[30, 2, 1, {0,0,0,1,0,0,0}, 2, Method -> "Native"]];
timeCompare["Rule 110, width 21, 20 steps",
    CellularAutomatonEvolution[110, 2, 1, CenterArray[{1}, 21], 20],
    CellularAutomatonEvolution[110, 2, 1, CenterArray[{1}, 21], 20, Method -> "Native"]];

print[""];
print["--- CellularAutomatonSearch ---"];

With[{init = {0,0,0,1,0,0,0},
      target = Last @ CellularAutomaton[30, {0,0,0,1,0,0,0}, 1]},
    timeCompare["Find rules matching rule 30 output",
        CellularAutomatonSearch[{2, 1}, init -> target, 1],
        CellularAutomatonSearch[{2, 1}, init -> target, 1, Method -> "Native"]];
];

timeCompare["Width target search (width=3, 2 steps)",
    CellularAutomatonSearch[{2, 1}, CenterArray[{1}, 11] -> 3, 2],
    CellularAutomatonSearch[{2, 1}, CenterArray[{1}, 11] -> 3, 2, Method -> "Native"]];

print[""];
print["--- CellularAutomatonOutputTable ---"];

timeCompare["Elementary output table, width 7, 1 step",
    CellularAutomatonOutputTable[{0,0,0,1,0,0,0}, 1],
    CellularAutomatonOutputTable[{0,0,0,1,0,0,0}, 1, Method -> "Native"]];

print[""];
print["--- CellularAutomatonBoundedWidthSearch ---"];

timeCompare["Bounded width 5, 20 steps",
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5],
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5, Method -> "Native"]];

print[""];
print["--- CellularAutomatonActiveWidths ---"];

timeCompare["Active widths, all elementary rules, 10 steps",
    CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10],
    CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10, Method -> "Native"]];

print[""];
print["--- CellularAutomatonWidthRatioSearch ---"];

timeCompare["Width ratio=2 search, small range",
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3, 1}, 54240 ;; 54240, 15],
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3, 1}, 54240 ;; 54240, 15, Method -> "Native"]];

(* Sieve test *)
With[{candidates = CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 10, 2, {3, 1}, 54230 ;; 54250, 15]},
    If[Length[candidates] > 0,
        timeCompare["Sieve: filter candidates through 2nd init",
            CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1, 1}, 41]}, 10, 2, {3, 1}, candidates],
            CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1, 1}, 41]}, 10, 2, {3, 1}, candidates, Method -> "Native"]];
    ];
];

print[""];
print["--- CellularAutomatonTest ---"];

With[{
    init = {0,0,0,1,0,0,0},
    target = Last @ CellularAutomaton[30, {0,0,0,1,0,0,0}, 1]
},
    timeCompare["Batch test 256 rules",
        CellularAutomatonTest[Range[0, 255], init -> target, 1],
        CellularAutomatonTest[Range[0, 255], init -> target, 1, {2, 1}, Method -> "Native"]];
];


(* ---- Summary ---- *)
print[""];
print["=== Results ==="];
print["Total:  ", $testCount];
print["Passed: ", $passCount];
print["Failed: ", $failCount];

If[$failCount > 0,
    print[""];
    print["Failed tests:"];
    Scan[print["  - ", #] &, $failures];
    print[""];
    print["SOME TESTS FAILED"];
    Exit[1];
    ,
    print[""];
    print["ALL TESTS PASSED"];
    Exit[0];
];
