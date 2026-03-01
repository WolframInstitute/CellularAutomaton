# Width-Doubling 3-Color Cellular Automata

Three-color (k=3, r=1) CA rules that double the width of their input pattern,
from [NKS p. 833](https://www.wolframscience.com/nks/p833--intelligence-in-the-universe/).

These are 4277 rules (out of 7,625,597,484,987) found by exhaustive search where
the CA evolves a finite input pattern into a doubled-width output pattern. The number
of steps scales roughly linearly with input width.

## Setup

```wolfram
PacletInstall["https://www.wolframcloud.com/obj/nikm/CellularAutomaton.paclet", ForceVersionInstall -> True]
Get["WolframInstitute`CellularAutomaton`"]
```

## The Doubling Rules Dataset

The Wolfram Data Repository provides a curated subset of these rules.

```wolfram
doublingRules = ResourceData["Three-Color Cellular Automaton Rules that Double Their Input"];
Length[doublingRules]
```

## Visualizing Doubling Rules

### Single cell input

Each rule evolves a single non-zero cell. The pattern grows obliquely,
with the non-trivial output region encoding a doubled-width pattern.

```wolfram
show = Take[doublingRules, 12];
Grid[Partition[
  Table[
    Labeled[
      ArrayPlot[CellularAutomaton[{r, 3, 1}, {{1}, 0}, {30, All}],
        ColorRules -> {0 -> White, 1 -> GrayLevel[0.3], 2 -> GrayLevel[0.65]},
        ImageSize -> 140, Frame -> False, PixelConstrained -> True],
      Style[r, 8]],
    {r, show}],
  4], Spacings -> 1]
```

### Multi-cell input

```wolfram
Grid[Partition[
  Table[
    Labeled[
      ArrayPlot[CellularAutomaton[{r, 3, 1}, {{1, 2, 1}, 0}, {30, All}],
        ColorRules -> {0 -> White, 1 -> GrayLevel[0.3], 2 -> GrayLevel[0.65]},
        ImageSize -> 140, Frame -> False, PixelConstrained -> True],
      Style[r, 8]],
    {r, Take[doublingRules, 12]}],
  4], Spacings -> 1]
```

## How Doubling Works

The input pattern sits at the top. As the CA evolves, the active region expands
and eventually stabilizes. The non-trivial portion of the spacetime has width 2× the input.

```wolfram
rule = First[doublingRules];
GraphicsRow[
  Table[
    Labeled[
      ArrayPlot[CellularAutomaton[{rule, 3, 1}, {in, 0}, {50, All}],
        ColorRules -> {0 -> White, 1 -> GrayLevel[0.3], 2 -> GrayLevel[0.65]},
        ImageSize -> 200, Frame -> False],
      Column[{Style["Rule " <> ToString[rule], 10],
        Style["Input: " <> ToString[in], 9]}, Alignment -> Center], Top],
    {in, {{1}, {1, 2}, {1, 2, 1}, {1, 2, 1, 2, 1}}}],
  Spacings -> 1]
```

## Active Width Analysis

```wolfram
activeWidth[cells_List] := With[{pos = Position[cells, _?(# != 0 &)]},
  If[pos === {}, 0, Last[pos][[1]] - First[pos][[1]] + 1]];

(* For each rule, compute the final active width from single cell input *)
widths = Table[
  activeWidth[CellularAutomaton[{r, 3, 1}, {{1}, 0}, 50]],
  {r, doublingRules}];
Histogram[widths, PlotLabel -> "Final active width from single cell (50 steps)",
  AxesLabel -> {"Width", "Count"}, ImageSize -> 500]
```

## Comparing Doubling Styles

Different rules achieve doubling through different internal dynamics.

```wolfram
(* Pick 6 visually distinct rules *)
samples = doublingRules[[{1, 10, 50, 100, 150, 199}]];
Grid[Partition[
  Table[
    Labeled[
      ArrayPlot[CellularAutomaton[{r, 3, 1}, {{1, 2, 1, 2, 1}, 0}, {80, All}],
        ColorRules -> {0 -> White, 1 -> GrayLevel[0.3], 2 -> GrayLevel[0.65]},
        ImageSize -> 250, Frame -> False],
      Style["Rule " <> ToString[r], 10]],
    {r, samples}],
  3], Spacings -> 1]
```

## Searching for New Doublers with CASearch

Our Rust-powered search can scan for rules with bounded active width.
This is a necessary (but not sufficient) condition for doubling.

```wolfram
(* Find bounded-width k=3 rules in a range *)
AbsoluteTiming[
  bounded = CellularAutomatonBoundedWidthSearch[
    CenterArray[{1}, 61], 30, 9, {3, 1}, 0 ;; 999999];
  Length[bounded]
]
```

```wolfram
(* Check overlap with known doublers *)
knownInRange = Select[doublingRules, # <= 999999 &];
Print["Known doublers in range: ", Length[knownInRange]];
Print["Bounded-width rules found: ", Length[bounded]];
Print["Overlap: ", Length[Intersection[bounded, knownInRange]]];
```
