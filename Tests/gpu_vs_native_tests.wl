#!/usr/bin/env wolframscript

(* GPU vs Native Comparison Tests *)
(* Tests specifically the Metal GPU-accelerated code paths against pure WL *)
(* Run with: wolframscript -f Tests/gpu_vs_native_tests.wl *)

print[a___] := WriteString["stdout", a, "\n"];

print["=== GPU vs Native Comparison Tests ==="];
print[""];

print["Loading paclet..."];
PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName, 2], "CellularAutomaton"}]];
Needs["WolframInstitute`CellularAutomaton`"];
print["Paclet loaded."];
print[""];

$testCount = 0;
$passCount = 0;
$failCount = 0;
$failures = {};

(* Compare GPU/Rust vs Native results and print timings *)
SetAttributes[timeCompare, HoldRest];
timeCompare[name_String, gpuExpr_, nativeExpr_] := Module[{gpuResult, nativeResult, tGpu, tNative, speedup},
    {tGpu, gpuResult} = AbsoluteTiming[gpuExpr];
    {tNative, nativeResult} = AbsoluteTiming[nativeExpr];
    $testCount++;
    If[gpuResult === nativeResult,
        $passCount++;
        speedup = If[tGpu > 0, tNative / tGpu, Infinity];
        print["  \[Checkmark] ", name, "  (", Length[gpuResult], " results)"];
        print["    GPU: ", NumberForm[1000 tGpu, 4], "ms  |  Native: ", NumberForm[1000 tNative, 4], "ms  |  Speedup: ",
            NumberForm[speedup, {4, 1}], "x"];
        ,
        $failCount++;
        AppendTo[$failures, name];
        print["  \[Times] ", name];
        print["    GPU results:    ", Length[gpuResult], " items, first 5: ", Take[gpuResult, UpTo[5]]];
        print["    Native results: ", Length[nativeResult], " items, first 5: ", Take[nativeResult, UpTo[5]]];
        With[{extra = Complement[gpuResult, nativeResult],
              missing = Complement[nativeResult, gpuResult]},
            If[Length[extra] > 0, print["    Extra in GPU: ", Take[extra, UpTo[5]]]];
            If[Length[missing] > 0, print["    Missing from GPU: ", Take[missing, UpTo[5]]]];
        ];
    ];
]

(* ---- GPU Function Tests ---- *)

print["=== 1. CellularAutomatonSearch: find matching rules (GPU: ca_find_matching) ==="];
print["   Full elementary search space (256 rules)"];

With[{init = CenterArray[{1}, 11], target = Last @ CellularAutomaton[30, CenterArray[{1}, 11], 3]},
    timeCompare["k=2 r=1 matching, 3 steps",
        CellularAutomatonSearch[{2, 1}, init -> target, 3],
        CellularAutomatonSearch[{2, 1}, init -> target, 3, Method -> "Native"]];
];

With[{init = CenterArray[{1}, 21], target = Last @ CellularAutomaton[110, CenterArray[{1}, 21], 5]},
    timeCompare["k=2 r=1 matching, 5 steps wider tape",
        CellularAutomatonSearch[{2, 1}, init -> target, 5],
        CellularAutomatonSearch[{2, 1}, init -> target, 5, Method -> "Native"]];
];

print[""];
print["=== 2. CellularAutomatonSearch: exact width (GPU: ca_find_exact_width) ==="];

With[{init = CenterArray[{1}, 21]},
    timeCompare["Width=5, 5 steps",
        CellularAutomatonSearch[{2, 1}, init -> 5, 5],
        CellularAutomatonSearch[{2, 1}, init -> 5, 5, Method -> "Native"]];
    timeCompare["Width=3, 10 steps",
        CellularAutomatonSearch[{2, 1}, init -> 3, 10],
        CellularAutomatonSearch[{2, 1}, init -> 3, 10, Method -> "Native"]];
];

print[""];
print["=== 3. CellularAutomatonBoundedWidthSearch (GPU: ca_find_bounded_width) ==="];

timeCompare["maxWidth=5, 20 steps",
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5],
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5, Method -> "Native"]];

