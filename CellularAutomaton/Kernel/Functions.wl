BeginPackage["WolframInstitute`CellularAutomaton`"]

ClearAll["WolframInstitute`CellularAutomaton`*", "WolframInstitute`CellularAutomaton`**`*"]

CellularAutomatonRuleCount::usage = "CellularAutomatonRuleCount[k, r] returns the total number of distinct cellular automaton rules for k colors and radius r."

CellularAutomatonOutput::usage = "CellularAutomatonOutput[rule, k, r, init, steps] runs a 1D cellular automaton and returns the final state.
CellularAutomatonOutput[rule, init, steps] uses elementary CA defaults (k=2, r=1)."

CellularAutomatonEvolution::usage = "CellularAutomatonEvolution[rule, k, r, init, steps] returns the full spacetime evolution as a matrix of cell values.
CellularAutomatonEvolution[rule, init, steps] uses elementary CA defaults (k=2, r=1)."

CellularAutomatonSearch::usage = "CellularAutomatonSearch[init, steps, target, {k, r}] finds all CA rules whose evolution from init produces target after steps.
CellularAutomatonSearch[init, steps, width] finds rules where the final active width equals width (an integer).
CellularAutomatonSearch[init, steps, target] uses elementary defaults (k=2, r=1)."

CellularAutomatonOutputTable::usage = "CellularAutomatonOutputTable[k, r, init, steps] computes the output (final state value) for all rules in the (k, r) rule space.
CellularAutomatonOutputTable[init, steps] uses elementary defaults (k=2, r=1)."

CellularAutomatonBoundedWidthSearch::usage = "CellularAutomatonBoundedWidthSearch[init, steps, maxWidth, {k, r}] finds all CA rules where the active region never exceeds maxWidth cells.
CellularAutomatonBoundedWidthSearch[init, steps, maxWidth] uses elementary defaults (k=2, r=1)."

CellularAutomatonActiveWidths::usage = "CellularAutomatonActiveWidths[k, r, init, steps] returns {maxWidth, finalWidth} for each rule in the (k,r) rule space.
CellularAutomatonActiveWidths[init, steps] uses elementary defaults (k=2, r=1)."

CellularAutomatonWidthRatioSearch::usage = "CellularAutomatonWidthRatioSearch[inits, steps, ratio, {k, r}, ruleRange, maxWidth] finds rules where the final active width equals ratio \[Times] input width for ALL initial conditions in inits. Fully parallelized.\nCellularAutomatonWidthRatioSearch[inits, steps, ratio, {k, r}] searches all rules.\nCellularAutomatonWidthRatioSearch[inits, steps, ratio] uses elementary defaults."

CellularAutomatonTest::usage = "CellularAutomatonTest[rule, init, steps, target, {k, r}] returns True if the CA produces target from init.\nCellularAutomatonTest[{rule1, ...}, init, steps, target, {k, r}] returns the subset of rules that pass (parallel)."

CellularAutomatonPlot


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
TestRulesRust := functions["test_rules_wl"]

