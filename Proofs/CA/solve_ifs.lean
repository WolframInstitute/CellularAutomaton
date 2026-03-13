import Lean

open Lean Elab Tactic Meta

elab "solve_ifs" : tactic => do
  let goal ← getMainGoal
  -- this is complex.
