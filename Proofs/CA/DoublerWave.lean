import CA.Doubler

namespace CA

set_option maxHeartbeats 1600000

-- ============================================================================
-- Wave state: {2, 1, 0, (1, 0)^k, 1^m}
--
-- Layout on tape at position p:
--   p   : 2
--   p+1 : 1
--   p+2 : 0
--   p+3 to p+2+2k : alternating 1,0 (k pairs)
--     positions p+3, p+5, ..., p+3+2(k-1) : 1
--     positions p+4, p+6, ..., p+4+2(k-1) : 0
--   p+3+2k to p+2+2k+m : 1^m
--
-- To avoid existential quantifiers we encode this with range checks:
-- ============================================================================

-- Alternating 1,0 block occupies [p+3, p+2+2k)
-- Within that range: odd offset from p → 1, even offset from p → 0
-- i.e. (i - p) % 2 = 1 → value 1, (i - p) % 2 = 0 → value 0

-- For k = 0 this simplifies to: {2, 1, 0, 1^m}
-- For k ≥ 1: {2, 1, 0, 1, 0, ..., 1, 0, 1^m}

-- We define two separate states to avoid the modular arithmetic complexity:
-- S_wave0: {2, 1, 0, 1^m} (base case, k=0)
-- S_wave_succ: represents the 2-step reduction

-- Actually let us just prove the key chain without a parametric S_wave:
-- We already have S_pre1 = {1, 2, 0, 1^m} and S_pre2 = {2, 2, 0, 1^m}
-- and proved S_pre1 → S21 and S_pre2 → S21.
--
-- We also need:
-- S_mid = {1, 2, 1^m} → S_pre2
-- S21_0 = {2, 1, 0, 1^m} → S_mid (= S_pre1 without the gap)

-- ============================================================================
-- State: {2, 1, 0, 1^m} → {1, 2, 0, 1^m} → S21(m+1)
-- ============================================================================

def S_210 (m : Nat) (p : Int) : Tape := fun i =>
  if i = p then 2
  else if i = p + 1 then 1
  else if i = p + 2 then 0
  else if p + 2 < i ∧ i ≤ p + 2 + ↑m then 1
  else 0

def S_120 (m : Nat) (p : Int) : Tape := fun i =>
  if i = p then 1
  else if i = p + 1 then 2
  else if i = p + 2 then 0
  else if p + 2 < i ∧ i ≤ p + 2 + ↑m then 1
  else 0

theorem step_210_to_120 (m : Nat) (hm : m ≥ 2) (p : Int) :
    step (S_210 m p) = S_120 m p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl
      · by_cases h4 : i = p + 1
        · rw [h4]; dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + 2
          · rw [h5]; dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl
          · by_cases h6 : p + 2 < i ∧ i < p + 2 + ↑m
            · dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + 2 + ↑m
              · rw [h7]; dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl
              · by_cases h8 : i = p + 2 + ↑m + 1
                · rw [h8]; dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl
                · dsimp [step, S_210, S_120]; repeat (split <;> try omega); try rfl

theorem step_120_to_S21 (m : Nat) (hm : m ≥ 2) (p : Int) :
    step (S_120 m p) = S21 (m + 1) p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl
      · by_cases h4 : i = p + 1
        · rw [h4]; dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + 2
          · rw [h5]; dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl
          · by_cases h6 : p + 2 < i ∧ i < p + 2 + ↑m
            · dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + 2 + ↑m
              · rw [h7]; dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl
              · by_cases h8 : i = p + 2 + ↑m + 1
                · rw [h8]; dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl
                · dsimp [step, S_120, S21]; repeat (split <;> try omega); try rfl

-- Combined: {2, 1, 0, 1^m} →₂ S21(m+1, p)
theorem wave_base (m : Nat) (hm : m ≥ 2) (p : Int) :
    evolve (S_210 m p) 2 = S21 (m + 1) p := by
  dsimp [evolve]; rw [step_210_to_120 m hm p, step_120_to_S21 m hm p]

-- ============================================================================
-- State: {1, 2, 1^m} → {2, 2, 0, 1^m} → S21(m+1)
-- This is the universal last-5 tail entry
-- ============================================================================

-- {1, 2, 1^m}
def S_12 (m : Nat) (p : Int) : Tape := fun i =>
  if i = p then 1
  else if i = p + 1 then 2
  else if p + 1 < i ∧ i ≤ p + 1 + ↑m then 1
  else 0

-- {2, 2, 0, 1^m}
def S_220 (m : Nat) (p : Int) : Tape := fun i =>
  if i = p then 2
  else if i = p + 1 then 2
  else if i = p + 2 then 0
  else if p + 2 < i ∧ i ≤ p + 2 + ↑m then 1
  else 0

theorem step_12_to_220 (m : Nat) (hm : m ≥ 2) (p : Int) :
    step (S_12 m p) = S_220 (m - 1) p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl
      · by_cases h4 : i = p + 1
        · rw [h4]; dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + 2
          · rw [h5]; dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl
          · by_cases h6 : p + 2 < i ∧ i < p + 1 + ↑m
            · dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + 1 + ↑m
              · rw [h7]; dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl
              · by_cases h8 : i = p + 1 + ↑m + 1
                · rw [h8]; dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl
                · dsimp [step, S_12, S_220]; repeat (split <;> try omega); try rfl

theorem step_220_to_S21 (m : Nat) (hm : m ≥ 2) (p : Int) :
    step (S_220 m p) = S21 (m + 1) p := by
  funext i
  by_cases h1 : i ≤ p - 2
  · dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl
  · by_cases h2 : i = p - 1
    · rw [h2]; dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl
    · by_cases h3 : i = p
      · rw [h3]; dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl
      · by_cases h4 : i = p + 1
        · rw [h4]; dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl
        · by_cases h5 : i = p + 2
          · rw [h5]; dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl
          · by_cases h6 : p + 2 < i ∧ i < p + 2 + ↑m
            · dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl
            · by_cases h7 : i = p + 2 + ↑m
              · rw [h7]; dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl
              · by_cases h8 : i = p + 2 + ↑m + 1
                · rw [h8]; dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl
                · dsimp [step, S_220, S21]; repeat (split <;> try omega); try rfl

end CA
