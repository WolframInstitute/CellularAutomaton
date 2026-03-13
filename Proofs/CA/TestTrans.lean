import CA.Doubler

namespace CA

def S_in (n : Nat) (p : Int) : Tape := fun i =>
  if p ≤ i ∧ i < p + (↑n + 1) then 1 else if i = p + (↑n + 1) then 2 else 0

def S_out (n : Nat) (p : Int) : Tape := fun i =>
  if p ≤ i ∧ i < p + ↑n then 1
  else if i = p + ↑n then 2
  else if p + ↑n < i ∧ i ≤ p + ↑n + 2 then 1
  else 0

theorem step_transition_h5 (n : Nat) (hn : n ≥ 1) (p : Int) (i : Int) (h5 : i = p + ↑n) :
    step (S_in n p) i = S_out n p i := by
  rw [h5]
  dsimp [step, S_in, S_out]
  repeat (split <;> try omega)
  try rfl

end CA
