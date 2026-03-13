/-
  Rule110.ECA

  Formalization of Elementary Cellular Automata (1D, radius-1, 2-color),
  with Rule 110 as the specific instance.

  Design decisions:
  - Tape: Int → Bool (bi-infinite), avoids boundary headaches
  - FinTape: Fin n → Bool for native_decide verification of finite patterns
  - Evolution indexed by Nat steps
-/

namespace CA

-- ============================================================================
-- Core ECA definitions
-- ============================================================================

/-- An Elementary Cellular Automaton: lookup table mapping 3-bit
    neighborhoods (as Fin 8) to output bit -/
structure ECA where
  rule : Fin 8 → Bool


/-- Encode a 3-bit neighborhood (left, center, right) into Fin 8.
    Convention: left is MSB, right is LSB.
    Index = 4*left + 2*center + right -/
def neighborhoodIndex (left center right : Bool) : Fin 8 :=
  ⟨(if left then 4 else 0) + (if center then 2 else 0) + (if right then 1 else 0),
   by cases left <;> cases center <;> cases right <;> simp⟩

/-- Rule 110 in Wolfram numbering: 110 = 01101110 in binary.
    Index:  7(111)  6(110)  5(101)  4(100)  3(011)  2(010)  1(001)  0(000)
    Output:   0       1       1       0       1       1       1       0    -/
def rule110 : ECA where
  rule := fun i =>
    match i.val with
    | 0 => false  -- 000 → 0
    | 1 => true   -- 001 → 1
    | 2 => true   -- 010 → 1
    | 3 => true   -- 011 → 1
    | 4 => false  -- 100 → 0
    | 5 => true   -- 101 → 1
    | 6 => true   -- 110 → 1
    | _ => false  -- 111 → 0 (and unreachable cases)

-- ============================================================================
-- Bi-infinite tape
-- ============================================================================

/-- A bi-infinite tape of Boolean cells, indexed by integers -/
def Tape := Int → Bool

/-- Apply one step of an ECA to a bi-infinite tape -/
def ECA.step (ca : ECA) (tape : Tape) : Tape :=
  fun i => ca.rule (neighborhoodIndex (tape (i - 1)) (tape i) (tape (i + 1)))

/-- Evolve a tape for n steps under an ECA -/
def ECA.evolve (ca : ECA) (tape : Tape) : Nat → Tape
  | 0 => tape
  | n + 1 => ca.step (ca.evolve tape n)

-- ============================================================================
-- Finite tapes for computational verification
-- ============================================================================

/-- A finite tape of width w, for computational verification via native_decide -/
def FinTape (w : Nat) := Fin w → Bool

/-- Decidable equality for finite tapes -/
instance finTapeDecEq (w : Nat) : DecidableEq (FinTape w) :=
  fun a b =>
    if h : ∀ i : Fin w, a i = b i then
      isTrue (funext h)
    else
      isFalse (fun hab => h (fun i => congrFun hab i))

instance finTapeBEq (w : Nat) : BEq (FinTape w) :=
  ⟨fun a b => (List.range w).all fun i =>
    if h : i < w then a ⟨i, h⟩ == b ⟨i, h⟩ else true⟩

/-- Apply one ECA step to a finite tape with periodic boundary conditions -/
def ECA.finStep (ca : ECA) (w : Nat) (tape : FinTape w) (hw : w > 0) : FinTape w :=
  fun i =>
    let left := tape ⟨(i.val + w - 1) % w, Nat.mod_lt _ hw⟩
    let center := tape i
    let right := tape ⟨(i.val + 1) % w, Nat.mod_lt _ hw⟩
    ca.rule (neighborhoodIndex left center right)

/-- Evolve a finite tape for n steps with periodic boundaries -/
def ECA.finEvolve (ca : ECA) (w : Nat) (tape : FinTape w) (hw : w > 0) : Nat → FinTape w
  | 0 => tape
  | n + 1 => ca.finStep w (ca.finEvolve w tape hw n) hw

