/-
  Rule110.Glider

  Layer 4: Glider infrastructure for the Rule 110 universality proof.

  Formalizes the periodic structures ("gliders") that propagate on the
  Rule 110 ether background. Each glider is verified by decide
  on a width-84 periodic tape (6 copies of the 14-cell ether pattern).

  Critical discovery: gliders must be placed at ether phase 13 (0-indexed)
  for the perturbation to propagate cleanly. At other phases, the diff
  between evolved perturbed and evolved unperturbed tapes grows.

  The verification approach:
  1. Create an 84-cell periodic ether tape
  2. Place the glider patch at ether phase 13
  3. Evolve both perturbed and unperturbed tapes for P steps
  4. Verify the diff between them is exactly the shifted perturbation

  Cook's classification:
    A: velocity +2/3 (right), period 3 — data carrier
    C: velocity 0 (stationary), period 7 — wall/barrier
    B,D,E: TODO — require wider patches or different discovery method
-/

import CA.ECA

namespace CA

-- ============================================================================
-- Verification infrastructure
-- ============================================================================

/-- Ether-filled tape of width 84 (= 6 × 14 ether copies).
    Large enough for glider propagation without boundary effects. -/
def etherTape84 : FinTape 84 :=
  fun i => etherPattern ⟨i.val % 14, Nat.mod_lt _ (by omega)⟩

/-- Evolve the pure ether tape for n steps (reference baseline) -/
def evolvedEther84 (n : Nat) : FinTape 84 :=
  ECA.finEvolve rule110 84 etherTape84 (by omega) n

-- ============================================================================
-- Glider A: velocity +2/3 (right), temporal period 3
-- ============================================================================

/-- A-glider: 8-cell patch placed at 0-indexed position 27 (ether phase 13).
    Overwrites ether cells with [1,0,1,1,1,0,1,1].
    Creates exactly 3 cells that differ from ether at 0-indexed positions
    {29, 30, 33} (phases {1,2,5} mod 14), all flipped from 0 to 1. -/
def gliderA_tape : FinTape 84 :=
  listToFinTape 84
    [false, false, false, true, false, false, true, true, false, true, true, true, true, true,
     false, false, false, true, false, false, true, true, false, true, true, true, true, true,
     -- patch starts at position 27 (phase 13):
     false, true, true, true, false, true, true, true,
     -- position 35:
     false, true, true, true, true, true,
     false, false, false, true, false, false, true, true, false, true, true, true, true, true,
     false, false, false, true, false, false, true, true, false, true, true, true, true, true,
     false, false, false, true, false, false, true, true, false, true, true, true, true, true]

/-- Expected tape after evolving glider A for 3 steps.
    The perturbation has shifted 2 positions to the right.
    Diff from evolved ether at 0-indexed positions {31, 32, 35}. -/
def gliderA_expected3 : FinTape 84 :=
  listToFinTape 84
    [true, true, false, false, false, true, false, false, true, true, false, true, true, true,
     true, true, false, false, false, true, false, false, true, true, false, true, true, true,
     true, true,
     -- shifted perturbation at position 31:
     false, true, true, true, false, true, true, true,
     -- position 39:
     false, true, true, true, true, true,
     false, false, false, true, false, false, true, true, false, true, true, true, true, true,
     false, false, false, true, false, false, true, true, false, true, true, true, true, true,
     false, false, false, true, false, false, true, true, false, true, true, true]

/-- **A-glider periodicity theorem**: After 3 steps of Rule 110, the tape with
    an A-glider at position 27 evolves to equal a specific expected tape where
    the perturbation has shifted 2 positions rightward.
    Verified computationally on a width-84 periodic tape. -/
theorem gliderA_period3_shift2 :
    ECA.finEvolveLoop rule110 84 (by omega) 3 gliderA_tape = gliderA_expected3 := by native_decide

-- ============================================================================
-- Glider C: velocity 0 (stationary), temporal period 7
-- ============================================================================

/-- C-glider: 10-cell patch placed at 0-indexed position 27 (ether phase 13).
    Overwrites ether cells with [1,1,1,1,0,0,0,1,1,1].
    Perturbation is stationary — after 7 steps (one ether period) the diff
    is at the same positions. -/
