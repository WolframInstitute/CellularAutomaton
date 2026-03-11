BeginPackage["WolframInstitute`CellularAutomaton`"]

ClearAll["WolframInstitute`CellularAutomaton`*", "WolframInstitute`CellularAutomaton`**`*"]

CellularAutomatonRuleCount::usage = "CellularAutomatonRuleCount[k, r] returns the total number of distinct cellular automaton rules for k colors and radius r."

CellularAutomatonOutput::usage = "CellularAutomatonOutput[rule, k, r, init, steps] runs a 1D cellular automaton and returns the final state.
CellularAutomatonOutput[rule, init, steps] uses elementary CA defaults (k=2, r=1)."

CellularAutomatonEvolution::usage = "CellularAutomatonEvolution[rule, k, r, init, steps] returns the full spacetime evolution as a matrix of cell values.
CellularAutomatonEvolution[rule, init, steps] uses elementary CA defaults (k=2, r=1)."

CellularAutomatonSearch::usage = "CellularAutomatonSearch[{k, r}, init \[Rule] target, steps] finds all CA rules matching init\[Rule]target.\nCellularAutomatonSearch[{k, r}, {init1 \[Rule] target1, ...}, steps] incrementally sieves through pairs.\nCellularAutomatonSearch[{{rn1, ...}, k, r}, ...] searches only specified candidate rules.\nCellularAutomatonSearch[{All, k, r}, ...] is equivalent to {k, r}."

CellularAutomatonOutputTable::usage = "CellularAutomatonOutputTable[k, r, init, steps] computes the output (final state value) for all rules in the (k, r) rule space.
CellularAutomatonOutputTable[init, steps] uses elementary defaults (k=2, r=1)."

CellularAutomatonBoundedWidthSearch::usage = "CellularAutomatonBoundedWidthSearch[init, steps, maxWidth, {k, r}] finds all CA rules where the active region never exceeds maxWidth cells.
CellularAutomatonBoundedWidthSearch[init, steps, maxWidth] uses elementary defaults (k=2, r=1)."

CellularAutomatonActiveWidths::usage = "CellularAutomatonActiveWidths[k, r, init, steps] returns {maxWidth, finalWidth} for each rule in the (k,r) rule space.
CellularAutomatonActiveWidths[init, steps] uses elementary defaults (k=2, r=1)."

CellularAutomatonWidthRatioSearch::usage = "CellularAutomatonWidthRatioSearch[inits, steps, ratio, {k, r}, ruleRange, maxWidth] finds rules where the final active width equals ratio \[Times] input width for ALL initial conditions in inits. Fully parallelized.\nCellularAutomatonWidthRatioSearch[inits, steps, ratio, {k, r}] searches all rules.\nCellularAutomatonWidthRatioSearch[inits, steps, ratio] uses elementary defaults."

CellularAutomatonTest::usage = "CellularAutomatonTest[{rule, k, r}, init \[Rule] target, steps] returns True if the CA produces target from init.\nCellularAutomatonTest[rule, init \[Rule] target, steps] uses elementary defaults.\nCellularAutomatonTest[{{r1, k1, s1}, ...}, init \[Rule] target, steps] returns the subset of rule specs that pass.\nCellularAutomatonTest[{rule1, rule2, ...}, init \[Rule] target, steps, {k, r}] tests a list of rule numbers (parallel)."

CellularAutomatonPlot

CARuleIterator::usage = "CARuleIterator[k, r, fixedRules] creates a compiled iterator over CA rule numbers consistent with the given fixed pattern constraints. Use iter[\"Next\"] to yield successive rule numbers."

$CARuleFixedConstraintsK3R1::usage = "$CARuleFixedConstraintsK3R1 is the list of 7 structural fixed constraints for k=3, r=1 CAs with patterns embedded in 0-background."

$CAMethod::usage = "$CAMethod controls the computation backend: \"Rust\" (default, GPU+Rayon) or \"Native\" (pure Wolfram Language)."


Begin["`Private`"];


