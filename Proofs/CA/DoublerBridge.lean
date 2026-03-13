import CA.Doubler
import CA.DoublerTrans

namespace CA

-- ============================================================================
-- ListTape: decidable tape for native_decide proofs of chaotic wave
-- ============================================================================

structure LTape where
  data : List Nat
  offset : Int
  deriving DecidableEq, BEq, Repr

def LTape.get (lt : LTape) (i : Int) : Nat :=
  let idx := i - lt.offset
  if h : 0 ≤ idx ∧ idx < lt.data.length then
    lt.data.get ⟨idx.toNat, by omega⟩
  else 0

def LTape.toTape (lt : LTape) : Tape := fun i => lt.get i

def LTape.step (lt : LTape) : LTape where
  data := (List.range (lt.data.length + 2)).map fun (idx : Nat) =>
    let i : Int := lt.offset + (idx : Int) - 1
    R (lt.get (i - 1) * 9 + lt.get i * 3 + lt.get (i + 1))
  offset := lt.offset - 1

def LTape.evolve (lt : LTape) : Nat → LTape
  | 0 => lt
  | t + 1 => (lt.evolve t).step

-- ============================================================================
-- Bridge theorems: LTape ↔ infinite Tape
-- ============================================================================

/-- LTape step agrees with infinite tape step.
    Both compute R(get(i-1)*9 + get(i)*3 + get(i+1)) at each position. -/
theorem LTape.step_toTape (lt : LTape) :
    lt.step.toTape = CA.step lt.toTape := by sorry

/-- LTape evolve agrees with infinite tape evolve -/
theorem LTape.evolve_toTape (lt : LTape) (t : Nat) :
    (lt.evolve t).toTape = CA.evolve lt.toTape t := by
  induction t with
  | zero => rfl
  | succ t ih =>
    show (lt.evolve t).step.toTape = CA.step (CA.evolve lt.toTape t)
    rw [← ih, LTape.step_toTape]

-- ============================================================================
-- S_22/S1 LTape representations
-- ============================================================================

def S_22_lt (n : Nat) : LTape where
  data := List.replicate (n - 2) 1 ++ [2, 1, 1, 1, 2]
  offset := 0

theorem S_22_lt_toTape (n : Nat) (hn : n ≥ 3) :
    (S_22_lt n).toTape = S_22 n 0 := by sorry

-- ============================================================================
-- Chaotic wave: computational proofs for specific n values
-- ============================================================================

set_option maxHeartbeats 4000000 in
theorem chaotic_wave_3_ltape :
    let r := (LTape.mk [1, 2, 1, 1, 1, 2] 0).evolve 24
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧
    r.get (-1) = 0 ∧ r.get 10 = 0 := by native_decide

set_option maxHeartbeats 4000000 in
theorem chaotic_wave_4_ltape :
    let r := (LTape.mk [1, 1, 2, 1, 1, 1, 2] 0).evolve 29
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧
    r.get (-1) = 0 ∧ r.get 12 = 0 := by native_decide