timeCompare["maxWidth=7, 30 steps",
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 31], 30, 7],
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 31], 30, 7, Method -> "Native"]];

print[""];
print["=== 4. CellularAutomatonTest: batch (GPU: ca_test_rules) ==="];

With[{init = {0,0,0,1,0,0,0}, target = Last @ CellularAutomaton[30, {0,0,0,1,0,0,0}, 1]},
    timeCompare["256 rules, 1 step",
        CellularAutomatonTest[Range[0, 255], init -> target, 1],
        CellularAutomatonTest[Range[0, 255], init -> target, 1, {2, 1}, Method -> "Native"]];
];

With[{init = CenterArray[{1}, 21], target = Last @ CellularAutomaton[110, CenterArray[{1}, 21], 5]},
    timeCompare["256 rules, 5 steps wider tape",
        CellularAutomatonTest[Range[0, 255], init -> target, 5],
        CellularAutomatonTest[Range[0, 255], init -> target, 5, {2, 1}, Method -> "Native"]];
];

print[""];
print["=== 5. CellularAutomatonWidthRatioSearch: small range (GPU: ca_find_width_ratio) ==="];

timeCompare["ratio=2, range 54200..54300, k=3 r=1",
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3, 1}, 54200 ;; 54300, 15],
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3, 1}, 54200 ;; 54300, 15, Method -> "Native"]];

timeCompare["ratio=2, range 0..255, k=2 r=1",
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 21]}, 10, 2, {2, 1}],
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 21]}, 10, 2, {2, 1}, Method -> "Native"]];

print[""];
print["=== 6. CellularAutomatonWidthRatioSearch: sieve path (GPU: ca_refine_doublers) ==="];
print["   Filter pre-found candidate rules through additional constraints"];

(* Get doubler candidates from GPU first, then compare sieve paths *)
With[{db = CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3, 1}, 54200 ;; 54300, 15]},
    If[Length[db] > 0,
        timeCompare["Sieve through 2nd init",
            CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1, 1}, 41]}, 10, 2, {3, 1}, db],
            CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1, 1}, 41]}, 10, 2, {3, 1}, db, Method -> "Native"]];
    ];
];

(* NKS doubler sieve — GPU-only algorithm (sequential-scan update, NOT standard parallel CA)
   The built-in CellularAutomaton cannot replicate NKS sequential-scan behavior,
   so we benchmark GPU only, no native comparison *)
With[{doublers = CellularAutomatonWidthRatioSearch[
    Table[Append[ConstantArray[1, n], 2], {n, 0, 5}], 400, 2, {3, 1}]},
    print["   (", Length[doublers], " NKS doubler candidates — GPU-only, no native equivalent)"];
    With[{t = First @ AbsoluteTiming[
        CellularAutomatonWidthRatioSearch[
            Table[Append[ConstantArray[1, n], 2], {n, 0, 10}], 400, 2, {3, 1}, doublers]]},
        print["  \[Checkmark] NKS sieve n=1..10 (GPU-only): ", NumberForm[1000 t, 4], "ms"];
    ];
];

print[""];
print["=== 7. CellularAutomatonOutputTable (Rayon parallel) ==="];

timeCompare["256 rules, width 11, 5 steps",
    CellularAutomatonOutputTable[2, 1, CenterArray[{1}, 11], 5],
    CellularAutomatonOutputTable[2, 1, CenterArray[{1}, 11], 5, Method -> "Native"]];

timeCompare["256 rules, width 21, 10 steps",
    CellularAutomatonOutputTable[2, 1, CenterArray[{1}, 21], 10],
    CellularAutomatonOutputTable[2, 1, CenterArray[{1}, 21], 10, Method -> "Native"]];

print[""];
print["=== 8. CellularAutomatonActiveWidths (Rayon parallel) ==="];

timeCompare["256 rules, width 21, 20 steps",
    CellularAutomatonActiveWidths[CenterArray[{1}, 21], 20],
    CellularAutomatonActiveWidths[CenterArray[{1}, 21], 20, Method -> "Native"]];


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
