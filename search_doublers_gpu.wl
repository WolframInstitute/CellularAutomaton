(* GPU Width-Doubling Rule Search *)
(* Launches GPU binary, reads results, and provides analysis *)
(* Usage: wolframscript -f search_doublers_gpu.wl *)

$dir = DirectoryName[$InputFileName];
$binary = FileNameJoin[{$dir, "target", "release", "gpu_benchmark"}];
$gpuDir = FileNameJoin[{$dir, "gpu_search"}];
$resultsFile = FileNameJoin[{$dir, "doublers_found.txt"}];

(* Build if needed *)
If[!FileExistsQ[$binary],
    Print["Building GPU search binary..."];
    Run["cd " <> $gpuDir <> " && cargo build --release 2>&1"];
    If[!FileExistsQ[$binary],
        Print["ERROR: Build failed. Ensure Rust and Metal SDK are available."];
        Exit[1]
    ];
    Print["Build complete."];
];

(* Run search *)
Print["Running GPU width-doubling search..."];
Print["Search space: 3^19 = ", 3^19, " (8 fixed digit constraints)"];
Print["Tests: {1^n, 2} → {1^(2n+2)} for n=0..6 (7 tests)"];
Print[""];

runResult = RunProcess[{$binary}, "StandardOutput"];
Print[runResult];

(* Read results *)
If[!FileExistsQ[$resultsFile],
    Print["ERROR: No results file found."];
    Exit[1]
];

rules = ToExpression /@ Select[
    StringSplit[Import[$resultsFile, "Text"], "\n"],
    StringLength[#] > 0 &
];
Print["\n=== RESULTS ==="];
Print["Total width-doubling rules found: ", Length[rules]];
Print["Rule number range: [", Min[rules], ", ", Max[rules], "]"];

(* Known NKS doublers cross-check *)
nksDoublers = {1920106431, 5407067979, 50663695617, 50749793433,
    144892613592, 238949703351, 272425762404, 272684219877,
    493427573370, 837428508144, 1380347975457, 3385253974896,
    4510289298924, 5616661823460, 5616790963623, 5794444905633,
    6424448193765, 6463950373854, 6463950380415, 6863658437061,
    6937134280020, 7050911966469, 7066073564883};
Print["\nKnown NKS doublers found: ",
    Length[Intersection[rules, nksDoublers]], "/", Length[nksDoublers]];

(* Save as WL expression *)
wlFile = FileNameJoin[{$dir, "width_doubling_rules.wl"}];
Export[wlFile, rules, "WL"];
Print["Rules saved to: ", wlFile];
