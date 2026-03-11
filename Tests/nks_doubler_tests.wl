(* NKS GPU Doubler Search tests *)
(* Tests Metal GPU-accelerated width-doubler search over k=3 r=1 *)
(* Verifies against known NKS count of 4278 doublers *)

print["--- NKS GPU Doubler Search ---"];

print["  Computing doublers n=1..20 (GPU)..."];
{tDb, db20} = AbsoluteTiming[CellularAutomatonWidthRatioSearch[
    Table[Append[ConstantArray[1, n], 2], {n, 0, 20}], 400, 2, {3, 1}]];
print["  Found ", Length[db20], " doublers in ", NumberForm[tDb, 4], "s"];

test["NKS: doubler count = 4278", Length[db20], 4278];
testQ["NKS: known doubler 4517262867726 present", MemberQ[db20, 4517262867726]];

(* Monotonicity: stricter tests -> fewer doublers *)
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

(* Spot-check: verify sample doublers actually double *)
testQ["NKS: spot-check 20 doublers n=1..5",
    AllTrue[Take[db20, UpTo[20]], Function[rule,
        AllTrue[Range[5], Function[n,
            CellularAutomatonTest[{rule, 3, 1},
                Append[ConstantArray[1, n], 2] -> ConstantArray[1, 2 (n + 1)], 200]
        ]]]]];
