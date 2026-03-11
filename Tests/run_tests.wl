#!/usr/bin/env wolframscript

(* CA Paclet Test Suite — Consolidated *)
(* Run with: wolframscript -f Tests/run_tests.wl *)
(* Uses WL VerificationTest / TestReport framework *)

print[a___] := WriteString["stdout", a, "\n"];

print["=== CA Paclet Test Suite ==="];
print[""];

(* Load paclet *)
print["Loading paclet..."];
PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName, 2], "CellularAutomaton"}]];
Needs["WolframInstitute`CellularAutomaton`"];
print["Paclet loaded."];
print[""];

(* Collect all VerificationTest results *)
$results = <||>;
SetAttributes[test, HoldRest];
test[id_String, input_, expected_] := With[{obj = VerificationTest[input, expected, TestID -> id]},
    $results[id] = obj;
    If[obj["Outcome"] === "Success",
        print["  \[Checkmark] ", id],
        print["  \[Times] ", id];
        print["    Expected: ", Short[obj["ExpectedOutput"] // ReleaseHold, 2]];
        print["    Got:      ", Short[obj["ActualOutput"] // ReleaseHold, 2]];
    ];
];
(* Boolean predicate test: input should evaluate to True *)
SetAttributes[testQ, HoldRest];
testQ[id_String, input_] := test[id, input, True];

(* ========================================================================== *)
(* 1. CellularAutomatonRuleCount *)
(* ========================================================================== *)
print["--- CellularAutomatonRuleCount ---"];

test["RuleCount: k=2 r=1 -> 256", CellularAutomatonRuleCount[2, 1], 256];
test["RuleCount: k=3 r=1 -> 3^27", CellularAutomatonRuleCount[3, 1], 7625597484987];

(* ========================================================================== *)
(* 2. CellularAutomatonOutput *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonOutput ---"];

test["Output: rule 30 w=7 s=1",
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 1], {0,0,1,1,1,0,0}];
test["Output: rule 30 w=7 s=2",
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 2], {0,1,1,0,0,1,0}];
test["Output: rule 0 all die",
    CellularAutomatonOutput[0, 2, 1, {1,1,1,1,1}, 1], {0,0,0,0,0}];
test["Output: rule 255 all alive",
    CellularAutomatonOutput[255, 2, 1, {0,0,0,0,0}, 1], {1,1,1,1,1}];
test["Output: elementary shorthand",
    CellularAutomatonOutput[30, {0,0,0,1,0,0,0}, 1], {0,0,1,1,1,0,0}];
test["Output: zero steps = init",
    CellularAutomatonOutput[30, {0,0,1,0,0}, 0], {0,0,1,0,0}];
test["Output: rule 204 identity",
    CellularAutomatonOutput[204, {1,0,1,1,0}, 5], {1,0,1,1,0}];
test["Output: all-zero stays zero",
    CellularAutomatonOutput[30, {0,0,0,0,0}, 3], {0,0,0,0,0}];

(* ========================================================================== *)
(* 3. CellularAutomatonEvolution *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonEvolution ---"];

With[{evo = CellularAutomatonEvolution[30, {0,0,0,1,0,0,0}, 2]},
    test["Evolution: dimensions", Dimensions[evo], {3, 7}];
    test["Evolution: row 1 = init", evo[[1]], {0,0,0,1,0,0,0}];
    test["Evolution: row 2", evo[[2]], {0,0,1,1,1,0,0}];
    test["Evolution: row 3", evo[[3]], {0,1,1,0,0,1,0}];
];
test["Evolution: shorthand dims",
    Dimensions[CellularAutomatonEvolution[110, {0,0,0,1,0,0,0}, 5]], {6, 7}];

(* ========================================================================== *)
(* 4. CellularAutomatonSearch *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonSearch ---"];

With[{target30 = CellularAutomatonOutput[30, {0,0,0,1,0,0,0}, 1]},
    testQ["Search: finds rule 30 (legacy)",
        MemberQ[CellularAutomatonSearch[{0,0,0,1,0,0,0}, 1, target30], 30]];
    testQ["Search: finds rule 30 (new API)",
        MemberQ[CellularAutomatonSearch[{0,0,0,1,0,0,0} -> target30, 1], 30]];
    testQ["Search: {k,r} rulespec",
        MemberQ[CellularAutomatonSearch[{2,1}, {0,0,0,1,0,0,0} -> target30, 1], 30]];
    testQ["Search: {All,k,r} alias",
        MemberQ[CellularAutomatonSearch[{All,2,1}, {0,0,0,1,0,0,0} -> target30, 1], 30]];
    test["Search: candidate list",
        CellularAutomatonSearch[{{30,90,110}, 2, 1}, {0,0,0,1,0,0,0} -> target30, 1], {30}];
];

With[{target110 = CellularAutomatonOutput[110, {0,0,0,1,0,0,0}, 1]},
    testQ["Search: finds rule 110",
        MemberQ[CellularAutomatonSearch[{0,0,0,1,0,0,0} -> target110, 1], 110]];
];

(* Multi-pair sieve *)
With[{
    init1 = {0,0,0,1,0,0,0}, target1 = CellularAutomatonOutput[30, {0,0,0,1,0,0,0}, 1],
    init2 = {0,0,1,0,0,0,0}, target2 = CellularAutomatonOutput[30, {0,0,1,0,0,0,0}, 1]
},
    testQ["Search: multi-pair sieve finds rule 30",
        MemberQ[CellularAutomatonSearch[{2,1}, {init1 -> target1, init2 -> target2}, 1], 30]];
    testQ["Search: sieve narrows results",
        Length[CellularAutomatonSearch[{2,1}, {init1 -> target1, init2 -> target2}, 1]] <=
        Length[CellularAutomatonSearch[{2,1}, init1 -> target1, 1]]];
];

(* Width target *)
With[{init = CenterArray[{1}, 21]},
    testQ["Search: width target returns results",
        Length[CellularAutomatonSearch[init -> 7, 3]] > 0];
    testQ["Search: width target {k,r}",
        Length[CellularAutomatonSearch[{2,1}, init -> 7, 3]] > 0];
    testQ["Search: width target (legacy)",
        ListQ[CellularAutomatonSearch[init, 3, 7]]];
];

(* ========================================================================== *)
(* 5. CellularAutomatonOutputTable *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonOutputTable ---"];

test["OutputTable: 256 entries",
    Length[CellularAutomatonOutputTable[{0,0,0,1,0,0,0}, 1]], 256];

(* ========================================================================== *)
(* 6. CellularAutomatonPlot *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonPlot ---"];

testQ["Plot: rule 30", MatchQ[CellularAutomatonPlot[30, 21, 10], _Graphics]];
testQ["Plot: explicit init", MatchQ[CellularAutomatonPlot[110, {0,0,0,1,0,0,0}, 5], _Graphics]];

(* ========================================================================== *)
(* 7. CellularAutomatonBoundedWidthSearch *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonBoundedWidthSearch ---"];

With[{bounded = CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5]},
    testQ["BoundedWidth: returns list", ListQ[bounded]];
    testQ["BoundedWidth: rule 0 bounded", MemberQ[bounded, 0]];
    testQ["BoundedWidth: rule 30 NOT bounded", !MemberQ[bounded, 30]];
];

(* ========================================================================== *)
(* 8. CellularAutomatonActiveWidths *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonActiveWidths ---"];

With[{widths = CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10]},
    test["ActiveWidths: 256 rows", Length[widths], 256];
    test["ActiveWidths: 2 per row", Length[widths[[1]]], 2];
    testQ["ActiveWidths: rule 30 max > 1", widths[[31, 1]] > 1];
];

(* ========================================================================== *)
(* 9. CellularAutomatonWidthRatioSearch *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonWidthRatioSearch ---"];

testQ["WidthRatio: finds rule 54240",
    MemberQ[CellularAutomatonWidthRatioSearch[
        {CenterArray[{1}, 41], CenterArray[{1,2,1}, 41]}, 15, 2, {3,1}, 54240 ;; 54240, 15], 54240]];

With[{pass1 = CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 10, 2, {3,1}, 54230 ;; 54250, 15]},
    If[Length[pass1] > 0,
        With[{sieved = CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1,1}, 41]}, 10, 2, {3,1}, pass1]},
            testQ["WidthRatio: sieve returns list", ListQ[sieved]];
            testQ["WidthRatio: sieve subset", SubsetQ[pass1, sieved]];
        ];
    ];
];

(* ========================================================================== *)
(* 10. CellularAutomatonTest *)
(* ========================================================================== *)
print[""];
print["--- CellularAutomatonTest ---"];

With[{init = {0,0,0,1,0,0,0}, target = CellularAutomatonOutput[30, {0,0,0,1,0,0,0}, 1]},
    test["Test: single True", CellularAutomatonTest[30, init -> target, 1], True];
    test["Test: single False", CellularAutomatonTest[90, init -> target, 1], False];
    testQ["Test: rulespec {rule,k,r}", CellularAutomatonTest[{30,2,1}, init -> target, 1]];
    testQ["Test: batch includes rule 30",
        MemberQ[CellularAutomatonTest[Range[0,255], init -> target, 1], 30]];
    testQ["Test: batch excludes non-matching",
        !MemberQ[CellularAutomatonTest[Range[0,255], init -> target, 1], 1]];
    test["Test: list of specs",
        CellularAutomatonTest[{{30,2,1},{90,2,1}}, init -> target, 1], {{30,2,1}}];
];

With[{init = Join[ConstantArray[0,15], {1,2}, ConstantArray[0,15]], rule = 1920106431},
    With[{target = CellularAutomatonOutput[rule, 3, 1, init, 5]},
        test["Test: k=3 r=1 rulespec", CellularAutomatonTest[{rule,3,1}, init -> target, 5], True];
        test["Test: k=3 r=1 batch", CellularAutomatonTest[{rule,123456,654321}, init -> target, 5, {3,1}], {rule}];
    ];
];

test["Test: NKS doubler {2}->{1,1}",
    CellularAutomatonTest[{4517262867726,3,1}, {2} -> {1,1}, 200], True];
test["Test: NKS doubler {1,2}->{1,1,1,1}",
    CellularAutomatonTest[{4517262867726,3,1}, {1,2} -> {1,1,1,1}, 200], True];
test["Test: NKS doubler table n=1..10",
    Table[CellularAutomatonTest[{4517262867726,3,1},
        Append[ConstantArray[1,n],2] -> ConstantArray[1,2(n+1)], 200], {n, 10}],
    ConstantArray[True, 10]];

(* ========================================================================== *)
(* 11. TimeConstrained *)
(* ========================================================================== *)
print[""];
print["--- TimeConstrained ---"];

testQ["TimeConstrained: k=3 search",
    With[{result = TimeConstrained[
        CellularAutomatonSearch[{3,1},
            Join[ConstantArray[0,5],{1},ConstantArray[0,5]] ->
            CellularAutomatonOutput[1920106431, 3, 1, Join[ConstantArray[0,5],{1},ConstantArray[0,5]], 1], 1],
        10, "$TimedOut"]},
        ListQ[result] || result === "$TimedOut"]];

test["TimeConstrained: elementary completes",
    TimeConstrained[
        MemberQ[CellularAutomatonSearch[{2,1},
            {0,0,0,1,0,0,0} -> CellularAutomatonOutput[30, {0,0,0,1,0,0,0}, 1], 1], 30],
        5, False],
    True];

(* ========================================================================== *)
(* 12. k=4 BigInteger rules *)
(* ========================================================================== *)
print[""];
print["--- BigInteger k=4 ---"];

testQ["BigInt: k=4 rule count > 2^64", CellularAutomatonRuleCount[4, 1] > 2^64];
testQ["BigInt: k=4 output is list",
    ListQ[CellularAutomatonOutput[123456789012345678901234567890, 4, 1, {0,0,1,0,0}, 3]]];
testQ["BigInt: k=4 output in range",
    AllTrue[CellularAutomatonOutput[123456789012345678901234567890, 4, 1, {0,0,1,0,0}, 3], 0 <= # < 4 &]];
testQ["BigInt: k=4 seed search",
    ListQ[CellularAutomatonSearch[{42 -> 100, 4, 1},
        {0,0,1,0,0} -> CellularAutomatonOutput[42, 4, 1, {0,0,1,0,0}, 1], 1]]];
testQ["BigInt: k=4 multi-pair sieve",
    ListQ[CellularAutomatonSearch[{42 -> 100, 4, 1},
        Table[Append[ConstantArray[1,n],2] -> ConstantArray[1,2(n+1)], {n, 0, 2}], 100]]];

(* ========================================================================== *)
(* 13. Cross-validation: Rust vs WL CellularAutomaton *)
(* ========================================================================== *)
print[""];
print["--- Cross-validation: Rust vs builtin CellularAutomaton ---"];

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

(* ========================================================================== *)
(* 14. Rust vs Native correctness (Method -> "Native") *)
(* ========================================================================== *)
print[""];
print["--- Rust vs Native correctness ---"];

(* Output *)
test["RustVsNative: Output rule 30 w=7 s=10",
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 10],
    CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 10, Method -> "Native"]];
test["RustVsNative: Output k=3",
    CellularAutomatonOutput[123456, 3, 1, Join[ConstantArray[0,10],{1,2,0},ConstantArray[0,10]], 5],
    CellularAutomatonOutput[123456, 3, 1, Join[ConstantArray[0,10],{1,2,0},ConstantArray[0,10]], 5, Method -> "Native"]];

(* Evolution *)
test["RustVsNative: Evolution rule 110 w=21 s=20",
    CellularAutomatonEvolution[110, 2, 1, CenterArray[{1}, 21], 20],
    CellularAutomatonEvolution[110, 2, 1, CenterArray[{1}, 21], 20, Method -> "Native"]];

(* Search *)
With[{init = CenterArray[{1}, 11], target = Last @ CellularAutomaton[30, CenterArray[{1}, 11], 3]},
    test["RustVsNative: Search k=2",
        CellularAutomatonSearch[{2,1}, init -> target, 3],
        CellularAutomatonSearch[{2,1}, init -> target, 3, Method -> "Native"]];
];
test["RustVsNative: ExactWidth k=2",
    CellularAutomatonSearch[{2,1}, CenterArray[{1}, 11] -> 3, 2],
    CellularAutomatonSearch[{2,1}, CenterArray[{1}, 11] -> 3, 2, Method -> "Native"]];

(* OutputTable *)
test["RustVsNative: OutputTable k=2",
    CellularAutomatonOutputTable[{0,0,0,1,0,0,0}, 1],
    CellularAutomatonOutputTable[{0,0,0,1,0,0,0}, 1, Method -> "Native"]];

(* BoundedWidth *)
test["RustVsNative: BoundedWidth k=2",
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5],
    CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5, Method -> "Native"]];

(* ActiveWidths *)
test["RustVsNative: ActiveWidths k=2",
    CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10],
    CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10, Method -> "Native"]];

