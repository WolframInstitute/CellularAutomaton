# Width-Doubling 3-Color Cellular Automata

Three-color (k=3, r=1) CA rules that double the width of their input, inspired by
[NKS p. 833](https://www.wolframscience.com/nks/p833--intelligence-in-the-universe/).

## Setup

```wolfram
PacletInstall["https://www.wolframcloud.com/obj/nikm/CellularAutomaton.paclet"]
Needs["WolframInstitute`CellularAutomaton`"]
```

## Parallel Width-Ratio Search

`CellularAutomatonWidthRatioSearch` tests every rule against multiple initial conditions in parallel (Rust + rayon), with bounded-width early exit. No sequential WL filtering needed.

```wolfram
(* Find all k=3 rules in 0..999999 that exactly double width for inputs of width 1 AND width 3 *)
inits = {CenterArray[{1}, 61], CenterArray[{1, 2, 1}, 61]};
AbsoluteTiming[
  doublers = CellularAutomatonWidthRatioSearch[inits, 30, 2, {3, 1}, 0 ;; 999999, 15]
]
```

```wolfram
Length[doublers]
```

### Deeper search

```wolfram
(* Extend to 5M rules *)
AbsoluteTiming[
  doublers5M = CellularAutomatonWidthRatioSearch[inits, 30, 2, {3, 1}, 0 ;; 4999999, 15]
]
Length[doublers5M]
```

### Triple-verified doublers

Adding a width-5 input as a third check eliminates false positives.

```wolfram
inits3 = {CenterArray[{1}, 61], CenterArray[{1, 2, 1}, 61], CenterArray[{1, 2, 1, 2, 1}, 61]};
AbsoluteTiming[
  verified = CellularAutomatonWidthRatioSearch[inits3, 30, 2, {3, 1}, 0 ;; 999999, 15]
]
Length[verified]
```

## Visualizing Discovered Doublers

### Single cell input (width 1 → 2)

```wolfram
(* Use first 6 doublers found *)
show = Take[doublers, UpTo[6]];
Grid[Partition[
  Table[
    Labeled[
      ArrayPlot[CellularAutomaton[{r, 3, 1}, {CenterArray[{1}, 41], 0}, 20],
        ColorRules -> {0 -> White, 1 -> Hue[0.6], 2 -> Hue[0.05]},
        ImageSize -> 160, Frame -> False],
      Style["Rule " <> ToString[r], 10]],
    {r, show}],
  3], Spacings -> 1]
```

### Width-3 input ({1,2,1} → width 6)

```wolfram
Grid[Partition[
  Table[
    Labeled[
      ArrayPlot[CellularAutomaton[{r, 3, 1}, {CenterArray[{1, 2, 1}, 41], 0}, 20],
        ColorRules -> {0 -> White, 1 -> Hue[0.6], 2 -> Hue[0.05]},
        ImageSize -> 160, Frame -> False],
      Style["Rule " <> ToString[r], 10]],
    {r, show}],
  3], Spacings -> 1]
```

### Width-5 input ({1,2,1,2,1} → width 10)

```wolfram
Grid[Partition[
  Table[
    Labeled[
      ArrayPlot[CellularAutomaton[{r, 3, 1}, {CenterArray[{1, 2, 1, 2, 1}, 41], 0}, 20],
        ColorRules -> {0 -> White, 1 -> Hue[0.6], 2 -> Hue[0.05]},
        ImageSize -> 160, Frame -> False],
      Style["Rule " <> ToString[r], 10]],
    {r, show}],
  3], Spacings -> 1]
```

## Detailed View

```wolfram
(* Pick the first doubler for a detailed view *)
rule = First[doublers];
GraphicsColumn[{
  Labeled[
    ArrayPlot[CellularAutomaton[{rule, 3, 1}, {CenterArray[{1}, 81], 0}, 40],
      ColorRules -> {0 -> White, 1 -> Hue[0.6], 2 -> Hue[0.05]},
      ImageSize -> 500],
    Style["Width 1 \[Rule] 2", 14, Bold], Top],
  Labeled[
    ArrayPlot[CellularAutomaton[{rule, 3, 1}, {CenterArray[{1, 2, 1}, 81], 0}, 40],
      ColorRules -> {0 -> White, 1 -> Hue[0.6], 2 -> Hue[0.05]},
      ImageSize -> 500],
    Style["Width 3 \[Rule] 6", 14, Bold], Top],
  Labeled[
    ArrayPlot[CellularAutomaton[{rule, 3, 1}, {CenterArray[{1, 2, 1, 2, 1}, 81], 0}, 40],
      ColorRules -> {0 -> White, 1 -> Hue[0.6], 2 -> Hue[0.05]},
      ImageSize -> 500],
    Style["Width 5 \[Rule] 10", 14, Bold], Top]
}, Spacings -> 1]
```

## Width Progression

Track how the active width evolves step-by-step.

```wolfram
activeWidth[cells_List] := With[{pos = Position[cells, _?(# != 0 &)]},
  If[pos === {}, 0, Last[pos][[1]] - First[pos][[1]] + 1]
];

widthTrace[rule_, init_, nSteps_] := Table[
  activeWidth[CellularAutomaton[{rule, 3, 1}, {init, 0}, t][[-1]]],
  {t, 0, nSteps}
];

ListLinePlot[
  Table[widthTrace[r, CenterArray[{1, 2, 1}, 81], 40], {r, Take[doublers, UpTo[5]]}],
  PlotLegends -> ("Rule " <> ToString[#] & /@ Take[doublers, UpTo[5]]),
  AxesLabel -> {"Step", "Active width"},
  PlotLabel -> "Width evolution from {1,2,1} input",
  PlotStyle -> Thick, ImageSize -> 500]
```

## Searching for Other Ratios

The same function works for any width ratio — tripling, halving, etc.

```wolfram
(* Width-tripling rules *)
inits = {CenterArray[{1}, 61], CenterArray[{1, 2, 1}, 61]};
AbsoluteTiming[
  triplers = CellularAutomatonWidthRatioSearch[inits, 30, 3, {3, 1}, 0 ;; 999999, 20]
]
Length[triplers]
```
