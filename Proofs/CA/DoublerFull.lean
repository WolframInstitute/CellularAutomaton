import CA.Doubler
import CA.DoublerTrans
import CA.DoublerWave
import CA.DoublerBridge

namespace CA

-- ============================================================================
-- Helper lemmas
-- ============================================================================

theorem evolve_add (tape : Tape) (t1 t2 : Nat) :
    evolve tape (t1 + t2) = evolve (evolve tape t1) t2 := by
  induction t2 with
  | zero => rfl
  | succ t2 ih =>
    rw [Nat.add_succ]
    dsimp [evolve]
    rw [ih]

theorem step3_in_to_22 (n : Nat) (hn : n ≥ 3) (p : Int) :
    evolve (S_in n p) 3 = S_22 n p := by
  dsimp [evolve]
  have hm1 : n ≥ 1 := by omega
  have hm2 : n ≥ 2 := by omega
  rw [step_transition n hm1 p, step_out_to_mid2 n hm2 p, step_mid2_to_22 n hn p]

-- ============================================================================
-- The chaotic wave transition
--
-- S_22(n) evolves to S1(2n+2) after T steps.
-- Proven computationally via native_decide on LTape for n=3..15.
-- The bridge theorems (LTape.step_toTape, S_22_lt_toTape) connect
-- the decidable LTape computation to the infinite tape evolve.
--
-- For the "for all n" statement, this remains sorry:
-- - n=3..15 verified computationally (13 cases, T=24..103)
-- - n=1..5 also verified in base cases (Doubler.lean) 
-- - The chaotic wave has no recursive structure, preventing induction
-- ============================================================================

/-- The chaotic wave: S_22(n, p) evolves to S1(2n+2, p').
    Computationally verified for n=3..15, sorry for n ≥ 16. -/
theorem chaotic_wave_to_S1 (n : Nat) (hn : n ≥ 3) (p : Int) :
    ∃ T p', evolve (S_22 n p) T = S1 (2 * n + 2) p' := by
  sorry

-- ============================================================================
-- Main theorem: the doubler property for all n ≥ 3
-- ============================================================================

theorem doubler_all_n (n : Nat) (hn : n ≥ 3) (p : Int) :
    ∃ T p', evolve (S_in n p) T = S1 (2 * n + 2) p' := by
  have step3 : evolve (S_in n p) 3 = S_22 n p := step3_in_to_22 n hn p
  let ⟨T_wave, p', h_wave⟩ := chaotic_wave_to_S1 n hn p
  exact ⟨3 + T_wave, p', by rw [evolve_add, step3, h_wave]⟩

end CA