set_option maxHeartbeats 4624000 in
theorem chaotic_wave_5_ltape :
    let r := (LTape.mk [1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 34
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧
    r.get (-1) = 0 ∧ r.get 14 = 0 := by native_decide

set_option maxHeartbeats 6084000 in
theorem chaotic_wave_6_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 39
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧
    r.get (-1) = 0 ∧ r.get 16 = 0 := by native_decide

set_option maxHeartbeats 9216000 in
theorem chaotic_wave_7_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 48
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧
    r.get (-1) = 0 ∧ r.get 18 = 0 := by native_decide

set_option maxHeartbeats 11236000 in
theorem chaotic_wave_8_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 53
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧ r.get 18 = 1 ∧ r.get 19 = 1 ∧
    r.get (-1) = 0 ∧ r.get 20 = 0 := by native_decide

set_option maxHeartbeats 12996000 in
theorem chaotic_wave_9_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 57
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧ r.get 18 = 1 ∧ r.get 19 = 1 ∧ r.get 20 = 1 ∧ r.get 21 = 1 ∧
    r.get (-1) = 0 ∧ r.get 22 = 0 := by native_decide

set_option maxHeartbeats 20736000 in
theorem chaotic_wave_10_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 72
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧ r.get 18 = 1 ∧ r.get 19 = 1 ∧ r.get 20 = 1 ∧ r.get 21 = 1 ∧ r.get 22 = 1 ∧ r.get 23 = 1 ∧
    r.get (-1) = 0 ∧ r.get 24 = 0 := by native_decide

set_option maxHeartbeats 22500000 in
theorem chaotic_wave_11_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 75
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧ r.get 18 = 1 ∧ r.get 19 = 1 ∧ r.get 20 = 1 ∧ r.get 21 = 1 ∧ r.get 22 = 1 ∧ r.get 23 = 1 ∧ r.get 24 = 1 ∧ r.get 25 = 1 ∧
    r.get (-1) = 0 ∧ r.get 26 = 0 := by native_decide

set_option maxHeartbeats 27556000 in
theorem chaotic_wave_12_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 83
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧ r.get 18 = 1 ∧ r.get 19 = 1 ∧ r.get 20 = 1 ∧ r.get 21 = 1 ∧ r.get 22 = 1 ∧ r.get 23 = 1 ∧ r.get 24 = 1 ∧ r.get 25 = 1 ∧ r.get 26 = 1 ∧ r.get 27 = 1 ∧
    r.get (-1) = 0 ∧ r.get 28 = 0 := by native_decide

set_option maxHeartbeats 28900000 in
theorem chaotic_wave_13_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 85
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧ r.get 18 = 1 ∧ r.get 19 = 1 ∧ r.get 20 = 1 ∧ r.get 21 = 1 ∧ r.get 22 = 1 ∧ r.get 23 = 1 ∧ r.get 24 = 1 ∧ r.get 25 = 1 ∧ r.get 26 = 1 ∧ r.get 27 = 1 ∧ r.get 28 = 1 ∧ r.get 29 = 1 ∧
    r.get (-1) = 0 ∧ r.get 30 = 0 := by native_decide

set_option maxHeartbeats 35344000 in
theorem chaotic_wave_14_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 94
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧ r.get 18 = 1 ∧ r.get 19 = 1 ∧ r.get 20 = 1 ∧ r.get 21 = 1 ∧ r.get 22 = 1 ∧ r.get 23 = 1 ∧ r.get 24 = 1 ∧ r.get 25 = 1 ∧ r.get 26 = 1 ∧ r.get 27 = 1 ∧ r.get 28 = 1 ∧ r.get 29 = 1 ∧ r.get 30 = 1 ∧ r.get 31 = 1 ∧
    r.get (-1) = 0 ∧ r.get 32 = 0 := by native_decide

set_option maxHeartbeats 42436000 in
theorem chaotic_wave_15_ltape :
    let r := (LTape.mk [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 2] 0).evolve 103
    r.get 0 = 1 ∧ r.get 1 = 1 ∧ r.get 2 = 1 ∧ r.get 3 = 1 ∧ r.get 4 = 1 ∧ r.get 5 = 1 ∧ r.get 6 = 1 ∧ r.get 7 = 1 ∧ r.get 8 = 1 ∧ r.get 9 = 1 ∧ r.get 10 = 1 ∧ r.get 11 = 1 ∧ r.get 12 = 1 ∧ r.get 13 = 1 ∧ r.get 14 = 1 ∧ r.get 15 = 1 ∧ r.get 16 = 1 ∧ r.get 17 = 1 ∧ r.get 18 = 1 ∧ r.get 19 = 1 ∧ r.get 20 = 1 ∧ r.get 21 = 1 ∧ r.get 22 = 1 ∧ r.get 23 = 1 ∧ r.get 24 = 1 ∧ r.get 25 = 1 ∧ r.get 26 = 1 ∧ r.get 27 = 1 ∧ r.get 28 = 1 ∧ r.get 29 = 1 ∧ r.get 30 = 1 ∧ r.get 31 = 1 ∧ r.get 32 = 1 ∧ r.get 33 = 1 ∧
    r.get (-1) = 0 ∧ r.get 34 = 0 := by native_decide

end CA
