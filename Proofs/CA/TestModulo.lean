import CA.Doubler

open CA

def B_val (idx : Int) : Nat :=
  if idx % 8 = 0 then 1
  else if idx % 8 = 1 then 2
  else if idx % 8 = 2 then 1
  else if idx % 8 = 3 then 1
  else if idx % 8 = 4 then 1
  else if idx % 8 = 5 then 2
  else if idx % 8 = 6 then 2
  else if idx % 8 = 7 then 0
  else 0

def test_tape (k : Nat) (p : Int) : Tape := fun i =>
  if p ≤ i ∧ i < p + 8 * ↑k then
    B_val (i - p)
  else 0

theorem test_modulo (k : Nat) (p : Int) (i : Int)
    (h1 : p + 2 ≤ i) (h2 : i < p + 8 * ↑k - 2) :
    step (test_tape k p) i = 0 := by
  dsimp [step, test_tape, B_val]
  split <;> omega