def gliderC_tape : FinTape 84 :=
  fun i =>
    -- Patch at positions 27..36
    if i.val ≥ 27 ∧ i.val < 37 then
      [true, true, true, true, false, false, false, true, true, true].getD (i.val - 27)
        (etherPattern ⟨i.val % 14, Nat.mod_lt _ (by omega)⟩)
    else
      etherPattern ⟨i.val % 14, Nat.mod_lt _ (by omega)⟩

/-- **C-glider stationarity theorem**: After 7 steps of Rule 110 (one ether
    period), the tape with a C-glider at position 27 returns to itself.
    The perturbation does not move — it is a stationary structure on the ether.
    Verified on a width-84 periodic tape. -/
theorem gliderC_period7_shift0 :
    ECA.finEvolveLoop rule110 84 (by omega) 7 gliderC_tape = gliderC_tape := by native_decide

-- ============================================================================
-- Glider B: temporal period 14, stationary in absolute frame
-- Width 70 (5 ether periods) for manageable native_decide time
-- ============================================================================

/-- B-glider: 10-cell patch at 1-indexed position 28.
    After 14 steps, the tape returns to itself. -/
def gliderB_tape : FinTape 70 :=
  listToFinTape 70
    [false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, true, true, true, false, false, false, true, true, true, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true]

/-- **B-glider periodicity**: After 14 steps the tape returns to itself. -/
theorem gliderB_period14 :
    ECA.finEvolveLoop rule110 70 (by omega) 14 gliderB_tape = gliderB_tape := by
  apply finTapeEqOfListEq; native_decide

-- ============================================================================
-- Glider D: temporal period 5, shift +1
-- ============================================================================

/-- D-glider: 8-cell patch at 1-indexed position 35. After 5 steps,
    the perturbation shifts 1 position rightward. -/
def gliderD_tape : FinTape 70 :=
  listToFinTape 70
    [false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, false, true, true, true, false, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true]

/-- Expected D-glider tape after 5 steps -/
def gliderD_expected5 : FinTape 70 :=
  listToFinTape 70
    [true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, true, true, false, false, false, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false]

/-- **D-glider shift**: After 5 steps the perturbation shifts +1. -/
theorem gliderD_period5_shift1 :
    ECA.finEvolveLoop rule110 70 (by omega) 5 gliderD_tape = gliderD_expected5 := by
  apply finTapeEqOfListEq; native_decide

-- ============================================================================
-- Glider E: temporal period 15, shift −1
-- ============================================================================

/-- E-glider: 6-cell patch at 1-indexed position 42. After 15 steps,
    the perturbation shifts 1 position leftward. -/
def gliderE_tape : FinTape 70 :=
  listToFinTape 70
    [false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, true, true, false, true, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true]

/-- Expected E-glider tape after 15 steps -/
def gliderE_expected15 : FinTape 70 :=
  listToFinTape 70
    [false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true, true, true, false, false, false, true, true, true, true, true, false, false, false, true, false, false, true, true, false, true, true, true, true, true, false, false, false, true]

/-- **E-glider shift**: After 15 steps the perturbation shifts −1. -/
theorem gliderE_period15_shift_neg1 :
    ECA.finEvolveLoop rule110 70 (by omega) 15 gliderE_tape = gliderE_expected15 := by
  apply finTapeEqOfListEq; native_decide

-- ============================================================================
-- Glider specifications (for future universality proof)
-- ============================================================================

/-- Classification of a glider type -/
structure GliderSpec where
  name : String
  /-- Temporal period (ECA steps per cycle) -/
  period : Nat
  /-- Spatial shift per period (positive = right) -/
  shift : Int

def gliderA_spec : GliderSpec := ⟨"A", 3, 2⟩
def gliderB_spec : GliderSpec := ⟨"B", 14, 0⟩    -- stationary in absolute frame
def gliderC_spec : GliderSpec := ⟨"C", 7, 0⟩
def gliderD_spec : GliderSpec := ⟨"D", 5, 1⟩
def gliderE_spec : GliderSpec := ⟨"E", 15, -1⟩

end CA
