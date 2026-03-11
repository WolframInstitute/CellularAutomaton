#!/usr/bin/env wolframscript

(* Rust/GPU vs Native Benchmark *)
(* Run with: wolframscript -f Tests/benchmark.wl *)

print[a___] := WriteString["stdout", a, "\n"];

print["=== Rust/GPU vs Native WL Benchmark ==="];
print["Platform: ", $SystemID, " | ", $ProcessorCount, " cores"];
print[""];

print["Loading paclet..."];
PacletDirectoryLoad[FileNameJoin[{DirectoryName[$InputFileName, 2], "CellularAutomaton"}]];
Needs["WolframInstitute`CellularAutomaton`"];
print["Loaded."];
print[""];

(* Format microseconds as string *)
usStr[us_] := Which[
    us >= 1000000, StringPadLeft[ToString[Round[us / 1000000., 0.01]] <> "s", 10],
    us >= 1000, StringPadLeft[ToString[Round[us / 1000., 0.01]] <> "ms", 10],
    us >= 0.1, StringPadLeft[ToString[Round[us, 0.1]] <> "us", 10],
    True, StringPadLeft["<0.1us", 10]
]

(* Time N iterations — assign result to prevent caching *)
SetAttributes[timeIt, HoldFirst];
timeIt[expr_, n_:50] := Module[{r, t},
    ClearSystemCache[];
    r = expr; (* warm up *)
    ClearSystemCache[];
    t = First @ AbsoluteTiming[Do[r = expr, n]];
    1000000. * t / n
]

SetAttributes[row, HoldAll];
row[label_, rustExpr_, nativeExpr_, n_:50] := Module[{tR, tN, spd, spdStr},
    tR = timeIt[rustExpr, n];
    tN = timeIt[nativeExpr, n];
    spd = tN / tR;
    spdStr = If[spd > 1.05, ToString[Round[spd, 0.1]] <> "x",
        If[spd < 0.95, ToString[Round[1/spd, 0.1]] <> "x slower", "~1x"]];
    print["  ", StringPadRight[label, 50], usStr[tR], "  ", usStr[tN], "   ", spdStr];
]

header[] := (
    print["  ", StringPadRight["", 50],
        StringPadLeft["Rust/GPU", 10], "  ",
        StringPadLeft["Native", 10], "   Speedup"];
    print["  ", StringJoin@ConstantArray["-", 85]];
)

(* ============================================================ *)
print["--- Single-Rule Operations ---"];
header[];
Do[
    With[{init = CenterArray[{1}, w]},
        row["Output: rule 30, w=" <> ToString[w] <> " s=" <> ToString[s],
            CellularAutomatonOutput[30, 2, 1, init, s],
            CellularAutomatonOutput[30, 2, 1, init, s, Method -> "Native"],
            200]],
    {w, {21, 101, 501}}, {s, {10, 100}}
];
Do[
    With[{init = CenterArray[{1}, w]},
        row["Evolution: rule 30, w=" <> ToString[w] <> " s=" <> ToString[s],
            CellularAutomatonEvolution[30, 2, 1, init, s],
            CellularAutomatonEvolution[30, 2, 1, init, s, Method -> "Native"],
            200]],
    {w, {21, 101}}, {s, {10, 100}}
];

(* ============================================================ *)
print[""];
print["--- Bulk Search (k=2 r=1, 256 rules) ---"];
header[];

Do[
    With[{init = CenterArray[{1}, w],
          target = Last @ CellularAutomaton[30, CenterArray[{1}, w], s]},
        row["Search (match): w=" <> ToString[w] <> " s=" <> ToString[s],
            CellularAutomatonSearch[{2, 1}, init -> target, s],
            CellularAutomatonSearch[{2, 1}, init -> target, s, Method -> "Native"]]],
    {w, {21, 51}}, {s, {5, 10}}
];

Do[
    With[{init = CenterArray[{1}, w]},
        row["Search (width): w=" <> ToString[w] <> " tw=5 s=" <> ToString[s],
            CellularAutomatonSearch[{2, 1}, init -> 5, s],
            CellularAutomatonSearch[{2, 1}, init -> 5, s, Method -> "Native"]]],
    {w, {21, 51}}, {s, {5, 20}}
];

Do[
    With[{init = CenterArray[{1}, w],
          target = Last @ CellularAutomaton[30, CenterArray[{1}, w], s]},
        row["Test (256 rules): w=" <> ToString[w] <> " s=" <> ToString[s],
            CellularAutomatonTest[Range[0, 255], init -> target, s],
            CellularAutomatonTest[Range[0, 255], init -> target, s, {2, 1}, Method -> "Native"]]],
    {w, {21, 51}}, {s, {1, 10}}
];

Do[
    With[{init = CenterArray[{1}, w]},
        row["OutputTable: w=" <> ToString[w] <> " s=" <> ToString[s],
            CellularAutomatonOutputTable[2, 1, init, s],
            CellularAutomatonOutputTable[2, 1, init, s, Method -> "Native"]]],
    {w, {21, 51, 101}}, {s, {10, 50}}
];

Do[
    With[{init = CenterArray[{1}, w]},
        row["ActiveWidths: w=" <> ToString[w] <> " s=" <> ToString[s],
            CellularAutomatonActiveWidths[init, s],
            CellularAutomatonActiveWidths[init, s, Method -> "Native"]]],
    {w, {21, 51, 101}}, {s, {10, 50}}
];

Do[
    With[{init = CenterArray[{1}, w]},
        row["BoundedWidth: w=" <> ToString[w] <> " s=" <> ToString[s] <> " maxW=5",
            CellularAutomatonBoundedWidthSearch[init, s, 5],
            CellularAutomatonBoundedWidthSearch[init, s, 5, Method -> "Native"]]],
    {w, {21, 51}}, {s, {10, 50}}
];

Do[
    With[{init = CenterArray[{1}, w]},
        row["WidthRatio: w=" <> ToString[w] <> " s=" <> ToString[s] <> " ratio=2",
            CellularAutomatonWidthRatioSearch[{init}, s, 2, {2, 1}],
            CellularAutomatonWidthRatioSearch[{init}, s, 2, {2, 1}, Method -> "Native"]]],
    {w, {21, 51}}, {s, {10, 30}}
];

(* ============================================================ *)
print[""];
print["--- Large Rule Space (k=3 r=1, range scan) ---"];
header[];
Do[
    row["WidthRatio: range 0.." <> ToString[n],
        CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 21]}, 10, 2, {3, 1}, 0 ;; n, 21],
        CellularAutomatonWidthRatioSearch[{CenterArray[{1}, 21]}, 10, 2, {3, 1}, 0 ;; n, 21, Method -> "Native"],
        3],
    {n, {1000, 10000, 100000}}
];

(* ============================================================ *)
print[""];
print["--- NKS Doublers (GPU-only, sequential-scan) ---"];
print["  ", StringPadRight["", 50], StringPadLeft["Time", 10], "  Count"];
print["  ", StringJoin@ConstantArray["-", 68]];
Do[
    With[{t = First @ AbsoluteTiming[
        db = CellularAutomatonWidthRatioSearch[
            Table[Append[ConstantArray[1, n], 2], {n, 0, maxN}], 400, 2, {3, 1}]]},
        print["  ", StringPadRight["n=0.." <> ToString[maxN], 50],
            usStr[1000000. * t], "  ", Length[db]];
    ],
    {maxN, {5, 10, 20}}
];

print["\nDone."];