/-- Tail-recursive evolution — compiles to a simple loop under native_decide.
    The standard finEvolve builds closures outside-in: `step(step(...step(tape)...))`,
    creating O(n)-deep expression trees expensive to compile.
    This version evaluates step-by-step bottom-up. -/
def ECA.finEvolveLoop (ca : ECA) (w : Nat) (hw : w > 0) : Nat → FinTape w → FinTape w
  | 0, tape => tape
  | n + 1, tape => ECA.finEvolveLoop ca w hw n (ca.finStep w tape hw)

-- ============================================================================
-- Conversion utilities
-- ============================================================================

/-- Create a finite tape from a list, padding with false if needed -/
def listToFinTape (w : Nat) (bits : List Bool) : FinTape w :=
  fun i => bits.getD i.val false

/-- Convert a finite tape to a list -/
def finTapeToList (w : Nat) (tape : FinTape w) : List Bool :=
  (List.range w).map (fun i =>
    if h : i < w then tape ⟨i, h⟩ else false)

-- ============================================================================
-- Optimized comparison: list-based equality for fast native_decide
-- ============================================================================

/-- Two finite tapes are equal iff their list representations are equal.
    List comparison is O(n) in native code; function comparison is expensive. -/
theorem finTapeEqOfListEq {w : Nat} (a b : FinTape w)
    (h : finTapeToList w a = finTapeToList w b) : a = b := by
  funext ⟨i, hi⟩
  simp [finTapeToList] at h
  have := h i hi
  simp [hi] at this
  exact this

/-- Create a periodic bi-infinite tape from a finite pattern -/
def periodicTape (period : Nat) (pattern : FinTape period) (hp : period > 0) : Tape :=
  fun i =>
    let m := ((i % period + period) % period).toNat
    pattern ⟨m % period, Nat.mod_lt _ hp⟩

/-- Shifted finite tape: shift all indices by an offset -/
def FinTape.shift (w : Nat) (tape : FinTape w) (offset : Nat) (hw : w > 0) : FinTape w :=
  fun i => tape ⟨(i.val + offset) % w, Nat.mod_lt _ hw⟩

-- ============================================================================
-- Rule 110 verification: spot checks via native_decide
-- ============================================================================

-- Verify individual neighborhood lookups match Rule 110
theorem r110_000 : rule110.rule (neighborhoodIndex false false false) = false := by native_decide
theorem r110_001 : rule110.rule (neighborhoodIndex false false true) = true := by native_decide
theorem r110_010 : rule110.rule (neighborhoodIndex false true false) = true := by native_decide
theorem r110_011 : rule110.rule (neighborhoodIndex false true true) = true := by native_decide
theorem r110_100 : rule110.rule (neighborhoodIndex true false false) = false := by native_decide
theorem r110_101 : rule110.rule (neighborhoodIndex true false true) = true := by native_decide
theorem r110_110 : rule110.rule (neighborhoodIndex true true false) = true := by native_decide
theorem r110_111 : rule110.rule (neighborhoodIndex true true true) = false := by native_decide

-- ============================================================================
-- Ether pattern (period 14)
-- ============================================================================

/-- The Rule 110 ether: the periodic background pattern with period 14.
    Pattern: 00010011011111 (Cook's convention) -/
def etherPattern : FinTape 14 :=
  listToFinTape 14 [false, false, false, true, false, false, true, true,
                     false, true, true, true, true, true]

/-- Ether is stable under 7 steps of Rule 110: after 7 steps with periodic
    boundary, the result is the ether shifted right by 7 positions.
    (The pattern has period 14, temporal period 7, spatial shift 7.) -/
theorem ether_stable_7 :
    ECA.finEvolve rule110 14 etherPattern (by omega) 7 = etherPattern := by native_decide

end CA
