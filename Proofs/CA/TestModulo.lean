

def B0 (idx : Int) : Nat :=
  if idx % 8 = 0 then 1 else if idx % 8 = 1 then 2 else if idx % 8 = 2 then 1 else if idx % 8 = 3 then 1
  else if idx % 8 = 4 then 1 else if idx % 8 = 5 then 2 else if idx % 8 = 6 then 2 else 0

def B1 (idx : Int) : Nat :=
  if idx % 8 = 0 then 2 else if idx % 8 = 1 then 2 else if idx % 8 = 2 then 0 else if idx % 8 = 3 then 1
  else if idx % 8 = 4 then 2 else if idx % 8 = 5 then 1 else if idx % 8 = 6 then 1 else if idx % 8 = 7 then 1 else 0

def B2 (idx : Int) : Nat :=
  if idx % 8 = 0 then 1 else if idx % 8 = 1 then 1 else if idx % 8 = 2 then 1 else if idx % 8 = 3 then 2
  else if idx % 8 = 4 then 2 else if idx % 8 = 5 then 0 else if idx % 8 = 6 then 1 else if idx % 8 = 7 then 2 else 0

def R (idx : Nat) : Nat :=
  match idx with
  |  0 => 0 |  1 => 0 |  2 => 0
  |  3 => 2 |  4 => 1 |  5 => 2
  |  6 => 1 |  7 => 1 |  8 => 2
  |  9 => 0 | 10 => 0 | 11 => 0
  | 12 => 1 | 13 => 1 | 14 => 2
  | 15 => 1 | 16 => 2 | 17 => 1
  | 18 => 1 | 19 => 1 | 20 => 0
  | 21 => 2 | 22 => 0 | 23 => 2
  | 24 => 1 | 25 => 1 | _  => 2

theorem test_B0_to_B1 (m : Int) (hm : 0 ≤ m) :
  R (9 * B0 (m - 1) + 3 * B0 m + B0 (m + 1)) = B1 m := by
  dsimp [B0, B1]
  have hmod : m % 8 = 0 ∨ m % 8 = 1 ∨ m % 8 = 2 ∨ m % 8 = 3 ∨ m % 8 = 4 ∨ m % 8 = 5 ∨ m % 8 = 6 ∨ m % 8 = 7 := by omega
  rcases hmod with h | h | h | h | h | h | h | h
  · have h1 : (m - 1) % 8 = 7 := (by omega); have h2 : (m + 1) % 8 = 1 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 0 := (by omega); have h2 : (m + 1) % 8 = 2 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 1 := (by omega); have h2 : (m + 1) % 8 = 3 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 2 := (by omega); have h2 : (m + 1) % 8 = 4 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 3 := (by omega); have h2 : (m + 1) % 8 = 5 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 4 := (by omega); have h2 : (m + 1) % 8 = 6 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 5 := (by omega); have h2 : (m + 1) % 8 = 7 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 6 := (by omega); have h2 : (m + 1) % 8 = 0 := (by omega); rw [h, h1, h2]; decide

theorem test_B1_to_B2 (m : Int) (hm : 0 ≤ m) :
  R (9 * B1 (m - 1) + 3 * B1 m + B1 (m + 1)) = B2 m := by
  dsimp [B1, B2]
  have hmod : m % 8 = 0 ∨ m % 8 = 1 ∨ m % 8 = 2 ∨ m % 8 = 3 ∨ m % 8 = 4 ∨ m % 8 = 5 ∨ m % 8 = 6 ∨ m % 8 = 7 := by omega
  rcases hmod with h | h | h | h | h | h | h | h
  · have h1 : (m - 1) % 8 = 7 := (by omega); have h2 : (m + 1) % 8 = 1 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 0 := (by omega); have h2 : (m + 1) % 8 = 2 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 1 := (by omega); have h2 : (m + 1) % 8 = 3 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 2 := (by omega); have h2 : (m + 1) % 8 = 4 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 3 := (by omega); have h2 : (m + 1) % 8 = 5 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 4 := (by omega); have h2 : (m + 1) % 8 = 6 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 5 := (by omega); have h2 : (m + 1) % 8 = 7 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 6 := (by omega); have h2 : (m + 1) % 8 = 0 := (by omega); rw [h, h1, h2]; decide

theorem test_B2_to_B0 (m : Int) (hm : 0 ≤ m) :
  R (9 * B2 (m - 1) + 3 * B2 m + B2 (m + 1)) = B0 (m - 1) := by
  dsimp [B0, B2]
  have hmod : m % 8 = 0 ∨ m % 8 = 1 ∨ m % 8 = 2 ∨ m % 8 = 3 ∨ m % 8 = 4 ∨ m % 8 = 5 ∨ m % 8 = 6 ∨ m % 8 = 7 := by omega
  rcases hmod with h | h | h | h | h | h | h | h
  · have h1 : (m - 1) % 8 = 7 := (by omega); have h2 : (m + 1) % 8 = 1 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 0 := (by omega); have h2 : (m + 1) % 8 = 2 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 1 := (by omega); have h2 : (m + 1) % 8 = 3 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 2 := (by omega); have h2 : (m + 1) % 8 = 4 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 3 := (by omega); have h2 : (m + 1) % 8 = 5 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 4 := (by omega); have h2 : (m + 1) % 8 = 6 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 5 := (by omega); have h2 : (m + 1) % 8 = 7 := (by omega); rw [h, h1, h2]; decide
  · have h1 : (m - 1) % 8 = 6 := (by omega); have h2 : (m + 1) % 8 = 0 := (by omega); rw [h, h1, h2]; decide
