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
  · dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl
      · by_cases h4 : p < i ∧ i < p + ↑n
        · dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + ↑n
          · rw [h5]; dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl
          · by_cases h6 : i = p + ↑n + 1
            · rw [h6]; dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + ↑n + 2
              · rw [h7]; dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl
              · by_cases h8 : p + ↑n + 2 < i
                · dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl
                · dsimp [step, S_in, S_out]; repeat (split <;> try omega); try rfl

end CA