(* Test batch *)
With[{init = {0,0,0,1,0,0,0}, target = Last @ CellularAutomaton[30, {0,0,0,1,0,0,0}, 1]},
    test["RustVsNative: Test batch k=2",
        CellularAutomatonTest[Range[0,255], init -> target, 1],
        CellularAutomatonTest[Range[0,255], init -> target, 1, {2,1}, Method -> "Native"]];
];

(* WidthRatio *)
test["RustVsNative: WidthRatio k=3",
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3,1}, 54200 ;; 54300, 15],
    CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 15, 2, {3,1}, 54200 ;; 54300, 15, Method -> "Native"]];

(* Sieve *)
With[{candidates = CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 10, 2, {3,1}, 54230 ;; 54250, 15]},
    If[Length[candidates] > 0,
        test["RustVsNative: Sieve filter",
            CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1,1}, 41]}, 10, 2, {3,1}, candidates],
            CellularAutomatonWidthRatioSearch[
                {CenterArray[{1}, 41], CenterArray[{1,1}, 41]}, 10, 2, {3,1}, candidates, Method -> "Native"]];
    ];
];

(* ========================================================================== *)
(* 15. NKS GPU Doubler Search *)
(* ========================================================================== *)
print[""];
print["--- NKS GPU Doubler Search ---"];

