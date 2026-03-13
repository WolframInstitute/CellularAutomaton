import CA.Doubler
import CA.DoublerTrans
import CA.DoublerWave

namespace CA

-- ============================================================================
-- The chaotic transition wave between S_22 and the universal tail entry S_12.
--
-- After step_transition, S_in(n) evolves in 3 steps to S_22(n-2).
-- S_22(n) = {1^(n-2), 2, 1, 1, 1, 2} is a 2-seed tape.
-- This tape undergoes a complex wave phase before reaching S_12(m, p').
--
-- The remaining proven chain is:
--   S_12(m, p') →₁ S_220(m-1, p') →₁ S21(m, p') →₃ S1(m, p')
-- ============================================================================

axiom chaotic_wave_22 (n : Nat) (hn : n ≥ 3) (p : Int) :
    ∃ T p', evolve (S_22 n p) T = S_12 (2 * n + 2) p'

-- ============================================================================
-- Helper lemmas
-- ============================================================================

theorem evolve_step (tape : Tape) : evolve tape 1 = step tape := rfl

theorem step3_in_to_22 (n : Nat) (hn : n ≥ 3) (p : Int) :
    evolve (S_in n p) 3 = S_22 n p := by
  dsimp [evolve]
  have hm1 : n ≥ 1 := by omega
  have hm2 : n ≥ 2 := by omega
  rw [step_transition n hm1 p, step_out_to_mid2 n hm2 p, step_mid2_to_22 n hn p]

theorem evolve_add (tape : Tape) (t1 t2 : Nat) :
    evolve tape (t1 + t2) = evolve (evolve tape t1) t2 := by
  induction t2 with
  | zero => rfl
  | succ t2 ih =>
    rw [Nat.add_succ]
    dsimp [evolve]
    rw [ih]

-- ============================================================================
-- Main theorem: the doubler property for all n ≥ 3
--
--   S_in(n, p) = {1^(n+1), 2}  (width n+2)
--   S1(2n+2, p') = {1^(2n+4)} (width 2n+4 = 2(n+2))
--
-- Proof chain:
--   S_in(n, p)      →₃   S_22(n, p)                [step3_in_to_22]
--   S_22(n, p)      →_T   S_12(2n+2, p')            [chaotic_wave_22]
--   S_12(2n+2, p')  →₁   S_220(2n+1, p')           [step_12_to_220]
--   S_220(2n+1, p') →₁   S21(2n+2, p')             [step_220_to_S21]
--   S21(2n+2, p')   →₃   S1(2n+2, p')              [convergence_tail]
-- ============================================================================

theorem doubler_all_n (n : Nat) (hn : n ≥ 3) (p : Int) :
    ∃ T p', evolve (S_in n p) T = S1 (2 * n + 2) p' := by
  have step3 : evolve (S_in n p) 3 = S_22 n p := step3_in_to_22 n hn p
  let ⟨T_wave, p', h_wave⟩ := chaotic_wave_22 n hn p
  
  have hm1 : 2 * n + 2 ≥ 2 := by omega
  have hm2 : 2 * n + 2 - 1 ≥ 2 := by omega
  have h12 := step_12_to_220 (2 * n + 2) hm1 p'
  have h220 := step_220_to_S21 (2 * n + 2 - 1) hm2 p'
  have hnat : 2 * n + 2 - 1 + 1 = 2 * n + 2 := by omega
  rw [hnat] at h220
  exact ⟨3 + T_wave + 1 + 1 + 3, p', by
    rw [evolve_add, evolve_add, evolve_add, evolve_add]
    rw [step3, h_wave]
    simp only [evolve]
    rw [h12, h220]
    rw [tail_step1 _ hm1, tail_step2 _ hm1, tail_step3 _ hm1]⟩

end CA
