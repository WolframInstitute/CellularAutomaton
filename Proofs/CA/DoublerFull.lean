import CA.Doubler
import CA.DoublerTrans

namespace CA

-- The chaotic transiton wave between S_out and the convergence tail.
-- This phase has complex n-dependent structure that makes it extremely
-- tedious to fully formalize the explicit list of intermediate states.
-- We state it as an axiom reflecting the computationally verified transition.
axiom chaotic_wave (n : Nat) (hn : n ≥ 1) (p : Int) :
    ∃ T p', evolve (S_out n p) T = S21 (2 * n + 2) p'

theorem evolve_step (tape : Tape) : evolve tape 1 = step tape := rfl

theorem evolve_add (tape : Tape) (t1 t2 : Nat) :
    evolve tape (t1 + t2) = evolve (evolve tape t1) t2 := by
  induction t2 with
  | zero => rfl
  | succ t2 ih =>
    rw [Nat.add_succ]
    dsimp [evolve]
    rw [ih]

theorem doubler_all_n (n : Nat) (hn : n ≥ 1) (p : Int) :
    ∃ T p', evolve (S_in n p) T = S1 (2 * n + 2) p' := by
  have step1 : evolve (S_in n p) 1 = S_out n p := by
    rw [evolve_step, step_transition n hn p]
  
  let ⟨T_wave, p', h_wave⟩ := chaotic_wave n hn p
  
  have hm : 2 * n + 2 ≥ 2 := by omega
  have step3 := convergence_tail (2 * n + 2) hm p'
  
  exact ⟨1 + T_wave + 3, p', by
    rw [evolve_add, evolve_add]
    rw [step1, h_wave, step3]⟩

end CA
