/-
  Rule110.Doubler
-/

namespace CA

def R (idx : Nat) : Nat :=
  match idx with
  |  0 => 0 |  1 => 0 |  2 => 0  |  3 => 2 |  4 => 1 |  5 => 2
  |  6 => 1 |  7 => 1 |  8 => 2  |  9 => 0 | 10 => 0 | 11 => 0
  | 12 => 1 | 13 => 1 | 14 => 2  | 15 => 1 | 16 => 2 | 17 => 1
  | 18 => 1 | 19 => 1 | 20 => 0  | 21 => 2 | 22 => 0 | 23 => 2
  | 24 => 1 | 25 => 1 | _  => 2

def Tape := Int → Nat
def step (tape : Tape) : Tape := fun i => R (tape (i - 1) * 9 + tape i * 3 + tape (i + 1))

def evolve (tape : Tape) : Nat → Tape
  | 0 => tape
  | t + 1 => step (evolve tape t)

def stepV (w : Nat) (hw : w > 0) (tape : Vector Nat w) : Vector Nat w :=
  Vector.ofFn fun (i : Fin w) =>
    R (tape[(i.val + w - 1) % w]'(Nat.mod_lt _ hw) % 3 * 9 + tape[i] % 3 * 3 + tape[(i.val + 1) % w]'(Nat.mod_lt _ hw) % 3)

def evolveV (w : Nat) (hw : w > 0) (tape : Vector Nat w) : Nat → Vector Nat w
  | 0 => tape
  | t + 1 => stepV w hw (evolveV w hw tape t)

