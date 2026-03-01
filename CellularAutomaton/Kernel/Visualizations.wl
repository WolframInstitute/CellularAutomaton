(* ::Package:: *)

BeginPackage["WolframInstitute`CellularAutomaton`"]

CellularAutomatonPlot::usage = 
  "CellularAutomatonPlot[rule, init, steps, opts] generates a visualization of the evolution of a 1D cellular automaton.
   - rule: an integer encoding the CA rule.
   - init: a list of cell values or an integer width (single cell in center).
   - steps: the number of steps to simulate.
   Options:
   - \"Width\": override the width of the CA (default: from init).
   - ImageSize: size of the image (default: Automatic).
   CellularAutomatonPlot[rule, width, steps] uses a single cell in the center of a tape of given width."


Begin["`Private`"]


Options[CellularAutomatonPlot] = Join[{
    "Width" -> Automatic,
    "ColorRules" -> Automatic,
    ImageSize -> Automatic
},
    Options[ArrayPlot]
];

CellularAutomatonPlot[
    rule_Integer,
    init_List,
    steps_Integer,
    opts : OptionsPattern[]
] := With[{
    evolution = CellularAutomatonEvolution[rule, init, steps],
    k = Max[init] + 1
},
    ArrayPlot[evolution,
        FilterRules[{opts}, Options[ArrayPlot]],
        ColorRules -> Replace[OptionValue["ColorRules"], Automatic :> defaultColorRules[k]],
        Mesh -> True,
        MeshStyle -> GrayLevel[0.85],
        Frame -> False,
        ImageSize -> OptionValue[ImageSize],
        PlotLabel -> StringTemplate["Rule ``"][rule]
    ]
]

CellularAutomatonPlot[
    rule_Integer,
    width_Integer,
    steps_Integer,
    opts : OptionsPattern[]
] := With[{
    init = ReplacePart[ConstantArray[0, width], Ceiling[width / 2] -> 1]
},
    CellularAutomatonPlot[rule, init, steps, opts]
]

CellularAutomatonPlot[
    {rule_Integer, k_Integer, r_Integer},
    init_List,
    steps_Integer,
    opts : OptionsPattern[]
] := With[{
    evolution = CellularAutomatonEvolution[rule, k, r, init, steps]
},
    ArrayPlot[evolution,
        FilterRules[{opts}, Options[ArrayPlot]],
        ColorRules -> Replace[OptionValue["ColorRules"], Automatic :> defaultColorRules[k]],
        Mesh -> True,
        MeshStyle -> GrayLevel[0.85],
        Frame -> False,
        ImageSize -> OptionValue[ImageSize],
        PlotLabel -> StringTemplate["Rule `` (k=``, r=``)"][rule, k, r]
    ]
]


defaultColorRules[2] := {0 -> White, 1 -> Black}

defaultColorRules[k_] := Table[
    i -> ColorData["Rainbow"][i / (k - 1)],
    {i, 0, k - 1}
]


End[]

EndPackage[]
