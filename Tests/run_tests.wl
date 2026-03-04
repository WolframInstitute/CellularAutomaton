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
    runTestQ["Search finds rule 30 (legacy)",
        MemberQ[CellularAutomatonSearch[{0, 0, 0, 1, 0, 0, 0}, 1, target], 30]
    ];
    runTestQ["Search finds rule 30 (new API)",
        MemberQ[CellularAutomatonSearch[{0, 0, 0, 1, 0, 0, 0} -> target, 1], 30]
    ];
    runTestQ["Search with rulespec {k,r}",
        MemberQ[CellularAutomatonSearch[{2, 1}, {0, 0, 0, 1, 0, 0, 0} -> target, 1], 30]
    ];
];

With[{target = CellularAutomatonOutput[110, {0, 0, 0, 1, 0, 0, 0}, 1]},
    runTestQ["Search finds rule 110",
        MemberQ[CellularAutomatonSearch[{0, 0, 0, 1, 0, 0, 0} -> target, 1], 110]
    ];
];

(* {All, k, r} alias *)
With[{target = CellularAutomatonOutput[30, {0, 0, 0, 1, 0, 0, 0}, 1]},
    runTestQ["{All, k, r} alias works",
        MemberQ[CellularAutomatonSearch[{All, 2, 1}, {0, 0, 0, 1, 0, 0, 0} -> target, 1], 30]
    ];
];

(* Candidate list rulespec *)
With[{
    init = {0, 0, 0, 1, 0, 0, 0},
    target = CellularAutomatonOutput[30, {0, 0, 0, 1, 0, 0, 0}, 1]
},
    runTest["Candidate list filters correctly",
        CellularAutomatonSearch[{{30, 90, 110}, 2, 1}, init -> target, 1],
        {30}
    ];
];

