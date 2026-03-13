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

set_option maxHeartbeats 2000000

-- ============================================================================
-- Step 2: S_out(n) = {1^n, 2, 1, 1} →₁ S_mid2(n) = {1^(n-1), 2, 2, 0, 1}
-- ============================================================================

def S_mid2 (n : Nat) (p : Int) : Tape := fun i =>
  if p ≤ i ∧ i < p + ↑n - 1 then 1
  else if i = p + ↑n - 1 then 2
  else if i = p + ↑n then 2
  else if i = p + ↑n + 1 then 0
  else if i = p + ↑n + 2 then 1
  else 0

theorem step_out_to_mid2 (n : Nat) (hn : n ≥ 2) (p : Int) :
    step (S_out n p) = S_mid2 n p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
      · by_cases h4 : p < i ∧ i < p + ↑n - 1
        · dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + ↑n - 1
          · rw [h5]; dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
          · by_cases h6 : i = p + ↑n
            · rw [h6]; dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + ↑n + 1
              · rw [h7]; dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
              · by_cases h8 : i = p + ↑n + 2
                · rw [h8]; dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
                · by_cases h9 : i = p + ↑n + 3
                  · rw [h9]; dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
                  · by_cases h10 : i = p + ↑n + 4
                    · rw [h10]; dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl
                    · dsimp [step, S_out, S_mid2]; repeat (split <;> try omega); try rfl

-- ============================================================================
-- Step 3: S_mid2(n) = {1^(n-1), 2, 2, 0, 1} →₁ S_22(n) = {1^(n-2), 2, 1, 1, 1, 2}
-- ============================================================================

def S_22 (n : Nat) (p : Int) : Tape := fun i =>
  if p ≤ i ∧ i < p + ↑n - 2 then 1
  else if i = p + ↑n - 2 then 2
  else if p + ↑n - 2 < i ∧ i ≤ p + ↑n + 1 then 1
  else if i = p + ↑n + 2 then 2
  else 0

theorem step_mid2_to_22 (n : Nat) (hn : n ≥ 3) (p : Int) :
    step (S_mid2 n p) = S_22 n p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
      · by_cases h4 : p < i ∧ i < p + ↑n - 2
        · dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + ↑n - 2
          · rw [h5]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
          · by_cases h6 : i = p + ↑n - 1
            · rw [h6]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + ↑n
              · rw [h7]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
              · by_cases h8 : i = p + ↑n + 1
                · rw [h8]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
                · by_cases h9 : i = p + ↑n + 2
                  · rw [h9]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
                  · by_cases h10 : i = p + ↑n + 3
                    · rw [h10]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
                    · by_cases h11 : i = p + ↑n + 4
                      · rw [h11]; dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl
                      · dsimp [step, S_mid2, S_22]; repeat (split <;> try omega); try rfl

end CA