pacletInstalledQ[paclet_, version_] := AnyTrue[Through[PacletFind[paclet]["Version"]], ResourceFunction["VersionOrder"][#, version] <= 0 &]

functions := functions = (
	If[ ! pacletInstalledQ["ExternalEvaluate", "38.0.1"],
		PacletInstall["ExternalEvaluate"]
	];
	If[ ! pacletInstalledQ["PacletExtensions", "40.0.0"],
		PacletInstall["https://www.wolframcloud.com/obj/nikm/PacletExtensions.paclet"]
	];
	Needs["ExtensionCargo`"];
	Replace[
		ExtensionCargo`CargoLoad[
			PacletObject["WolframInstitute/CellularAutomaton"],
			"Functions"
		],
		Except[_ ? AssociationQ] :> Replace[
			ExtensionCargo`CargoBuild[PacletObject["WolframInstitute/CellularAutomaton"]], {
				f : Except[{__ ? FileExistsQ}] :> Function @ Function @ Failure["CargoBuildError", <|
							"MessageTemplate" -> "Cargo build failed",
							"Return" -> f
						|>],
				files_ :> Replace[
					ExtensionCargo`CargoLoad[files, "Functions"],
					f : Except[_ ? AssociationQ] :>
						Function @ Function @ Failure["CargoLoadError", <|
							"MessageTemplate" -> "Cargo load failed",
							"Return" -> f
						|>]
				]
			}
		]
	]
) // Replace[{
	functions_ ? AssociationQ :>
		Association @ KeyValueMap[
			#1 -> Composition[
				Replace[LibraryFunctionError[error_, code_] :>
					Failure["RustError", <|
						"MessageTemplate" -> "Rust error: `` (``)",
						"MessageParameters" -> {error, code},
					"Error" -> error, "ErrorCode" -> code, "Function" -> #1
				|>]
			],
			#2
		] &,
		functions
	]
}
]

(* Bind Rust functions *)
RunCARust := functions["run_ca_wl"]
RunCAFinalRust := functions["run_ca_final_wl"]
CAOutputTableParallelRust := functions["ca_output_table_parallel_wl"]
FindMatchingRulesRust := functions["find_matching_rules_wl"]
RuleCountRust := functions["rule_count_wl"]
CAEvolutionTableParallelRust := functions["ca_evolution_table_parallel_wl"]
FindBoundedWidthRulesRust := functions["find_bounded_width_rules_wl"]
MaxActiveWidthsParallelRust := functions["max_active_widths_parallel_wl"]
FindWidthRatioRulesRust := functions["find_width_ratio_rules_wl"]
FindExactWidthRulesRust := functions["find_exact_width_rules_wl"]
FindDoublersK3R1Rust := functions["find_doublers_k3r1_wl"]
FilterWidthRatioRulesRust := functions["filter_width_ratio_rules_wl"]
FilterDoublersK3R1Rust := functions["filter_doublers_k3r1_wl"]
FilterDoublersK3R1RangeRust := functions["filter_doublers_k3r1_range_wl"]
TestRulesRust := functions["test_rules_wl"]
RunCAFinalBigIntRust := functions["run_ca_final_bigint_wl"]
RunCABigIntRust := functions["run_ca_bigint_wl"]
TestRulesBigIntRust := functions["test_rules_bigint_wl"]
RandomSearchRust := functions["random_search_wl"]
RandomSieveRust := functions["random_sieve_wl"]
SearchFreeRust := functions["search_free_wl"]

(* Helper: convert WL list to DataStore for WLL Vec<T> arguments *)
toDS[list_List] := Developer`DataStore @@ list

(* Helper: convert returned DataStore back to WL list *)
fromDS[ds_] := List @@ ds

(* ---- Method dispatch ---- *)

(* Global method switch: "Rust" (default) or "Native" *)
$CAMethod = "Rust";

(* ---- Native WL implementations using built-in CellularAutomaton ---- *)
(* These use periodic boundary on a zero-padded tape to match Rust's fixed-width behavior *)

(* Core: evolve and return final state *)
nativeCAFinal[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] :=
    Last @ CellularAutomaton[{rule, k, r}, init, steps]

(* Core: evolve and return full spacetime *)
nativeCAEvolution[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] :=
    CellularAutomaton[{rule, k, r}, init, steps]

(* Core: find matching rules by brute-force Select *)
nativeCASearch[minRule_Integer, maxRule_Integer, k_Integer, r_Integer,
               init_List, steps_Integer, target_List] :=
    Select[Range[minRule, maxRule],
        Last[CellularAutomaton[{#, k, r}, init, steps]] === target &]

(* Core: output table for range of rules *)
nativeOutputTable[minRule_Integer, maxRule_Integer, k_Integer, r_Integer,
                  init_List, steps_Integer] :=
    Table[
        FromDigits[Reverse @ Last @ CellularAutomaton[{rule, k, r}, init, steps], k],
        {rule, minRule, maxRule}
    ]

(* Core: bounded width search *)
nativeBoundedSearch[minRule_Integer, maxRule_Integer, k_Integer, r_Integer,
                    init_List, steps_Integer, maxWidth_Integer] :=
    Select[Range[minRule, maxRule],
        Function[rule,
            With[{evo = CellularAutomaton[{rule, k, r}, init, steps]},
                AllTrue[evo, nativeActiveWidth[#] <= maxWidth &]
            ]
        ]
    ]

(* Helper: active width = extent of nonzero cells *)
nativeActiveWidth[state_List] :=
    With[{nz = Flatten @ Position[state, _?(# != 0 &)]},
        If[nz === {}, 0, Last[nz] - First[nz] + 1]
    ]

(* Core: active widths for range of rules *)
nativeActiveWidths[minRule_Integer, maxRule_Integer, k_Integer, r_Integer,
                   init_List, steps_Integer] :=
    Table[
        With[{evo = CellularAutomaton[{rule, k, r}, init, steps]},
            {Max[nativeActiveWidth /@ evo], nativeActiveWidth[Last[evo]]}
        ],
        {rule, minRule, maxRule}
    ]

(* Core: width ratio search *)
nativeWidthRatioSearch[minRule_Integer, maxRule_Integer, k_Integer, r_Integer,
                       initials_List, steps_Integer,
                       ratioNum_Integer, ratioDen_Integer, maxWidth_Integer] :=
    Select[Range[minRule, maxRule],
        Function[rule,
            AllTrue[initials,
                Function[init,
                    With[{evo = CellularAutomaton[{rule, k, r}, init, steps]},
                        AllTrue[evo, nativeActiveWidth[#] <= maxWidth &] &&
                        With[{iw = nativeActiveWidth[init],
                              fw = nativeActiveWidth[Last[evo]]},
                            fw * ratioDen == iw * ratioNum
                        ]
                    ]
                ]
            ]
        ]
    ]

(* Core: test rules against init->target *)
nativeTestRules[rules_List, k_Integer, r_Integer, init_List, steps_Integer, target_List] :=
    Boole[Last[CellularAutomaton[{#, k, r}, init, steps]] === target] & /@ rules

(* Core: filter width ratio rules from candidate list *)
nativeFilterWidthRatio[rules_List, k_Integer, r_Integer,
                       initials_List, steps_Integer,
                       ratioNum_Integer, ratioDen_Integer, maxWidth_Integer] :=
    Select[rules,
        Function[rule,
            AllTrue[initials,
                Function[init,
                    With[{evo = CellularAutomaton[{rule, k, r}, init, steps]},
                        AllTrue[evo, nativeActiveWidth[#] <= maxWidth &] &&
                        With[{iw = nativeActiveWidth[init],
                              fw = nativeActiveWidth[Last[evo]]},
                            fw * ratioDen == iw * ratioNum
                        ]
                    ]
                ]
            ]
        ]
    ]

(* Core: exact width search *)
nativeExactWidthSearch[minRule_Integer, maxRule_Integer, k_Integer, r_Integer,
                       initials_List, steps_Integer, targetWidth_Integer] :=
    Select[Range[minRule, maxRule],
        Function[rule,
            AllTrue[initials,
                nativeActiveWidth[Last @ CellularAutomaton[{rule, k, r}, #, steps]] == targetWidth &
            ]
        ]
    ]


(* ---- Public API ---- *)

CellularAutomatonRuleCount[k_Integer : 2, r_Integer : 1] :=
    k ^ (k ^ (2 r + 1))


(* CellularAutomatonOutput: final state *)

$MaxRustRuleNumber = 2^64 - 1; (* u64 max *)

(* Native path *)
CellularAutomatonOutput[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] /;
    $CAMethod === "Native" :=
    nativeCAFinal[rule, k, r, init, steps]

(* Rust path *)
CellularAutomatonOutput[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] /; rule <= $MaxRustRuleNumber :=
    fromDS @ RunCAFinalRust[rule, k, r, toDS[init], steps]

(* BigInt path: pass rule as string to Rust *)
CellularAutomatonOutput[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] :=
    fromDS @ RunCAFinalBigIntRust[ToString[rule], k, r, toDS[init], steps]

CellularAutomatonOutput[rule_Integer, init_List, steps_Integer] :=
    CellularAutomatonOutput[rule, 2, 1, init, steps]

CellularAutomatonOutput[rule_Integer, width_Integer, steps_Integer] := With[{
    init = ConstantArray[0, width]
},
    CellularAutomatonOutput[rule, 2, 1, ReplacePart[init, Ceiling[width / 2] -> 1], steps]
]


(* CellularAutomatonEvolution: full spacetime *)

(* Native path *)
CellularAutomatonEvolution[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] /;
    $CAMethod === "Native" :=
    nativeCAEvolution[rule, k, r, init, steps]

(* Rust path *)
CellularAutomatonEvolution[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] /; rule <= $MaxRustRuleNumber :=
    Partition[
        fromDS @ RunCARust[rule, k, r, toDS[init], steps],
        Length[init]
    ]

(* BigInt path for evolution *)
CellularAutomatonEvolution[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] :=
    Partition[
        fromDS @ RunCABigIntRust[ToString[rule], k, r, toDS[init], steps],
        Length[init]
    ]

CellularAutomatonEvolution[rule_Integer, init_List, steps_Integer] :=
    CellularAutomatonEvolution[rule, 2, 1, init, steps]

CellularAutomatonEvolution[rule_Integer, width_Integer, steps_Integer] := With[{
    init = ConstantArray[0, width]
},
    CellularAutomatonEvolution[rule, 2, 1, ReplacePart[init, Ceiling[width / 2] -> 1], steps]
]


(* CellularAutomatonSearch: find matching rules *)

(* === Rulespec normalization === *)

(* {All, k, r} is alias for {k, r} *)
CellularAutomatonSearch[{All, k_Integer, r_Integer}, args___] :=
    CellularAutomatonSearch[{k, r}, args]

(* === Core: {k, r} full-space search === *)

(* Single target — Native path *)
CellularAutomatonSearch[{k_Integer, r_Integer}, Rule[init_List, target_List], steps_Integer] /;
    $CAMethod === "Native" :=
    nativeCASearch[0, CellularAutomatonRuleCount[k, r] - 1, k, r, init, steps, target]

CellularAutomatonSearch[{k_Integer, r_Integer}, Rule[init_List, target_List], steps_Integer,
    minRule_Integer ;; maxRule_Integer] /; $CAMethod === "Native" :=
    nativeCASearch[minRule, maxRule, k, r, init, steps, target]

(* Width target — Native path *)
CellularAutomatonSearch[{k_Integer, r_Integer}, Rule[init_List, targetWidth_Integer], steps_Integer] /;
    $CAMethod === "Native" :=
    nativeExactWidthSearch[0, CellularAutomatonRuleCount[k, r] - 1, k, r, {init}, steps, targetWidth]

(* Single target — Rust *)
CellularAutomatonSearch[{k_Integer, r_Integer}, Rule[init_List, target_List], steps_Integer] :=
    fromDS @ FindMatchingRulesRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r, toDS[init], steps, toDS[target]]

CellularAutomatonSearch[{k_Integer, r_Integer}, Rule[init_List, target_List], steps_Integer, minRule_Integer ;; maxRule_Integer] :=
    fromDS @ FindMatchingRulesRust[minRule, maxRule, k, r, toDS[init], steps, toDS[target]]

(* Width target *)
CellularAutomatonSearch[{k_Integer, r_Integer}, Rule[init_List, targetWidth_Integer], steps_Integer] :=
    fromDS @ FindExactWidthRulesRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r,
        toDS[init], 1, steps, targetWidth]

CellularAutomatonSearch[{k_Integer, r_Integer}, Rule[init_List, targetWidth_Integer], steps_Integer, minRule_Integer ;; maxRule_Integer] :=
    fromDS @ FindExactWidthRulesRust[minRule, maxRule, k, r,
        toDS[init], 1, steps, targetWidth]

(* Multiple inits -> width target *)
CellularAutomatonSearch[{k_Integer, r_Integer}, Rule[inits:{__List}, targetWidth_Integer], steps_Integer] :=
    With[{flat = Flatten[inits], n = Length[inits]},
        fromDS @ FindExactWidthRulesRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r,
            toDS[flat], n, steps, targetWidth]
    ]

(* === Candidate list rulespec: {{rn1, ...}, k, r} === *)

(* Span → range of rule numbers *)
CellularAutomatonSearch[{span_Span, k_Integer, r_Integer}, target_, steps_Integer] :=
    CellularAutomatonSearch[{Range @@ span, k, r}, target, steps]

(* seed -> n: use Rust-native random generation (GPU-accelerated on macOS) *)
CellularAutomatonSearch[{Rule[seed_, n_Integer], k_Integer, r_Integer}, Rule[init_List, target_List], steps_Integer] :=
    With[{padWidth = Max[Length[init], Length[target]] + 2 * steps + 2},
        With[{paddedInit = padCenter[init, padWidth, k],
              paddedTarget = padCenter[target, padWidth, k]},
            ToExpression /@ fromDS @ RandomSearchRust[n, seed, k, r, toDS[paddedInit], steps, toDS[paddedTarget]]
        ]
    ]

(* seed -> n, multi-pair sieve: first pair via RandomSearch, rest via CellularAutomatonTest *)
CellularAutomatonSearch[{Rule[seed_, n_Integer], k_Integer, r_Integer}, pairs:{__Rule}, steps_Integer] :=
    With[{candidates = CellularAutomatonSearch[{seed -> n, k, r}, First[pairs], steps]},
        If[Length[pairs] === 1, candidates,
            Fold[CellularAutomatonTest[#1, #2, steps, {k, r}] &, candidates, Rest[pairs]]
        ]
    ]

(* Single target: filter candidates *)
CellularAutomatonSearch[{candidates_List, k_Integer, r_Integer}, Rule[init_List, target_List], steps_Integer] :=
    CellularAutomatonTest[candidates, init -> target, steps, {k, r}]

(* === Multi-pair sieve: {init1->target1, init2->target2, ...} === *)

(* Helper: detect if all pairs are width-doublers *)
isDoublerPattern[pairs:{__Rule}] :=
    AllTrue[pairs, Length[Last[#]] === 2 * Length[First[#]] &]

(* k=3, r=1 doubler optimization: use NKS sequential-scan GPU kernel directly *)
(* NOTE: This finds NKS-style doublers (sequential-scan update), not standard parallel CA *)
CellularAutomatonSearch[{3, 1}, pairs:{__Rule}, steps_Integer] /; isDoublerPattern[pairs] :=
    With[{maxN = Max[Length[First[#]] & /@ pairs]},
        With[{gpuCandidates = fromDS @ FindDoublersK3R1Rust[Min[maxN, 12]]},
            If[maxN <= 12,
                gpuCandidates,
                (* GPU searched 1..12; refine with tests 13..maxN only *)
                fromDS @ FilterDoublersK3R1RangeRust[toDS[gpuCandidates], 13, maxN]
            ]
        ]
    ]

(* General multi-pair GPU search using free-digit parameterization *)
(* Search smallest pair first (tiny tape = fast), then filter through rest *)
CellularAutomatonSearch[{k_Integer, r_Integer}, pairs:{__Rule}, steps_Integer] /;
        k <= 4 && r == 1 && Length[pairs] > 1 :=
    Module[{tableSize, fixedDigits, freePositions, fixedPositions,
            sortedPairs, firstPair, padWidth, paddedInit, paddedTarget, candidates},
        tableSize = k^(2 r + 1);
        (* Structural constraints for k=3 r=1: 7 fixed, 20 free → 3^20 = 3.5B *)
        fixedDigits = If[k == 3,
            {{0, 0}, {1, 0}, {2, 0}, {4, 1}, {9, 0}, {12, 1}, {13, 1}},
            {{0, 0}}
        ];
        fixedPositions = fixedDigits[[All, 1]];
        freePositions = Complement[Range[0, tableSize - 1], fixedPositions];
        
        (* Sort pairs by tape size needed (smallest first) *)
        sortedPairs = SortBy[pairs, Max[Length[First[#]], Length[Last[#]]] &];
        firstPair = First[sortedPairs];
        
        (* Pad based on pattern size, not steps — convergence happens quickly,
           patterns reaching tape edge fail target check correctly *)
        padWidth = Max[Length[First[firstPair]], Length[Last[firstPair]]] * 4 + 2;
        paddedInit = padCenter[First[firstPair], padWidth, k];
        paddedTarget = padCenter[Last[firstPair], padWidth, k];
        
        candidates = fromDS @ SearchFreeRust[
            toDS[Flatten[fixedDigits]],
            toDS[freePositions],
            k, r,
            toDS[paddedInit], toDS[paddedTarget],
            padWidth, steps, 1
        ];
        
        (* Filter candidates through remaining pairs *)
        If[Length[candidates] > 0 && Length[sortedPairs] > 1,
            CellularAutomatonSearch[{candidates, k, r}, Rest[sortedPairs], steps],
            candidates
        ]
    ]

(* {k, r} with pair list: search all rules on first pair, sieve rest *)
CellularAutomatonSearch[{k_Integer, r_Integer}, pairs:{__Rule}, steps_Integer] :=
    With[{initial = CellularAutomatonSearch[{k, r}, First[pairs], steps]},
        If[Length[pairs] === 1, initial,
            CellularAutomatonSearch[{initial, k, r}, Rest[pairs], steps]
        ]
    ]

(* Candidate list with pair list: Fold through pairs *)
CellularAutomatonSearch[{candidates_List, k_Integer, r_Integer}, pairs:{__Rule}, steps_Integer] :=
    Fold[
        CellularAutomatonTest[#1, #2, steps, {k, r}] &,
        candidates,
        pairs
    ]

(* === Elementary shorthands === *)

CellularAutomatonSearch[Rule[init_List, target_List], steps_Integer] :=
    CellularAutomatonSearch[{2, 1}, init -> target, steps]

CellularAutomatonSearch[Rule[init_List, targetWidth_Integer], steps_Integer] :=
    CellularAutomatonSearch[{2, 1}, init -> targetWidth, steps]

CellularAutomatonSearch[pairs:{__Rule}, steps_Integer] :=
    CellularAutomatonSearch[{2, 1}, pairs, steps]

(* === Legacy positional overloads === *)

CellularAutomatonSearch[init_List, steps_Integer, target_List, {k_Integer, r_Integer}] :=
    CellularAutomatonSearch[{k, r}, init -> target, steps]

CellularAutomatonSearch[init_List, steps_Integer, target_List] :=
    CellularAutomatonSearch[{2, 1}, init -> target, steps]

CellularAutomatonSearch[init_List, steps_Integer, target_List, {k_Integer, r_Integer}, minRule_Integer ;; maxRule_Integer] :=
    CellularAutomatonSearch[{k, r}, init -> target, steps, minRule ;; maxRule]


(* CellularAutomatonTest: check init -> target for specific rules *)

(* Auto-pad helper: embed pattern centered in a zero-padded tape *)
padCenter[pattern_List, width_Integer, k_Integer] :=
    With[{pad = Ceiling[(width - Length[pattern]) / 2]},
        Join[ConstantArray[0, pad], pattern, ConstantArray[0, width - Length[pattern] - pad]]
    ]

(* Extract active (nonzero) region from CA output *)
activeRegion[state_List] :=
    With[{nz = Flatten @ Position[state, _?(# != 0 &)]},
        If[nz === {}, {},
            state[[First[nz] ;; Last[nz]]]
        ]
    ]

(* Core test: handles same-length and different-length init/target *)
caTestSingle[rule_Integer, k_Integer, r_Integer, init_List, target_List, steps_Integer] :=
    If[Length[init] === Length[target],
        (* Same length: direct comparison *)
        CellularAutomatonOutput[rule, k, r, init, steps] === target,
        (* Different length: use WL CellularAutomaton with auto-expansion, check active region *)
        With[{output = CellularAutomaton[{rule, k, r}, {init, 0}, steps]},
            If[ListQ[output],
                activeRegion[Last[output]] === target,
                False
            ]
        ]
    ]

(* Single rulespec {rule, k, r} with init -> target *)
CellularAutomatonTest[{rule_Integer, k_Integer, r_Integer}, Rule[init_List, target_List], steps_Integer] :=
    caTestSingle[rule, k, r, init, target, steps]

(* Elementary shorthand: bare rule number *)
CellularAutomatonTest[rule_Integer, Rule[init_List, target_List], steps_Integer] :=
    CellularAutomatonTest[{rule, 2, 1}, init -> target, steps]

(* List of rulespecs {{r1, k1, s1}, ...} — filter to passing specs *)
CellularAutomatonTest[specs : {{_Integer, _Integer, _Integer} ..}, Rule[init_List, target_List], steps_Integer] :=
    Select[specs, CellularAutomatonTest[#, init -> target, steps] &]

(* Empty candidate list — short-circuit *)
CellularAutomatonTest[{}, Rule[_List, _List], _Integer, {_Integer, _Integer}] := {}

(* Native path: batch test *)
CellularAutomatonTest[rules : {__Integer}, Rule[init_List, target_List], steps_Integer, {k_Integer, r_Integer}] /;
        $CAMethod === "Native" :=
    With[{padWidth = Max[Length[init], Length[target]] + 2 * steps + 2},
        With[{paddedInit = padCenter[init, padWidth, k],
              paddedTarget = padCenter[target, padWidth, k]},
            Pick[rules, nativeTestRules[rules, k, r, paddedInit, steps, paddedTarget], 1]
        ]
    ]

(* List of rule numbers with explicit {k, r} — GPU-parallel filter *)
CellularAutomatonTest[rules : {__Integer}, Rule[init_List, target_List], steps_Integer, {k_Integer, r_Integer}] /;
        Max[rules] <= $MaxRustRuleNumber :=
    With[{padWidth = Max[Length[init], Length[target]] + 2 * steps + 2},
        With[{paddedInit = padCenter[init, padWidth, k],
              paddedTarget = padCenter[target, padWidth, k]},
            Pick[rules, fromDS @ TestRulesRust[toDS[rules], k, r, toDS[paddedInit], steps, toDS[paddedTarget]], 1]
        ]
    ]

(* BigInt path: pass rule numbers as strings to Rust *)
CellularAutomatonTest[rules : {__Integer}, Rule[init_List, target_List], steps_Integer, {k_Integer, r_Integer}] :=
    With[{padWidth = Max[Length[init], Length[target]] + 2 * steps + 2},
        With[{paddedInit = padCenter[init, padWidth, k],
              paddedTarget = padCenter[target, padWidth, k]},
            Pick[rules,
                fromDS @ TestRulesBigIntRust[
                    toDS[ToString /@ rules], k, r, toDS[paddedInit], steps, toDS[paddedTarget]], 1]
        ]
    ]

(* List of rule numbers, elementary default *)
CellularAutomatonTest[rules : {__Integer}, Rule[init_List, target_List], steps_Integer] :=
    CellularAutomatonTest[rules, init -> target, steps, {2, 1}]


(* Legacy width-target overloads *)

CellularAutomatonSearch[init_List, steps_Integer, targetWidth_Integer, {k_Integer, r_Integer}] :=
    CellularAutomatonSearch[{k, r}, init -> targetWidth, steps]

CellularAutomatonSearch[init_List, steps_Integer, targetWidth_Integer] :=
    CellularAutomatonSearch[{2, 1}, init -> targetWidth, steps]

CellularAutomatonSearch[init_List, steps_Integer, targetWidth_Integer, {k_Integer, r_Integer}, minRule_Integer ;; maxRule_Integer] :=
    CellularAutomatonSearch[{k, r}, init -> targetWidth, steps, minRule ;; maxRule]

CellularAutomatonSearch[inits:{__List}, steps_Integer, targetWidth_Integer, {k_Integer, r_Integer},
        minRule_Integer ;; maxRule_Integer] :=
    With[{flat = Flatten[inits], n = Length[inits]},
        fromDS @ FindExactWidthRulesRust[minRule, maxRule, k, r,
            toDS[flat], n, steps, targetWidth]
    ]

CellularAutomatonSearch[inits:{__List}, steps_Integer, targetWidth_Integer, {k_Integer, r_Integer}] :=
    CellularAutomatonSearch[inits, steps, targetWidth, {k, r},
        0 ;; CellularAutomatonRuleCount[k, r] - 1]


(* CellularAutomatonOutputTable: output for all rules *)

(* Native path *)
CellularAutomatonOutputTable[k_Integer, r_Integer, init_List, steps_Integer] /;
    $CAMethod === "Native" :=
    nativeOutputTable[0, CellularAutomatonRuleCount[k, r] - 1, k, r, init, steps]

CellularAutomatonOutputTable[k_Integer, r_Integer, init_List, steps_Integer,
    minRule_Integer ;; maxRule_Integer] /; $CAMethod === "Native" :=
    nativeOutputTable[minRule, maxRule, k, r, init, steps]

(* Rust path *)
CellularAutomatonOutputTable[k_Integer, r_Integer, init_List, steps_Integer] :=
    fromDS @ CAOutputTableParallelRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r, toDS[init], steps]

CellularAutomatonOutputTable[init_List, steps_Integer] :=
    CellularAutomatonOutputTable[2, 1, init, steps]

CellularAutomatonOutputTable[k_Integer, r_Integer, init_List, steps_Integer, minRule_Integer ;; maxRule_Integer] :=
    fromDS @ CAOutputTableParallelRust[minRule, maxRule, k, r, toDS[init], steps]


(* CellularAutomatonBoundedWidthSearch: find rules with bounded active width *)

(* Native path *)
CellularAutomatonBoundedWidthSearch[init_List, steps_Integer, maxWidth_Integer, {k_Integer, r_Integer}] /;
    $CAMethod === "Native" :=
    nativeBoundedSearch[0, CellularAutomatonRuleCount[k, r] - 1, k, r, init, steps, maxWidth]

CellularAutomatonBoundedWidthSearch[init_List, steps_Integer, maxWidth_Integer, {k_Integer, r_Integer},
    minRule_Integer ;; maxRule_Integer] /; $CAMethod === "Native" :=
    nativeBoundedSearch[minRule, maxRule, k, r, init, steps, maxWidth]

(* Rust path *)
CellularAutomatonBoundedWidthSearch[init_List, steps_Integer, maxWidth_Integer, {k_Integer, r_Integer}] :=
    fromDS @ FindBoundedWidthRulesRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r, toDS[init], steps, maxWidth]

CellularAutomatonBoundedWidthSearch[init_List, steps_Integer, maxWidth_Integer] :=
    CellularAutomatonBoundedWidthSearch[init, steps, maxWidth, {2, 1}]

CellularAutomatonBoundedWidthSearch[init_List, steps_Integer, maxWidth_Integer, {k_Integer, r_Integer}, minRule_Integer ;; maxRule_Integer] :=
    fromDS @ FindBoundedWidthRulesRust[minRule, maxRule, k, r, toDS[init], steps, maxWidth]


(* CellularAutomatonActiveWidths: compute {maxWidth, finalWidth} for each rule *)

(* Native path *)
CellularAutomatonActiveWidths[k_Integer, r_Integer, init_List, steps_Integer] /;
    $CAMethod === "Native" :=
    nativeActiveWidths[0, CellularAutomatonRuleCount[k, r] - 1, k, r, init, steps]

CellularAutomatonActiveWidths[k_Integer, r_Integer, init_List, steps_Integer,
    minRule_Integer ;; maxRule_Integer] /; $CAMethod === "Native" :=
    nativeActiveWidths[minRule, maxRule, k, r, init, steps]

(* Rust path *)
CellularAutomatonActiveWidths[k_Integer, r_Integer, init_List, steps_Integer] :=
    Partition[fromDS @ MaxActiveWidthsParallelRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r, toDS[init], steps], 2]

CellularAutomatonActiveWidths[init_List, steps_Integer] :=
    CellularAutomatonActiveWidths[2, 1, init, steps]

CellularAutomatonActiveWidths[k_Integer, r_Integer, init_List, steps_Integer, minRule_Integer ;; maxRule_Integer] :=
    Partition[fromDS @ MaxActiveWidthsParallelRust[minRule, maxRule, k, r, toDS[init], steps], 2]


(* CellularAutomatonWidthRatioSearch: parallel multi-init width ratio search *)

(* Native path: full search *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, ratio_?NumericQ, {k_Integer, r_Integer},
        minRule_Integer ;; maxRule_Integer, maxWidth_Integer] /; $CAMethod === "Native" :=
    With[{rat = Rationalize[ratio]},
        nativeWidthRatioSearch[minRule, maxRule, k, r, inits, steps,
            Numerator[rat], Denominator[rat], maxWidth]
    ]

(* Native path: sieve candidate list *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, ratio_?NumericQ, {k_Integer, r_Integer},
        rules_List] /; $CAMethod === "Native" :=
    With[{rat = Rationalize[ratio]},
        nativeFilterWidthRatio[rules, k, r, inits, steps,
            Numerator[rat], Denominator[rat], Max[Length /@ inits]]
    ]

(* Rust path: full search *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, ratio_?NumericQ, {k_Integer, r_Integer},
        minRule_Integer ;; maxRule_Integer, maxWidth_Integer] :=
    With[{rat = Rationalize[ratio], flat = Flatten[inits], n = Length[inits]},
        fromDS @ FindWidthRatioRulesRust[minRule, maxRule, k, r, toDS[flat], n, steps,
            Numerator[rat], Denominator[rat], maxWidth]
    ]

CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, ratio_, {k_Integer, r_Integer},
        minRule_Integer ;; maxRule_Integer] :=
    CellularAutomatonWidthRatioSearch[inits, steps, ratio, {k, r}, minRule ;; maxRule,
        Max[Length /@ inits]]

(* Helper: check if init is NKS-standard doubler pattern {1,...,1,2} *)
isNKSDoublerPattern[init_List] := init === Append[ConstantArray[1, Length[init] - 1], 2]

(* Specialized fast path: ratio=2, k=3, r=1 with NKS-standard patterns *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, 2, {3, 1}] /; AllTrue[inits, isNKSDoublerPattern] :=
    With[{maxN = Max[Length /@ inits]},
        With[{gpuCandidates = fromDS @ FindDoublersK3R1Rust[Min[maxN, 12]]},
            If[maxN <= 12,
                gpuCandidates,
                (* GPU searched 1..12; refine with tests 13..maxN only *)
                fromDS @ FilterDoublersK3R1RangeRust[toDS[gpuCandidates], 13, maxN]
            ]
        ]
    ]

(* Non-NKS inits, ratio=2, k=3, r=1: use NKS doubler as pre-filter, then verify with actual inits *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, 2, {3, 1}] :=
    With[{candidates = fromDS @ FindDoublersK3R1Rust[Min[Max[Length /@ inits], 12]]},
        CellularAutomatonWidthRatioSearch[inits, steps, 2, {3, 1}, candidates]
    ]

(* Specialized sieve: ratio=2, k=3, r=1, NKS patterns *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, 2, {3, 1}, rules_List] /; AllTrue[inits, isNKSDoublerPattern] :=
    fromDS @ FilterDoublersK3R1RangeRust[toDS[rules], 1, Max[Length /@ inits]]

(* Specialized sieve: ratio=2, k=3, r=1, non-NKS patterns — use general filter *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, 2, {3, 1}, rules_List] :=
    With[{flat = Flatten[inits], n = Length[inits]},
        fromDS @ FilterWidthRatioRulesRust[toDS[rules], 3, 1, toDS[flat], n, steps,
            2, 1, Max[Length /@ inits]]
    ]

CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, ratio_, {k_Integer, r_Integer}] :=
    CellularAutomatonWidthRatioSearch[inits, steps, ratio, {k, r},
        0 ;; CellularAutomatonRuleCount[k, r] - 1]

CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, ratio_] :=
    CellularAutomatonWidthRatioSearch[inits, steps, ratio, {2, 1}]

(* Sieve overload: filter a provided list of candidate rules *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, ratio_?NumericQ, {k_Integer, r_Integer},
        rules_List] :=
    With[{rat = Rationalize[ratio], flat = Flatten[inits], n = Length[inits]},
        fromDS @ FilterWidthRatioRulesRust[toDS[rules], k, r, toDS[flat], n, steps,
            Numerator[rat], Denominator[rat], Max[Length /@ inits]]
    ]

CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, ratio_?NumericQ, rules_List] :=
    CellularAutomatonWidthRatioSearch[inits, steps, ratio, {2, 1}, rules]

(* === Rule iterator === *)

(* CARuleIterator[k, r, fixedRules] creates a compiled iterator over all rule numbers
   consistent with the given fixed pattern constraints.
   fixedRules: list of {left_, center_, right_} -> val pattern rules
   Returns: object supporting ["Next"] and ["Send", ruleNumber] *)
CARuleIterator[k_Integer, r_Integer, fixedRules_List] :=
    Module[{tableSize, neighborhoods, fixed, freePos, numFree,
            fixedContribution, freeMultipliers, iterFn, obj, currentIter, total},
        tableSize = k^(2 r + 1);
        neighborhoods = Tuples[Range[0, k - 1], 2 r + 1];
        
        (* Expand pattern rules with _ to concrete {idx -> val} *)
        fixed = Association @@ Flatten[
            Table[
                With[{lhs = First[rule], rhs = Last[rule]},
                    Thread[
                        (FromDigits[#, k] & /@ 
                            Select[neighborhoods, MatchQ[#, lhs] &]) -> rhs
                    ]
                ],
                {rule, fixedRules}
            ]
        ];
        
        freePos = Complement[Range[0, tableSize - 1], Keys[fixed]];
        numFree = Length[freePos];
        total = k^numFree;
        
        (* Precompute: fixed contribution + positional multipliers for free digits *)
        fixedContribution = Total[KeyValueMap[#2 * k^#1 &, fixed]];
        freeMultipliers = k^freePos;
        
        (* Compile coroutine: iterates base-k free-digit space from startIdx *)
        With[{fc = fixedContribution, fm = freeMultipliers, nf = numFree, kk = k},
            iterFn = FunctionCompile[
                IncrementalFunction[
                    Function[{Typed[startIdx, "MachineInteger"], Typed[endIdx, "MachineInteger"]},
                        Module[{idx, j, val, ruleNum, digit},
                            Do[
                                ruleNum = fc;
                                val = idx;
                                Do[
                                    digit = Mod[val, kk];
                                    ruleNum = ruleNum + digit * fm[[j]];
                                    val = Quotient[val, kk],
                                    {j, nf}
                                ];
                                IncrementalYield[ruleNum],
                                {idx, startIdx, endIdx - 1}
                            ]
                        ]
                    ]
                ]
            ]
        ];
        
        (* WL wrapper: "Send" reverse-maps rule number to free-digit index *)
        currentIter = iterFn[0, total];
        
        obj["Next"] := currentIter["Next"];
        obj["Send", ruleNum_Integer] := (
            (* Reverse-map: extract free digits from rule number, compute index *)
            Module[{digits, freeDigits, freeIdx},
                digits = IntegerDigits[ruleNum, k, tableSize];
                digits = Reverse[digits]; (* little-endian: position i at index i+1 *)
                freeDigits = digits[[freePos + 1]];
                freeIdx = FromDigits[Reverse[freeDigits], k];
                currentIter = iterFn[freeIdx, total];
                currentIter["Next"]
            ]
        );
        obj["Total"] := total;
        obj["NumFree"] := numFree;
        
        obj
    ]

(* Default k=3 r=1 fixed constraints: structural symmetry from NKS analysis *)
$CARuleFixedConstraintsK3R1 = {
    {0, 0, _} -> 0,   (* background/boundary stays 0 *)
    {1, 0, 0} -> 0,   (* right boundary stays 0 *)
    {0, 1, 1} -> 1,   (* all-1 interior preserved *)
    {1, 1, 0} -> 1,   (* all-1 right edge preserved *)
    {1, 1, 1} -> 1    (* all-1 interior preserved *)
};


End[]

EndPackage[]
