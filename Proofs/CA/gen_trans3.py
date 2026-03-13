import CA.Doubler

namespace CA

def S_in (n : Nat) (p : Int) : Tape := fun i =>
  if p ≤ i ∧ i < p + (↑n + 1) then 1 else if i = p + (↑n + 1) then 2 else 0

def S_out (n : Nat) (p : Int) : Tape := fun i =>
  if p ≤ i ∧ i < p + ↑n then 1
  else if i = p + ↑n then 2
  else if p + ↑n < i ∧ i ≤ p + ↑n + 2 then 1
  else 0

theorem step_transition (n : Nat) (hn : n ≥ 1) (p : Int) :
    step (S_in n p) = S_out n p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show ¬(p ≤ i - 1 ∧ i - 1 < p + (↑n + 1)) from by omega,
      show ¬(i - 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i ∧ i < p + (↑n + 1)) from by omega,
      show ¬(i = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i + 1 ∧ i + 1 < p + (↑n + 1)) from by omega,
      show ¬(i + 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i ∧ i < p + ↑n) from by omega,
      show ¬(i = p + ↑n) from by omega,
      show ¬(p + ↑n < i ∧ i ≤ p + ↑n + 2) from by omega]
  by_cases h2 : i = p - 1
  · rw [h2]; simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show ¬(p ≤ p - 1 - 1 ∧ p - 1 - 1 < p + (↑n + 1)) from by omega,
      show ¬(p - 1 - 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ p - 1 ∧ p - 1 < p + (↑n + 1)) from by omega,
      show ¬(p - 1 = p + (↑n + 1)) from by omega,
      show p ≤ p - 1 + 1 ∧ p - 1 + 1 < p + (↑n + 1) from by omega,
      show ¬(p - 1 + 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ p - 1 ∧ p - 1 < p + ↑n) from by omega,
      show ¬(p - 1 = p + ↑n) from by omega,
      show ¬(p + ↑n < p - 1 ∧ p - 1 ≤ p + ↑n + 2) from by omega]
  by_cases h3 : i = p
  · rw [h3]; simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show ¬(p ≤ p - 1 ∧ p - 1 < p + (↑n + 1)) from by omega,
      show ¬(p - 1 = p + (↑n + 1)) from by omega,
      show p ≤ p ∧ p < p + (↑n + 1) from by omega,
      show ¬(p = p + (↑n + 1)) from by omega,
      show p ≤ p + 1 ∧ p + 1 < p + (↑n + 1) from by omega,
      show ¬(p + 1 = p + (↑n + 1)) from by omega,
      show p ≤ p ∧ p < p + ↑n from by omega,
      show ¬(p = p + ↑n) from by omega,
      show ¬(p + ↑n < p ∧ p ≤ p + ↑n + 2) from by omega]
  by_cases h4 : p < i ∧ i < p + ↑n
  · simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show p ≤ i - 1 ∧ i - 1 < p + (↑n + 1) from by omega,
      show ¬(i - 1 = p + (↑n + 1)) from by omega,
      show p ≤ i ∧ i < p + (↑n + 1) from by omega,
      show ¬(i = p + (↑n + 1)) from by omega,
      show p ≤ i + 1 ∧ i + 1 < p + (↑n + 1) from by omega,
      show ¬(i + 1 = p + (↑n + 1)) from by omega,
      show p ≤ i ∧ i < p + ↑n from by omega,
      show ¬(i = p + ↑n) from by omega,
      show ¬(p + ↑n < i ∧ i ≤ p + ↑n + 2) from by omega]
  by_cases h5 : i = p + ↑n
  · rw [h5]; simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show p ≤ p + ↑n - 1 ∧ p + ↑n - 1 < p + (↑n + 1) from by omega,
      show ¬(p + ↑n - 1 = p + (↑n + 1)) from by omega,
      show p ≤ p + ↑n ∧ p + ↑n < p + (↑n + 1) from by omega,
      show ¬(p + ↑n = p + (↑n + 1)) from by omega,
      show ¬(p ≤ p + ↑n + 1 ∧ p + ↑n + 1 < p + (↑n + 1)) from by omega,
      show p + ↑n + 1 = p + (↑n + 1) from by omega,
      show ¬(p ≤ p + ↑n ∧ p + ↑n < p + ↑n) from by omega,
      show p + ↑n = p + ↑n from by omega,
      show ¬(p + ↑n < p + ↑n ∧ p + ↑n ≤ p + ↑n + 2) from by omega]
  by_cases h6 : i = p + ↑n + 1
  · rw [h6]; simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show p ≤ p + ↑n + 1 - 1 ∧ p + ↑n + 1 - 1 < p + (↑n + 1) from by omega,
      show ¬(p + ↑n + 1 - 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ p + ↑n + 1 ∧ p + ↑n + 1 < p + (↑n + 1)) from by omega,
      show p + ↑n + 1 = p + (↑n + 1) from by omega,
      show ¬(p ≤ p + ↑n + 1 + 1 ∧ p + ↑n + 1 + 1 < p + (↑n + 1)) from by omega,
      show ¬(p + ↑n + 1 + 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ p + ↑n + 1 ∧ p + ↑n + 1 < p + ↑n) from by omega,
      show ¬(p + ↑n + 1 = p + ↑n) from by omega,
      show p + ↑n < p + ↑n + 1 ∧ p + ↑n + 1 ≤ p + ↑n + 2 from by omega]
  by_cases h7 : i = p + ↑n + 2
  · rw [h7]; simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show ¬(p ≤ p + ↑n + 2 - 1 ∧ p + ↑n + 2 - 1 < p + (↑n + 1)) from by omega,
      show p + ↑n + 2 - 1 = p + (↑n + 1) from by omega,
      show ¬(p ≤ p + ↑n + 2 ∧ p + ↑n + 2 < p + (↑n + 1)) from by omega,
      show ¬(p + ↑n + 2 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ p + ↑n + 2 + 1 ∧ p + ↑n + 2 + 1 < p + (↑n + 1)) from by omega,
      show ¬(p + ↑n + 2 + 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ p + ↑n + 2 ∧ p + ↑n + 2 < p + ↑n) from by omega,
      show ¬(p + ↑n + 2 = p + ↑n) from by omega,
      show p + ↑n < p + ↑n + 2 ∧ p + ↑n + 2 ≤ p + ↑n + 2 from by omega]
  by_cases h8 : p + ↑n + 2 < i
  · simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show ¬(p ≤ i - 1 ∧ i - 1 < p + (↑n + 1)) from by omega,
      show ¬(i - 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i ∧ i < p + (↑n + 1)) from by omega,
      show ¬(i = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i + 1 ∧ i + 1 < p + (↑n + 1)) from by omega,
      show ¬(i + 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i ∧ i < p + ↑n) from by omega,
      show ¬(i = p + ↑n) from by omega,
      show ¬(p + ↑n < i ∧ i ≤ p + ↑n + 2) from by omega]
  · simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,
      show ¬(p ≤ i - 1 ∧ i - 1 < p + (↑n + 1)) from by omega,
      show ¬(i - 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i ∧ i < p + (↑n + 1)) from by omega,
      show ¬(i = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i + 1 ∧ i + 1 < p + (↑n + 1)) from by omega,
      show ¬(i + 1 = p + (↑n + 1)) from by omega,
      show ¬(p ≤ i ∧ i < p + ↑n) from by omega,
      show ¬(i = p + ↑n) from by omega,
      show ¬(p + ↑n < i ∧ i ≤ p + ↑n + 2) from by omega]

end CA
