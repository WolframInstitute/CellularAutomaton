import CA.Doubler

namespace CA

set_option maxHeartbeats 1000000

def S_pre1 (m : Nat) (p : Int) : Tape := fun i =>
  if i = p then 1 else if i = p + 1 then 2 else if i = p + 2 then 0 else if p + 2 < i ∧ i ≤ p + 2 + ↑m then 1 else 0

def S_pre2 (m : Nat) (p : Int) : Tape := fun i =>
  if i = p then 2 else if i = p + 1 then 2 else if i = p + 2 then 0 else if p + 2 < i ∧ i ≤ p + 2 + ↑m then 1 else 0

theorem pre_tail_step1 (m : Nat) (hm : m ≥ 1) (p : Int) :
    step (S_pre1 m p) = S21 (m + 1) p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl
      · by_cases h4 : i = p + 1
        · rw [h4]; dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + 2
          · rw [h5]; dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl
          · by_cases h6 : p + 2 < i ∧ i < p + 2 + ↑m
            · dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + 2 + ↑m
              · rw [h7]; dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl
              · by_cases h8 : i = p + 2 + ↑m + 1
                · rw [h8]; dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl
                · dsimp [step, S_pre1, S21]; repeat (split <;> try omega); try rfl

theorem pre_tail_step2 (m : Nat) (hm : m ≥ 1) (p : Int) :
    step (S_pre2 m p) = S21 (m + 1) p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl
      · by_cases h4 : i = p + 1
        · rw [h4]; dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + 2
          · rw [h5]; dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl
          · by_cases h6 : p + 2 < i ∧ i < p + 2 + ↑m
            · dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + 2 + ↑m
              · rw [h7]; dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl
              · by_cases h8 : i = p + 2 + ↑m + 1
                · rw [h8]; dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl
                · dsimp [step, S_pre2, S21]; repeat (split <;> try omega); try rfl

end CA
