#!/usr/bin/env wolframscript

(* CA Paclet Test Runner *)
(* Run with: wolframscript -f Tests/run_tests.wl *)

print[a___] := WriteString["stdout", a, "\n"];

print["=== CA Paclet Test Suite ==="];
print[""];

(* Load paclet *)
print["Loading paclet..."];
PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName, 2], "CellularAutomaton"}]];
Needs["WolframInstitute`CellularAutomaton`"];
print["Paclet loaded successfully."];
print[""];

(* Test infrastructure *)
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
            print["    Expected: ", expected];
            print["    Got:      ", result];
        ]
    ]
)

SetAttributes[runTestQ, HoldAll];
runTestQ[name_String, expr_] := (
    $testCount++;
    With[{result = expr},
        If[ TrueQ[result],
            $passCount++;
            print["  \[Checkmark] ", name];
            ,
            $failCount++;
            AppendTo[$failures, name];
            print["  \[Times] ", name];
            print["    Expected: True"];
            print["    Got:      ", result];
        ]
    ]
)

(* ---- Tests ---- *)

print["--- CellularAutomatonRuleCount ---"];

runTest["Elementary CA: k=2, r=1 -> 256 rules",
    CellularAutomatonRuleCount[2, 1],
    256
];

runTest["k=3, r=1 -> 3^27 = 7625597484987",
    CellularAutomatonRuleCount[3, 1],
    7625597484987
];

print[""];
print["--- CellularAutomatonOutput (final state) ---"];

runTest["Rule 30, single cell width 7, 1 step",
    CellularAutomatonOutput[30, 2, 1, {0, 0, 0, 1, 0, 0, 0}, 1],
    {0, 0, 1, 1, 1, 0, 0}
];

runTest["Rule 30, single cell width 7, 2 steps",
    CellularAutomatonOutput[30, 2, 1, {0, 0, 0, 1, 0, 0, 0}, 2],
    {0, 1, 1, 0, 0, 1, 0}
];

runTest["Rule 0, all cells die",
    CellularAutomatonOutput[0, 2, 1, {1, 1, 1, 1, 1}, 1],
    {0, 0, 0, 0, 0}
];

runTest["Rule 255, all cells alive",
    CellularAutomatonOutput[255, 2, 1, {0, 0, 0, 0, 0}, 1],
    {1, 1, 1, 1, 1}
];

runTest["Rule 30, elementary shorthand",
    CellularAutomatonOutput[30, {0, 0, 0, 1, 0, 0, 0}, 1],
    {0, 0, 1, 1, 1, 0, 0}
];

print[""];
print["--- CellularAutomatonEvolution (spacetime) ---"];

With[{evo = CellularAutomatonEvolution[30, {0, 0, 0, 1, 0, 0, 0}, 2]},
    runTest["Evolution returns matrix",
        Dimensions[evo],
        {3, 7}  (* 3 rows (init + 2 steps), 7 cols *)
    ];
    runTest["Evolution first row is initial state",
        evo[[1]],
        {0, 0, 0, 1, 0, 0, 0}
    ];
    runTest["Evolution second row matches step 1",
        evo[[2]],
        {0, 0, 1, 1, 1, 0, 0}
    ];
    runTest["Evolution third row matches step 2",
        evo[[3]],
        {0, 1, 1, 0, 0, 1, 0}
    ];
];

runTest["Evolution elementary shorthand",
    Dimensions[CellularAutomatonEvolution[110, {0, 0, 0, 1, 0, 0, 0}, 5]],
    {6, 7}
];

print[""];
print["--- CellularAutomatonSearch ---"];

With[{target = CellularAutomatonOutput[30, {0, 0, 0, 1, 0, 0, 0}, 1]},
    runTestQ["Search finds rule 30 for its own output",
        MemberQ[CellularAutomatonSearch[{0, 0, 0, 1, 0, 0, 0}, 1, target], 30]
    ];
];

With[{target = CellularAutomatonOutput[110, {0, 0, 0, 1, 0, 0, 0}, 1]},
    runTestQ["Search finds rule 110 for its own output",
        MemberQ[CellularAutomatonSearch[{0, 0, 0, 1, 0, 0, 0}, 1, target], 110]
    ];
];

print[""];
print["--- CellularAutomatonOutputTable ---"];

With[{table = CellularAutomatonOutputTable[{0, 0, 0, 1, 0, 0, 0}, 1]},
    runTest["Output table has 256 entries (elementary)",
        Length[table],
        256
    ];
];

print[""];
print["--- CellularAutomatonPlot ---"];

runTestQ["Plot produces Graphics for rule 30",
    MatchQ[CellularAutomatonPlot[30, 21, 10], _Graphics]
];

runTestQ["Plot with explicit init produces Graphics",
    MatchQ[CellularAutomatonPlot[110, {0, 0, 0, 1, 0, 0, 0}, 5], _Graphics]
];

print[""];
print["--- CellularAutomatonBoundedWidthSearch ---"];

With[{bounded = CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5]},
    runTestQ["Bounded search returns list", ListQ[bounded]];
    runTestQ["Rule 0 is bounded (all die)", MemberQ[bounded, 0]];
    runTestQ["Rule 30 is NOT bounded (expands)", !MemberQ[bounded, 30]];
];

print[""];
print["--- CellularAutomatonActiveWidths ---"];

With[{widths = CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10]},
    runTest["Active widths has 256 rows", Length[widths], 256];
    runTest["Each row has 2 elements (max,final)", Length[widths[[1]]], 2];
    runTestQ["Rule 30 max width > 1", widths[[31, 1]] > 1]; (* rule 30 is index 31 in 1-indexed *)
];

print[""];
print["--- CellularAutomatonWidthRatioSearch ---"];

With[{inits = {CenterArray[{1}, 41], CenterArray[{1, 2, 1}, 41]}},
    With[{doublers = CellularAutomatonWidthRatioSearch[inits, 15, 2, {3, 1}, 54240 ;; 54240, 15]},
        runTestQ["Width ratio search returns list", ListQ[doublers]];
        runTestQ["Rule 54240 is a width doubler", MemberQ[doublers, 54240]];
    ];
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
    print["FAIL"];
    Exit[1];
    ,
    print[""];
    print["ALL TESTS PASSED"];
    Exit[0];
];