print["  Computing doublers n=1..20 (GPU)..."];
{tDb, db20} = AbsoluteTiming[CellularAutomatonWidthRatioSearch[
    Table[Append[ConstantArray[1, n], 2], {n, 0, 20}], 400, 2, {3, 1}]];
print["  Found ", Length[db20], " doublers in ", NumberForm[tDb, 4], "s"];

test["NKS: doubler count = 4278", Length[db20], 4278];
testQ["NKS: known doubler 4517262867726 present", MemberQ[db20, 4517262867726]];

(* Monotonicity *)
With[{
    db5 = CellularAutomatonWidthRatioSearch[Table[Append[ConstantArray[1,n],2], {n,0,5}], 400, 2, {3,1}],
    db10 = CellularAutomatonWidthRatioSearch[Table[Append[ConstantArray[1,n],2], {n,0,10}], 400, 2, {3,1}]
},
    testQ["NKS: monotonicity db5 \[Superset] db10 \[Superset] db20",
        SubsetQ[db5, db10] && SubsetQ[db10, db20]];
];

(* Sieve consistency *)
With[{db5 = CellularAutomatonWidthRatioSearch[Table[Append[ConstantArray[1,n],2], {n,0,5}], 400, 2, {3,1}]},
    test["NKS: sieve(db5, n=1..20) == db20",
        Sort[CellularAutomatonWidthRatioSearch[
            Table[Append[ConstantArray[1,n],2], {n,0,20}], 400, 2, {3,1}, db5]],
        Sort[db20]];
];

(* Spot-check *)
testQ["NKS: spot-check 20 doublers n=1..5",
    AllTrue[Take[db20, UpTo[20]], Function[rule,
        AllTrue[Range[5], Function[n,
            CellularAutomatonTest[{rule, 3, 1},
                Append[ConstantArray[1, n], 2] -> ConstantArray[1, 2 (n + 1)], 200]
        ]]]]];


(* ========================================================================== *)
(* Summary *)
(* ========================================================================== *)

$total = Length[$results];
$passed = Count[$results, _?(#["Outcome"] === "Success" &)];
$failed = $total - $passed;
$failNames = Keys[Select[$results, #["Outcome"] =!= "Success" &]];

print[""];
print["=== Results ==="];
print["Total:  ", $total];
print["Passed: ", $passed];
print["Failed: ", $failed];

If[$failed > 0,
    print[""];
    print["Failed tests:"];
    Scan[print["  - ", #] &, $failNames];
    print[""];
    print["SOME TESTS FAILED"];
    Exit[1];
    ,
    print[""];
    print["ALL TESTS PASSED"];
    Exit[0];
];