(* Multi-pair sieve *)
With[{
    init1 = {0, 0, 0, 1, 0, 0, 0},
    target1 = CellularAutomatonOutput[30, {0, 0, 0, 1, 0, 0, 0}, 1],
    init2 = {0, 0, 1, 0, 0, 0, 0},
    target2 = CellularAutomatonOutput[30, {0, 0, 1, 0, 0, 0, 0}, 1]
},
    runTestQ["Multi-pair sieve finds rule 30",
        MemberQ[
            CellularAutomatonSearch[{2, 1}, {init1 -> target1, init2 -> target2}, 1],
            30
        ]
    ];
    (* Sieve should narrow down results *)
    runTestQ["Sieve narrows results",
        Length[CellularAutomatonSearch[{2, 1}, {init1 -> target1, init2 -> target2}, 1]] <=
        Length[CellularAutomatonSearch[{2, 1}, init1 -> target1, 1]]
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

print[""];
print["--- CellularAutomatonTest ---"];

With[{
    init = {0, 0, 0, 1, 0, 0, 0},
    target = CellularAutomatonOutput[30, {0, 0, 0, 1, 0, 0, 0}, 1]
},
    runTest["Single rule True", CellularAutomatonTest[30, init -> target, 1], True];
    runTest["Single rule False", CellularAutomatonTest[90, init -> target, 1], False];
    runTestQ["Rulespec {rule, k, r} True",
        CellularAutomatonTest[{30, 2, 1}, init -> target, 1]];
    runTestQ["Batch test includes rule 30",
        MemberQ[CellularAutomatonTest[Range[0, 255], init -> target, 1], 30]
    ];
    runTestQ["Batch test excludes non-matching",
        !MemberQ[CellularAutomatonTest[Range[0, 255], init -> target, 1], 1]
    ];
    runTest["List of specs filters",
        CellularAutomatonTest[{{30, 2, 1}, {90, 2, 1}}, init -> target, 1],
        {{30, 2, 1}}
    ];
];

(* Test with k=3, r=1 *)
With[{
    init = Join[ConstantArray[0, 15], {1, 2}, ConstantArray[0, 15]],
    rule = 1920106431
},
    With[{target = CellularAutomatonOutput[rule, 3, 1, init, 5]},
        runTest["k=3 r=1 rulespec True",
            CellularAutomatonTest[{rule, 3, 1}, init -> target, 5], True];
        runTest["k=3 r=1 batch with {k,r}",
            CellularAutomatonTest[{rule, 123456, 654321}, init -> target, 5, {3, 1}],
            {rule}
        ];
    ];
];

(* Auto-padding: NKS doublers with different-length init/target *)
runTest["NKS doubler auto-pad: {2} -> {1,1}",
    CellularAutomatonTest[{4517262867726, 3, 1}, {2} -> {1, 1}, 200],
    True
];

runTest["NKS doubler auto-pad: {1,2} -> {1,1,1,1}",
    CellularAutomatonTest[{4517262867726, 3, 1}, {1, 2} -> {1, 1, 1, 1}, 200],
    True
];

runTest["NKS doubler auto-pad table",
    Table[
        CellularAutomatonTest[{4517262867726, 3, 1},
            Append[ConstantArray[1, n], 2] -> ConstantArray[1, 2 (n + 1)], 200],
        {n, 10}
    ],
    ConstantArray[True, 10]
];

print[""];
print["--- CellularAutomatonSearch (width target) ---"];

(* Width-target search: find rules producing specific active width *)
With[{init = CenterArray[{1}, 21]},
    With[{rules = CellularAutomatonSearch[init -> 7, 3]},
        runTestQ["Width search (new API) returns list", ListQ[rules]];
        runTestQ["Width search finds rules", Length[rules] > 0];
    ];
];

With[{init = CenterArray[{1}, 21]},
    With[{rules = CellularAutomatonSearch[{2, 1}, init -> 7, 3]},
        runTestQ["Width search with rulespec", ListQ[rules] && Length[rules] > 0];
    ];
];

(* Legacy width search *)
With[{init = CenterArray[{1}, 21]},
    With[{rules = CellularAutomatonSearch[init, 3, 7]},
        runTestQ["Width search (legacy) returns list", ListQ[rules]];
    ];
];

print[""];
print["--- CellularAutomatonWidthRatioSearch (sieve) ---"];

(* Test sieve functionality - filter a candidate list *)
With[{
    inits1 = {CenterArray[{1}, 41]},
    inits2 = {CenterArray[{1}, 41], CenterArray[{1, 1}, 41]},
    pass1 = CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 10, 2, {3, 1}, 54240 ;; 54240, 15]
},
    If[Length[pass1] > 0,
        With[{
            sieved = CellularAutomatonWidthRatioSearch[inits2, 10, 2, {3, 1}, pass1]
        },
            runTestQ["Sieve returns list", ListQ[sieved]];
            runTestQ["Sieve subset of original", SubsetQ[pass1, sieved]];
        ];
        ,
        runTestQ["Sieve prerequisite (pass1 non-empty)", False];
    ];
];

print[""];
print["--- Cross-validation: GPU vs WL CellularAutomaton ---"];

(* Verify our Rust CA matches Mathematica's CellularAutomaton *)
With[{init = {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0}},
    Scan[
        Function[rule,
            With[{
                ours = CellularAutomatonOutput[rule, init, 5],
                theirs = Last @ CellularAutomaton[rule, init, 5]
            },
                runTest["Cross-validate rule " <> ToString[rule],
                    ours, theirs];
            ]
        ],
        {30, 90, 110, 150, 184, 210}
    ];
];

(* k=3 cross-validation *)
With[{init = Join[ConstantArray[0, 10], {1, 2, 0}, ConstantArray[0, 10]]},
    With[{
        ours = CellularAutomatonOutput[123456, 3, 1, init, 3],
        theirs = Last @ CellularAutomaton[{123456, 3, 1}, init, 3]
    },
        runTest["Cross-validate k=3 rule 123456", ours, theirs];
    ];
];

print[""];
print["--- Edge cases ---"];

runTest["Zero steps returns init",
    CellularAutomatonOutput[30, {0, 0, 1, 0, 0}, 0],
    {0, 0, 1, 0, 0}
];

runTest["Rule 204 (identity)",
    CellularAutomatonOutput[204, {1, 0, 1, 1, 0}, 5],
    {1, 0, 1, 1, 0}
];

runTest["All-zero init stays zero",
    CellularAutomatonOutput[30, {0, 0, 0, 0, 0}, 3],
    {0, 0, 0, 0, 0}
];

print[""];
print["--- TimeConstrained (abort support) ---"];

(* TimeConstrained search should return partial results, not hang *)
With[{
    init = {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0},
    target = CellularAutomatonOutput[1920106431, 3, 1, {0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0}, 1]
},
    runTestQ["TimeConstrained k=3 search returns list or $Aborted",
        With[{result = TimeConstrained[
            CellularAutomatonSearch[{3, 1}, init -> target, 1], 10, "$TimedOut"
        ]},
            ListQ[result] || result === "$TimedOut"
        ]
    ];
];

(* Elementary search should complete within time limit *)
With[{target = CellularAutomatonOutput[30, {0, 0, 0, 1, 0, 0, 0}, 1]},
    runTest["TimeConstrained elementary completes",
        TimeConstrained[
            MemberQ[CellularAutomatonSearch[{2, 1}, {0, 0, 0, 1, 0, 0, 0} -> target, 1], 30],
            5, False
        ],
        True
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