(* Helper: convert WL list to DataStore for WLL Vec<T> arguments *)
toDS[list_List] := Developer`DataStore @@ list

(* Helper: convert returned DataStore back to WL list *)
fromDS[ds_] := List @@ ds


(* ---- Public API ---- *)

CellularAutomatonRuleCount[k_Integer : 2, r_Integer : 1] :=
    RuleCountRust[k, r]


(* CellularAutomatonOutput: final state *)

CellularAutomatonOutput[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] :=
    fromDS @ RunCAFinalRust[rule, k, r, toDS[init], steps]

CellularAutomatonOutput[rule_Integer, init_List, steps_Integer] :=
    CellularAutomatonOutput[rule, 2, 1, init, steps]

CellularAutomatonOutput[rule_Integer, width_Integer, steps_Integer] := With[{
    init = ConstantArray[0, width]
},
    CellularAutomatonOutput[rule, 2, 1, ReplacePart[init, Ceiling[width / 2] -> 1], steps]
]


(* CellularAutomatonEvolution: full spacetime *)

CellularAutomatonEvolution[rule_Integer, k_Integer, r_Integer, init_List, steps_Integer] :=
    Partition[
        fromDS @ RunCARust[rule, k, r, toDS[init], steps],
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

CellularAutomatonSearch[init_List, steps_Integer, target_List, {k_Integer, r_Integer}] :=
    fromDS @ FindMatchingRulesRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r, toDS[init], steps, toDS[target]]

CellularAutomatonSearch[init_List, steps_Integer, target_List] :=
    CellularAutomatonSearch[init, steps, target, {2, 1}]

CellularAutomatonSearch[init_List, steps_Integer, target_List, {k_Integer, r_Integer}, minRule_Integer ;; maxRule_Integer] :=
    fromDS @ FindMatchingRulesRust[minRule, maxRule, k, r, toDS[init], steps, toDS[target]]


(* CellularAutomatonTest: check init -> target for specific rules *)

CellularAutomatonTest[rule_Integer, init_List, steps_Integer, target_List, {k_Integer, r_Integer}] :=
    CellularAutomatonOutput[rule, k, r, init, steps] === target

CellularAutomatonTest[rule_Integer, init_List, steps_Integer, target_List] :=
    CellularAutomatonTest[rule, init, steps, target, {2, 1}]

CellularAutomatonTest[rules_List, init_List, steps_Integer, target_List, {k_Integer, r_Integer}] :=
    Pick[rules, fromDS @ TestRulesRust[toDS[rules], k, r, toDS[init], steps, toDS[target]], 1]

CellularAutomatonTest[rules_List, init_List, steps_Integer, target_List] :=
    CellularAutomatonTest[rules, init, steps, target, {2, 1}]


(* CellularAutomatonSearch: width-target overloads *)
(* Single init, find rules where final active width = targetWidth *)

CellularAutomatonSearch[init_List, steps_Integer, targetWidth_Integer, {k_Integer, r_Integer}] :=
    fromDS @ FindExactWidthRulesRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r,
        toDS[init], 1, steps, targetWidth]

CellularAutomatonSearch[init_List, steps_Integer, targetWidth_Integer] :=
    CellularAutomatonSearch[init, steps, targetWidth, {2, 1}]

CellularAutomatonSearch[init_List, steps_Integer, targetWidth_Integer, {k_Integer, r_Integer}, minRule_Integer ;; maxRule_Integer] :=
    fromDS @ FindExactWidthRulesRust[minRule, maxRule, k, r,
        toDS[init], 1, steps, targetWidth]

(* Multiple inits, ALL must produce targetWidth *)
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

CellularAutomatonOutputTable[k_Integer, r_Integer, init_List, steps_Integer] :=
    fromDS @ CAOutputTableParallelRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r, toDS[init], steps]

CellularAutomatonOutputTable[init_List, steps_Integer] :=
    CellularAutomatonOutputTable[2, 1, init, steps]

CellularAutomatonOutputTable[k_Integer, r_Integer, init_List, steps_Integer, minRule_Integer ;; maxRule_Integer] :=
    fromDS @ CAOutputTableParallelRust[minRule, maxRule, k, r, toDS[init], steps]


(* CellularAutomatonBoundedWidthSearch: find rules with bounded active width *)

CellularAutomatonBoundedWidthSearch[init_List, steps_Integer, maxWidth_Integer, {k_Integer, r_Integer}] :=
    fromDS @ FindBoundedWidthRulesRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r, toDS[init], steps, maxWidth]

CellularAutomatonBoundedWidthSearch[init_List, steps_Integer, maxWidth_Integer] :=
    CellularAutomatonBoundedWidthSearch[init, steps, maxWidth, {2, 1}]

CellularAutomatonBoundedWidthSearch[init_List, steps_Integer, maxWidth_Integer, {k_Integer, r_Integer}, minRule_Integer ;; maxRule_Integer] :=
    fromDS @ FindBoundedWidthRulesRust[minRule, maxRule, k, r, toDS[init], steps, maxWidth]


(* CellularAutomatonActiveWidths: compute {maxWidth, finalWidth} for each rule *)

CellularAutomatonActiveWidths[k_Integer, r_Integer, init_List, steps_Integer] :=
    Partition[fromDS @ MaxActiveWidthsParallelRust[0, CellularAutomatonRuleCount[k, r] - 1, k, r, toDS[init], steps], 2]

CellularAutomatonActiveWidths[init_List, steps_Integer] :=
    CellularAutomatonActiveWidths[2, 1, init, steps]

CellularAutomatonActiveWidths[k_Integer, r_Integer, init_List, steps_Integer, minRule_Integer ;; maxRule_Integer] :=
    Partition[fromDS @ MaxActiveWidthsParallelRust[minRule, maxRule, k, r, toDS[init], steps], 2]


(* CellularAutomatonWidthRatioSearch: parallel multi-init width ratio search *)

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

(* Specialized fast path: ratio=2, k=3, r=1 → GPU-accelerated doubler search *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, 2, {3, 1}] :=
    fromDS @ FindDoublersK3R1Rust[Length[inits]]

(* Specialized sieve: ratio=2, k=3, r=1 → NKS sequential-scan filter *)
CellularAutomatonWidthRatioSearch[inits:{__List}, steps_Integer, 2, {3, 1}, rules_List] :=
    fromDS @ FilterDoublersK3R1Rust[toDS[rules], Length[inits]]

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


End[]

EndPackage[]
