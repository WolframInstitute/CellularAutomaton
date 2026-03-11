(* Core API tests *)
(* Tests basic functionality of all public CellularAutomaton functions *)

print["--- CellularAutomatonRuleCount ---"];

test["RuleCount: k=2 r=1 -> 256", CellularAutomatonRuleCount[2, 1], 256];
test["RuleCount: k=3 r=1 -> 3^27", CellularAutomatonRuleCount[3, 1], 7625597484987];

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

With[{init = CenterArray[{1}, 21]},
    testQ["Search: width target returns results",
        Length[CellularAutomatonSearch[init -> 7, 3]] > 0];
    testQ["Search: width target {k,r}",
        Length[CellularAutomatonSearch[{2,1}, init -> 7, 3]] > 0];
    testQ["Search: width target (legacy)",
        ListQ[CellularAutomatonSearch[init, 3, 7]]];
];

print[""];
print["--- CellularAutomatonOutputTable ---"];

test["OutputTable: 256 entries",
    Length[CellularAutomatonOutputTable[{0,0,0,1,0,0,0}, 1]], 256];

print[""];
print["--- CellularAutomatonPlot ---"];

testQ["Plot: rule 30", MatchQ[CellularAutomatonPlot[30, 21, 10], _Graphics]];
testQ["Plot: explicit init", MatchQ[CellularAutomatonPlot[110, {0,0,0,1,0,0,0}, 5], _Graphics]];

print[""];
print["--- CellularAutomatonBoundedWidthSearch ---"];

With[{bounded = CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5]},
    testQ["BoundedWidth: returns list", ListQ[bounded]];
    testQ["BoundedWidth: rule 0 bounded", MemberQ[bounded, 0]];
    testQ["BoundedWidth: rule 30 NOT bounded", !MemberQ[bounded, 30]];
];

print[""];
print["--- CellularAutomatonActiveWidths ---"];

With[{widths = CellularAutomatonActiveWidths[CenterArray[{1}, 21], 10]},
    test["ActiveWidths: 256 rows", Length[widths], 256];
    test["ActiveWidths: 2 per row", Length[widths[[1]]], 2];
    testQ["ActiveWidths: rule 30 max > 1", widths[[31, 1]] > 1];
];

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

print[""];
print["--- Rulespec / Span / List patterns ---"];

With[{init = {0,0,0,1,0,0,0},
      out30 = CellularAutomatonOutput[30, 2, 1, {0,0,0,1,0,0,0}, 1]},

    (* Output: {rule,k,r} rulespec *)
    test["Output: {rule,k,r} rulespec",
        CellularAutomatonOutput[{30, 2, 1}, init, 1], out30];
    (* Output: {k,r} + rule *)
    test["Output: {k,r} + rule",
        CellularAutomatonOutput[{2, 1}, init, 1, 30], out30];
    (* Output: {k,r} + span *)
    test["Output: {k,r} + span length",
        Length[CellularAutomatonOutput[{2, 1}, init, 1, 28 ;; 30]], 3];
    test["Output: {k,r} + span last = rule 30",
        Last[CellularAutomatonOutput[{2, 1}, init, 1, 28 ;; 30]], out30];
    (* Output: {k,r} + list *)
    test["Output: {k,r} + list",
        CellularAutomatonOutput[{2, 1}, init, 1, {30}], {out30}];

    (* Evolution: {rule,k,r} rulespec *)
    test["Evolution: {rule,k,r} rulespec dims",
        Dimensions[CellularAutomatonEvolution[{30, 2, 1}, init, 2]], {3, 7}];
    test["Evolution: {rule,k,r} last row",
        Last[CellularAutomatonEvolution[{30, 2, 1}, init, 1]], out30];
    (* Evolution: {k,r} + rule *)
    test["Evolution: {k,r} + rule dims",
        Dimensions[CellularAutomatonEvolution[{2, 1}, init, 2, 30]], {3, 7}];
    (* Evolution: {k,r} + list *)
    test["Evolution: {k,r} + list length",
        Length[CellularAutomatonEvolution[{2, 1}, init, 2, {30, 90}]], 2];

    (* Search: list of rules *)
    test["Search: {k,r} + rules list",
        CellularAutomatonSearch[{2, 1}, init -> out30, 1, {28, 29, 30, 31}], {30}];
    (* Search: span *)
    testQ["Search: {k,r} + span finds rule 30",
        MemberQ[CellularAutomatonSearch[{2, 1}, init -> out30, 1, 28 ;; 32], 30]];

    (* Test: span *)
    test["Test: span filters",
        CellularAutomatonTest[28 ;; 32, init -> out30, 1], {30}];
    test["Test: span with {k,r}",
        CellularAutomatonTest[28 ;; 32, init -> out30, 1, {2, 1}], {30}];

    (* OutputTable: list *)
    test["OutputTable: {k,r} + list",
        CellularAutomatonOutputTable[2, 1, init, 1, {30}], {out30}];
    test["OutputTable: {k,r} + list length",
        Length[CellularAutomatonOutputTable[2, 1, init, 1, {28, 29, 30}]], 3];
];

(* BoundedWidth: list *)
With[{bw = CellularAutomatonBoundedWidthSearch[CenterArray[{1}, 21], 20, 5, {2, 1}, {0, 1, 30, 204}]},
    testQ["BoundedWidth: list includes rule 0", MemberQ[bw, 0]];
    testQ["BoundedWidth: list excludes rule 30", !MemberQ[bw, 30]];
];

(* ActiveWidths: list *)
With[{aw = CellularAutomatonActiveWidths[2, 1, CenterArray[{1}, 11], 5, {0, 30, 204}]},
    test["ActiveWidths: list length", Length[aw], 3];
    test["ActiveWidths: list shape", Length[aw[[1]]], 2];
    testQ["ActiveWidths: rule 30 wider than rule 0", aw[[2, 1]] > aw[[1, 1]]];
];

(* WidthRatio: span *)
testQ["WidthRatio: span search",
    ListQ[CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 41]}, 10, 2, {3, 1}, 54230 ;; 54250, 15]]];

(* k=3 rulespec patterns *)
With[{kinit = Join[ConstantArray[0,5], {1,2,0}, ConstantArray[0,5]]},
    test["Output: k=3 {rule,k,r}",
        CellularAutomatonOutput[{123456, 3, 1}, kinit, 1],
        CellularAutomatonOutput[123456, 3, 1, kinit, 1]];
    test["Evolution: k=3 {rule,k,r} dims",
        Dimensions[CellularAutomatonEvolution[{123456, 3, 1}, kinit, 3]],
        {4, Length[kinit]}];
];