theorem doubler_n1 : evolveV 16 (by omega) (#v[0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0]) 2 = (#v[0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0]) := by native_decide
theorem doubler_n2 : evolveV 20 (by omega) (#v[0,0,0,0,0,0,0,0,1,2,0,0,0,0,0,0,0,0,0,0]) 7 = (#v[0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0]) := by native_decide
theorem doubler_n3 : evolveV 30 (by omega) (#v[0,0,0,0,0,0,0,0,0,0,0,0,1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) 16 = (#v[0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0]) := by native_decide
theorem doubler_n4 : evolveV 40 (by omega) (#v[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) 21 = (#v[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) := by native_decide
theorem doubler_n5 : evolveV 50 (by omega) (#v[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) 28 = (#v[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) := by native_decide

def S21 (m : Nat) (p : Int) : Tape := fun i => if i = p then 2 else if p < i ∧ i ≤ p + (↑m + 1) then 1 else 0
def S10 (m : Nat) (p : Int) : Tape := fun i => if i = p then 1 else if i = p + 1 then 0 else if p + 1 < i ∧ i ≤ p + (↑m + 1) then 1 else 0
def S20 (m : Nat) (p : Int) : Tape := fun i => if i = p then 2 else if i = p + 1 then 0 else if p + 1 < i ∧ i ≤ p + (↑m + 1) then 1 else 0
def S1 (m : Nat) (p : Int) : Tape := fun i => if p ≤ i ∧ i < p + (↑m + 2) then 1 else 0
theorem tail_step1 (m : Nat) (hm : m ≥ 1) (p : Int) :
    step (S21 m p) = S10 m p := by
  funext i; simp only [step, S21, S10]
  by_cases h1 : i ≤ p - 2
  ·
    simp only [show ¬(i - 1 = p) from by omega, show ¬(p < i - 1 ∧ i - 1 ≤ p + (↑m + 1)) from by omega, show ¬(i = p) from by omega, show ¬(p < i ∧ i ≤ p + (↑m + 1)) from by omega, show ¬(i + 1 = p) from by omega, show ¬(p < i + 1 ∧ i + 1 ≤ p + (↑m + 1)) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show ¬(p + 1 < i ∧ i ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h2 : i = p - 1
  · subst h2
    simp only [show ¬(p - 1 - 1 = p) from by omega, show ¬(p < p - 1 - 1 ∧ p - 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p - 1 = p) from by omega, show ¬(p < p - 1 ∧ p - 1 ≤ p + (↑m + 1)) from by omega, show p - 1 + 1 = p from by omega, show ¬(p < p - 1 + 1 ∧ p - 1 + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p - 1 = p) from by omega, show ¬(p - 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 ∧ p - 1 ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h3 : i = p
  · subst h3
    simp only [show ¬(p - 1 = p) from by omega, show ¬(p < p - 1 ∧ p - 1 ≤ p + (↑m + 1)) from by omega, show p = p from by omega, show ¬(p < p ∧ p ≤ p + (↑m + 1)) from by omega, show ¬(p + 1 = p) from by omega, show p < p + 1 ∧ p + 1 ≤ p + (↑m + 1) from by omega, show p = p from by omega, show ¬(p = p + 1) from by omega, show ¬(p + 1 < p ∧ p ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h4 : i = p + 1
  · subst h4
    simp only [show p + 1 - 1 = p from by omega, show ¬(p < p + 1 - 1 ∧ p + 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + 1 = p) from by omega, show p < p + 1 ∧ p + 1 ≤ p + (↑m + 1) from by omega, show ¬(p + 1 + 1 = p) from by omega, show p < p + 1 + 1 ∧ p + 1 + 1 ≤ p + (↑m + 1) from by omega, show ¬(p + 1 = p) from by omega, show p + 1 = p + 1 from by omega, show ¬(p + 1 < p + 1 ∧ p + 1 ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h5 : p + 1 < i ∧ i < p + (↑m + 1)
  ·
    simp only [show ¬(i - 1 = p) from by omega, show p < i - 1 ∧ i - 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show p < i ∧ i ≤ p + (↑m + 1) from by omega, show ¬(i + 1 = p) from by omega, show p < i + 1 ∧ i + 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show p + 1 < i ∧ i ≤ p + (↑m + 1) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h6 : i = p + (↑m + 1)
  · subst h6
    simp only [show ¬(p + (↑m + 1) - 1 = p) from by omega, show p < p + (↑m + 1) - 1 ∧ p + (↑m + 1) - 1 ≤ p + (↑m + 1) from by omega, show ¬(p + (↑m + 1) = p) from by omega, show p < p + (↑m + 1) ∧ p + (↑m + 1) ≤ p + (↑m + 1) from by omega, show ¬(p + (↑m + 1) + 1 = p) from by omega, show p < p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 ≤ p + (↑m + 1) from by omega, show ¬(p + (↑m + 1) = p) from by omega, show ¬(p + (↑m + 1) = p + 1) from by omega, show p + 1 < p + (↑m + 1) ∧ p + (↑m + 1) ≤ p + (↑m + 1) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h7 : i = p + (↑m + 1) + 1
  · subst h7
    simp only [show ¬(p + (↑m + 1) + 1 - 1 = p) from by omega, show ¬(p < p + (↑m + 1) + 1 - 1 ∧ p + (↑m + 1) + 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + (↑m + 1) + 1 = p) from by omega, show ¬(p < p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + (↑m + 1) + 1 + 1 = p) from by omega, show ¬(p < p + (↑m + 1) + 1 + 1 ∧ p + (↑m + 1) + 1 + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + (↑m + 1) + 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 = p + 1) from by omega, show ¬(p + 1 < p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h8 : p + (↑m + 1) + 1 < i
  ·
    simp only [show ¬(i - 1 = p) from by omega, show p < i - 1 ∧ i - 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show p < i ∧ i ≤ p + (↑m + 1) from by omega, show ¬(i + 1 = p) from by omega, show p < i + 1 ∧ i + 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show p + 1 < i ∧ i ≤ p + (↑m + 1) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]

theorem tail_step2 (m : Nat) (hm : m ≥ 1) (p : Int) :
    step (S10 m p) = S20 m p := by
  funext i; simp only [step, S10, S20]
  by_cases h1 : i ≤ p - 2
  ·
    simp only [show ¬(i - 1 = p) from by omega, show ¬(i - 1 = p + 1) from by omega, show ¬(p + 1 < i - 1 ∧ i - 1 ≤ p + (↑m + 1)) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show ¬(p + 1 < i ∧ i ≤ p + (↑m + 1)) from by omega, show ¬(i + 1 = p) from by omega, show ¬(i + 1 = p + 1) from by omega, show ¬(p + 1 < i + 1 ∧ i + 1 ≤ p + (↑m + 1)) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show ¬(p + 1 < i ∧ i ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h2 : i = p - 1
  · subst h2
    simp only [show ¬(p - 1 - 1 = p) from by omega, show ¬(p - 1 - 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 - 1 ∧ p - 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p - 1 = p) from by omega, show ¬(p - 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 ∧ p - 1 ≤ p + (↑m + 1)) from by omega, show p - 1 + 1 = p from by omega, show ¬(p - 1 + 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 + 1 ∧ p - 1 + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p - 1 = p) from by omega, show ¬(p - 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 ∧ p - 1 ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h3 : i = p
  · subst h3
    simp only [show ¬(p - 1 = p) from by omega, show ¬(p - 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 ∧ p - 1 ≤ p + (↑m + 1)) from by omega, show p = p from by omega, show ¬(p = p + 1) from by omega, show ¬(p + 1 < p ∧ p ≤ p + (↑m + 1)) from by omega, show ¬(p + 1 = p) from by omega, show p + 1 = p + 1 from by omega, show ¬(p + 1 < p + 1 ∧ p + 1 ≤ p + (↑m + 1)) from by omega, show p = p from by omega, show ¬(p = p + 1) from by omega, show ¬(p + 1 < p ∧ p ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h4 : i = p + 1
  · subst h4
    simp only [show p + 1 - 1 = p from by omega, show ¬(p + 1 - 1 = p + 1) from by omega, show ¬(p + 1 < p + 1 - 1 ∧ p + 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + 1 = p) from by omega, show p + 1 = p + 1 from by omega, show ¬(p + 1 < p + 1 ∧ p + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + 1 + 1 = p) from by omega, show ¬(p + 1 + 1 = p + 1) from by omega, show p + 1 < p + 1 + 1 ∧ p + 1 + 1 ≤ p + (↑m + 1) from by omega, show ¬(p + 1 = p) from by omega, show p + 1 = p + 1 from by omega, show ¬(p + 1 < p + 1 ∧ p + 1 ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h5 : i = p + 2
  · subst h5
    simp only [show ¬(p + 2 - 1 = p) from by omega, show p + 2 - 1 = p + 1 from by omega, show ¬(p + 1 < p + 2 - 1 ∧ p + 2 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + 2 = p) from by omega, show ¬(p + 2 = p + 1) from by omega, show p + 1 < p + 2 ∧ p + 2 ≤ p + (↑m + 1) from by omega, show ¬(p + 2 + 1 = p) from by omega, show ¬(p + 2 + 1 = p + 1) from by omega, show p + 1 < p + 2 + 1 ∧ p + 2 + 1 ≤ p + (↑m + 1) from by omega, show ¬(p + 2 = p) from by omega, show ¬(p + 2 = p + 1) from by omega, show p + 1 < p + 2 ∧ p + 2 ≤ p + (↑m + 1) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h6 : p + 2 < i ∧ i < p + (↑m + 1)
  ·
    simp only [show ¬(i - 1 = p) from by omega, show ¬(i - 1 = p + 1) from by omega, show p + 1 < i - 1 ∧ i - 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show p + 1 < i ∧ i ≤ p + (↑m + 1) from by omega, show ¬(i + 1 = p) from by omega, show ¬(i + 1 = p + 1) from by omega, show p + 1 < i + 1 ∧ i + 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show p + 1 < i ∧ i ≤ p + (↑m + 1) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h7 : i = p + (↑m + 1)
  · subst h7
    simp only [show ¬(p + (↑m + 1) - 1 = p) from by omega, show ¬(p + (↑m + 1) - 1 = p + 1) from by omega, show p + 1 < p + (↑m + 1) - 1 ∧ p + (↑m + 1) - 1 ≤ p + (↑m + 1) from by omega, show ¬(p + (↑m + 1) = p) from by omega, show ¬(p + (↑m + 1) = p + 1) from by omega, show p + 1 < p + (↑m + 1) ∧ p + (↑m + 1) ≤ p + (↑m + 1) from by omega, show ¬(p + (↑m + 1) + 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 = p + 1) from by omega, show p + 1 < p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 ≤ p + (↑m + 1) from by omega, show ¬(p + (↑m + 1) = p) from by omega, show ¬(p + (↑m + 1) = p + 1) from by omega, show p + 1 < p + (↑m + 1) ∧ p + (↑m + 1) ≤ p + (↑m + 1) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h8 : i = p + (↑m + 1) + 1
  · subst h8
    simp only [show ¬(p + (↑m + 1) + 1 - 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 - 1 = p + 1) from by omega, show ¬(p + 1 < p + (↑m + 1) + 1 - 1 ∧ p + (↑m + 1) + 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + (↑m + 1) + 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 = p + 1) from by omega, show ¬(p + 1 < p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + (↑m + 1) + 1 + 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 + 1 = p + 1) from by omega, show ¬(p + 1 < p + (↑m + 1) + 1 + 1 ∧ p + (↑m + 1) + 1 + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + (↑m + 1) + 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 = p + 1) from by omega, show ¬(p + 1 < p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 ≤ p + (↑m + 1)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h9 : p + (↑m + 1) + 1 < i
  ·
    simp only [show ¬(i - 1 = p) from by omega, show ¬(i - 1 = p + 1) from by omega, show p + 1 < i - 1 ∧ i - 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show p + 1 < i ∧ i ≤ p + (↑m + 1) from by omega, show ¬(i + 1 = p) from by omega, show ¬(i + 1 = p + 1) from by omega, show p + 1 < i + 1 ∧ i + 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show p + 1 < i ∧ i ≤ p + (↑m + 1) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]

theorem tail_step3 (m : Nat) (hm : m ≥ 1) (p : Int) :
    step (S20 m p) = S1 m p := by
  funext i; simp only [step, S20, S1]
  by_cases h1 : i ≤ p - 2
  ·
    simp only [show ¬(i - 1 = p) from by omega, show ¬(i - 1 = p + 1) from by omega, show ¬(p + 1 < i - 1 ∧ i - 1 ≤ p + (↑m + 1)) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show ¬(p + 1 < i ∧ i ≤ p + (↑m + 1)) from by omega, show ¬(i + 1 = p) from by omega, show ¬(i + 1 = p + 1) from by omega, show ¬(p + 1 < i + 1 ∧ i + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p ≤ i ∧ i < p + (↑m + 2)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h2 : i = p - 1
  · subst h2
    simp only [show ¬(p - 1 - 1 = p) from by omega, show ¬(p - 1 - 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 - 1 ∧ p - 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p - 1 = p) from by omega, show ¬(p - 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 ∧ p - 1 ≤ p + (↑m + 1)) from by omega, show p - 1 + 1 = p from by omega, show ¬(p - 1 + 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 + 1 ∧ p - 1 + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p ≤ p - 1 ∧ p - 1 < p + (↑m + 2)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h3 : i = p
  · subst h3
    simp only [show ¬(p - 1 = p) from by omega, show ¬(p - 1 = p + 1) from by omega, show ¬(p + 1 < p - 1 ∧ p - 1 ≤ p + (↑m + 1)) from by omega, show p = p from by omega, show ¬(p = p + 1) from by omega, show ¬(p + 1 < p ∧ p ≤ p + (↑m + 1)) from by omega, show ¬(p + 1 = p) from by omega, show p + 1 = p + 1 from by omega, show ¬(p + 1 < p + 1 ∧ p + 1 ≤ p + (↑m + 1)) from by omega, show p ≤ p ∧ p < p + (↑m + 2) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h4 : i = p + 1
  · subst h4
    simp only [show p + 1 - 1 = p from by omega, show ¬(p + 1 - 1 = p + 1) from by omega, show ¬(p + 1 < p + 1 - 1 ∧ p + 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + 1 = p) from by omega, show p + 1 = p + 1 from by omega, show ¬(p + 1 < p + 1 ∧ p + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + 1 + 1 = p) from by omega, show ¬(p + 1 + 1 = p + 1) from by omega, show p + 1 < p + 1 + 1 ∧ p + 1 + 1 ≤ p + (↑m + 1) from by omega, show p ≤ p + 1 ∧ p + 1 < p + (↑m + 2) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h5 : i = p + 2
  · subst h5
    simp only [show ¬(p + 2 - 1 = p) from by omega, show p + 2 - 1 = p + 1 from by omega, show ¬(p + 1 < p + 2 - 1 ∧ p + 2 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + 2 = p) from by omega, show ¬(p + 2 = p + 1) from by omega, show p + 1 < p + 2 ∧ p + 2 ≤ p + (↑m + 1) from by omega, show ¬(p + 2 + 1 = p) from by omega, show ¬(p + 2 + 1 = p + 1) from by omega, show p + 1 < p + 2 + 1 ∧ p + 2 + 1 ≤ p + (↑m + 1) from by omega, show p ≤ p + 2 ∧ p + 2 < p + (↑m + 2) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h6 : p + 2 < i ∧ i < p + (↑m + 1)
  ·
    simp only [show ¬(i - 1 = p) from by omega, show ¬(i - 1 = p + 1) from by omega, show p + 1 < i - 1 ∧ i - 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show p + 1 < i ∧ i ≤ p + (↑m + 1) from by omega, show ¬(i + 1 = p) from by omega, show ¬(i + 1 = p + 1) from by omega, show p + 1 < i + 1 ∧ i + 1 ≤ p + (↑m + 1) from by omega, show p ≤ i ∧ i < p + (↑m + 2) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h7 : i = p + (↑m + 1)
  · subst h7
    simp only [show ¬(p + (↑m + 1) - 1 = p) from by omega, show ¬(p + (↑m + 1) - 1 = p + 1) from by omega, show p + 1 < p + (↑m + 1) - 1 ∧ p + (↑m + 1) - 1 ≤ p + (↑m + 1) from by omega, show ¬(p + (↑m + 1) = p) from by omega, show ¬(p + (↑m + 1) = p + 1) from by omega, show p + 1 < p + (↑m + 1) ∧ p + (↑m + 1) ≤ p + (↑m + 1) from by omega, show ¬(p + (↑m + 1) + 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 = p + 1) from by omega, show p + 1 < p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 ≤ p + (↑m + 1) from by omega, show p ≤ p + (↑m + 1) ∧ p + (↑m + 1) < p + (↑m + 2) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h8 : i = p + (↑m + 1) + 1
  · subst h8
    simp only [show ¬(p + (↑m + 1) + 1 - 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 - 1 = p + 1) from by omega, show ¬(p + 1 < p + (↑m + 1) + 1 - 1 ∧ p + (↑m + 1) + 1 - 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + (↑m + 1) + 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 = p + 1) from by omega, show ¬(p + 1 < p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p + (↑m + 1) + 1 + 1 = p) from by omega, show ¬(p + (↑m + 1) + 1 + 1 = p + 1) from by omega, show ¬(p + 1 < p + (↑m + 1) + 1 + 1 ∧ p + (↑m + 1) + 1 + 1 ≤ p + (↑m + 1)) from by omega, show ¬(p ≤ p + (↑m + 1) + 1 ∧ p + (↑m + 1) + 1 < p + (↑m + 2)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]
  by_cases h9 : p + (↑m + 1) + 1 < i
  ·
    simp only [show ¬(i - 1 = p) from by omega, show ¬(i - 1 = p + 1) from by omega, show p + 1 < i - 1 ∧ i - 1 ≤ p + (↑m + 1) from by omega, show ¬(i = p) from by omega, show ¬(i = p + 1) from by omega, show p + 1 < i ∧ i ≤ p + (↑m + 1) from by omega, show ¬(i + 1 = p) from by omega, show ¬(i + 1 = p + 1) from by omega, show p + 1 < i + 1 ∧ i + 1 ≤ p + (↑m + 1) from by omega, show ¬(p ≤ i ∧ i < p + (↑m + 2)) from by omega, R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false]


theorem convergence_tail (m : Nat) (hm : m ≥ 1) (p : Int) :
    evolve (S21 m p) 3 = S1 m p := by
  simp only [evolve, tail_step1 m hm p, tail_step2 m hm p, tail_step3 m hm p]

end CA
