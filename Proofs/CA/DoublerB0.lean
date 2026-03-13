import CA.Doubler
namespace CA
set_option maxHeartbeats 200000000

def B0 (idx : Int) : Nat :=
  if idx % 8 = 0 then 1 else if idx % 8 = 1 then 1 else if idx % 8 = 2 then 2 else if idx % 8 = 3 then 2 else if idx % 8 = 4 then 0 else if idx % 8 = 5 then 1 else if idx % 8 = 6 then 2 else if idx % 8 = 7 then 1 else 0

def B1 (idx : Int) : Nat :=
  if idx % 8 = 0 then 1 else if idx % 8 = 1 then 2 else if idx % 8 = 2 then 1 else if idx % 8 = 3 then 1 else if idx % 8 = 4 then 1 else if idx % 8 = 5 then 2 else if idx % 8 = 6 then 2 else if idx % 8 = 7 then 0 else 0

def B2 (idx : Int) : Nat :=
  if idx % 8 = 0 then 2 else if idx % 8 = 1 then 2 else if idx % 8 = 2 then 0 else if idx % 8 = 3 then 1 else if idx % 8 = 4 then 2 else if idx % 8 = 5 then 1 else if idx % 8 = 6 then 1 else if idx % 8 = 7 then 1 else 0

@[simp] theorem mod_8k (k : Nat) (c : Int) : (8 * (k : Int) + c) % 8 = c % 8 := by omega

theorem step_B0_to_B1 (m : Int) : R (B0 (m - 1) * 9 + B0 m * 3 + B0 (m + 1)) = B1 m := by
  dsimp [B0, B1, R]
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

theorem step_B1_to_B2 (m : Int) : R (B1 (m - 1) * 9 + B1 m * 3 + B1 (m + 1)) = B2 m := by
  dsimp [B1, B2, R]
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

theorem step_B2_to_B0 (m : Int) : R (B2 (m - 1) * 9 + B2 m * 3 + B2 (m + 1)) = B0 (m - 1) := by
  dsimp [B2, B0, R]
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

def S_wave_0 (m k : Nat) (p : Int) : Tape := fun i =>
  if i < p then 0
  else if i < p + ↑m + 2 then 1
  else if i < p + ↑m + 8 * ↑k + 1 then B0 (i - (p + ↑m))
  else 0

def S_wave_1 (m k : Nat) (p : Int) : Tape := fun i =>
  if i < p then 0
  else if i < p + ↑m + 1 then 1
  else if i < p + ↑m + 8 * ↑k + 1 then B1 (i - (p + ↑m))
  else 0

def S_wave_2 (m k : Nat) (p : Int) : Tape := fun i =>
  if i < p then 0
  else if i < p + ↑m then 1
  else if i < p + ↑m + 8 * ↑k + 1 then B2 (i - (p + ↑m))
  else 0

def S_wave_3 (m k : Nat) (p : Int) : Tape := fun i =>
  if i < p then 0
  else if i < p + ↑m - 1 then 1
  else if i < p + ↑m + 8 * ↑k + 2 then B0 (i - (p + ↑m + 1))
  else 0

def S_wave_4 (m k : Nat) (p : Int) : Tape := fun i =>
  if i < p then 0
  else if i < p + ↑m - 2 then 1
  else if i < p + ↑m + 8 * ↑k + 2 then B1 (i - (p + ↑m + 1))
  else 0

def S_wave_5 (m k : Nat) (p : Int) : Tape := fun i =>
  if i < p then 0
  else if i < p + ↑m - 3 then 1
  else if i < p + ↑m + 8 * ↑k + 2 then B2 (i - (p + ↑m + 1))
  else 0

def S_wave_6 (m k : Nat) (p : Int) : Tape := fun i =>
  if i < p then 0
  else if i < p + ↑m - 4 then 1
  else if i < p + ↑m + 8 * ↑k + 3 then B0 (i - (p + ↑m + 2))
  else 0

theorem step_wave_1 (m k : Nat) (hm : m ≥ 6) (hk : k ≥ 6) (p : Int) :
    step (S_wave_0 m k p) = S_wave_1 m k p := by
  funext i
  have h_cases : i ≤ p + ↑m - 1 ∨ i = p + ↑m ∨ i = p + ↑m + 1 ∨ i = p + ↑m + 2 ∨ i = p + ↑m + 3 ∨ i = p + ↑m + 4 ∨ (i > p + ↑m + 4 ∧ i < p + ↑m + 8 * ↑k - 1) ∨ i = p + ↑m + 8 * ↑k - 1 ∨ i = p + ↑m + 8 * ↑k ∨ i = p + ↑m + 8 * ↑k + 1 ∨ i = p + ↑m + 8 * ↑k + 2 ∨ i = p + ↑m + 8 * ↑k + 3 ∨ i > p + ↑m + 8 * ↑k + 3 := by omega
  rcases h_cases with h_l | h_pt_0 | h_pt_1 | h_pt_2 | h_pt_3 | h_pt_4 | ⟨h_bulk_L, h_bulk_R⟩ | h_r_m1 | h_r_0 | h_r_1 | h_r_2 | h_r_3 | h_end
  · dsimp [step, S_wave_0, S_wave_1]
    have hw1 : i - 1 < p + ↑m + 2 := by omega
    have hw2 : i < p + ↑m + 2 := by omega
    have hw3 : i + 1 < p + ↑m + 2 := by omega
    have hw4 : i - 1 < p + ↑m + 1 := by omega
    have hw5 : i < p + ↑m + 1 := by omega
    have hw6 : i + 1 < p + ↑m + 1 := by omega
    simp only [hw1, hw2, hw3, hw4, hw5, hw6, ite_true, ite_false]
    have h_3way : i < p - 1 ∨ i = p - 1 ∨ i ≥ p := by omega
    rcases h_3way with h_lo | h_mid | h_hi
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : i + 1 < p := by omega
      simp only [hLp1, hLp2, hLp3, ite_true]
      decide
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : ¬(i + 1 < p) := by omega
      simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
      decide
    · have h_sub : i = p ∨ i > p := by omega
      rcases h_sub with h_eq | h_gt
      · have hLp1 : i - 1 < p := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
        decide
      · have hLp1 : ¬(i - 1 < p) := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_false]
        decide
  · subst h_pt_0
    dsimp [step, S_wave_0, S_wave_1]
    have hw7 : ¬(p + ↑m - 1 < p) := by omega
    have hw8 : p + ↑m - 1 < p + ↑m + 2 := by omega
    have hw9 : ¬(p + ↑m < p) := by omega
    have hw10 : p + ↑m < p + ↑m + 2 := by omega
    have hw11 : ¬(p + ↑m + 1 < p) := by omega
    have hw12 : p + ↑m + 1 < p + ↑m + 2 := by omega
    have hw13 : ¬(p + ↑m < p) := by omega
    have hw14 : p + ↑m < p + ↑m + 1 := by omega
    simp only [hw7, hw8, hw9, hw10, hw11, hw12, hw13, hw14, ite_true, ite_false]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_1
    dsimp [step, S_wave_0, S_wave_1]
    have hw15 : ¬(p + ↑m + 1 - 1 < p) := by omega
    have hw16 : p + ↑m + 1 - 1 < p + ↑m + 2 := by omega
    have hw17 : ¬(p + ↑m + 1 < p) := by omega
    have hw18 : p + ↑m + 1 < p + ↑m + 2 := by omega
    have hw19 : ¬(p + ↑m + 1 + 1 < p) := by omega
    have hw20 : ¬(p + ↑m + 1 + 1 < p + ↑m + 2) := by omega
    have hw21 : p + ↑m + 1 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw22 : ¬(p + ↑m + 1 < p) := by omega
    have hw23 : ¬(p + ↑m + 1 < p + ↑m + 1) := by omega
    have hw24 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw15, hw16, hw17, hw18, hw19, hw20, hw21, hw22, hw23, hw24, ite_true, ite_false]
    have hw25 : p + ↑m + 1 + 1 - (p + ↑m) = (2) := by omega
    try rw [hw25]
    have hw26 : p + ↑m + 1 - (p + ↑m) = (1) := by omega
    try rw [hw26]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_2
    dsimp [step, S_wave_0, S_wave_1]
    have hw27 : ¬(p + ↑m + 2 - 1 < p) := by omega
    have hw28 : p + ↑m + 2 - 1 < p + ↑m + 2 := by omega
    have hw29 : ¬(p + ↑m + 2 < p) := by omega
    have hw30 : ¬(p + ↑m + 2 < p + ↑m + 2) := by omega
    have hw31 : p + ↑m + 2 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw32 : ¬(p + ↑m + 2 + 1 < p) := by omega
    have hw33 : ¬(p + ↑m + 2 + 1 < p + ↑m + 2) := by omega
    have hw34 : p + ↑m + 2 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw35 : ¬(p + ↑m + 2 < p) := by omega
    have hw36 : ¬(p + ↑m + 2 < p + ↑m + 1) := by omega
    have hw37 : p + ↑m + 2 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw27, hw28, hw29, hw30, hw31, hw32, hw33, hw34, hw35, hw36, hw37, ite_true, ite_false]
    have hw38 : p + ↑m + 2 - (p + ↑m) = (2) := by omega
    try rw [hw38]
    have hw39 : p + ↑m + 2 + 1 - (p + ↑m) = (3) := by omega
    try rw [hw39]
    have hw40 : p + ↑m + 2 - (p + ↑m) = (2) := by omega
    try rw [hw40]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_3
    dsimp [step, S_wave_0, S_wave_1]
    have hw41 : ¬(p + ↑m + 3 - 1 < p) := by omega
    have hw42 : ¬(p + ↑m + 3 - 1 < p + ↑m + 2) := by omega
    have hw43 : p + ↑m + 3 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw44 : ¬(p + ↑m + 3 < p) := by omega
    have hw45 : ¬(p + ↑m + 3 < p + ↑m + 2) := by omega
    have hw46 : p + ↑m + 3 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw47 : ¬(p + ↑m + 3 + 1 < p) := by omega
    have hw48 : ¬(p + ↑m + 3 + 1 < p + ↑m + 2) := by omega
    have hw49 : p + ↑m + 3 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw50 : ¬(p + ↑m + 3 < p) := by omega
    have hw51 : ¬(p + ↑m + 3 < p + ↑m + 1) := by omega
    have hw52 : p + ↑m + 3 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw41, hw42, hw43, hw44, hw45, hw46, hw47, hw48, hw49, hw50, hw51, hw52, ite_true, ite_false]
    have hw53 : p + ↑m + 3 - 1 - (p + ↑m) = (2) := by omega
    try rw [hw53]
    have hw54 : p + ↑m + 3 - (p + ↑m) = (3) := by omega
    try rw [hw54]
    have hw55 : p + ↑m + 3 + 1 - (p + ↑m) = (4) := by omega
    try rw [hw55]
    have hw56 : p + ↑m + 3 - (p + ↑m) = (3) := by omega
    try rw [hw56]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_4
    dsimp [step, S_wave_0, S_wave_1]
    have hw57 : ¬(p + ↑m + 4 - 1 < p) := by omega
    have hw58 : ¬(p + ↑m + 4 - 1 < p + ↑m + 2) := by omega
    have hw59 : p + ↑m + 4 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw60 : ¬(p + ↑m + 4 < p) := by omega
    have hw61 : ¬(p + ↑m + 4 < p + ↑m + 2) := by omega
    have hw62 : p + ↑m + 4 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw63 : ¬(p + ↑m + 4 + 1 < p) := by omega
    have hw64 : ¬(p + ↑m + 4 + 1 < p + ↑m + 2) := by omega
    have hw65 : p + ↑m + 4 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw66 : ¬(p + ↑m + 4 < p) := by omega
    have hw67 : ¬(p + ↑m + 4 < p + ↑m + 1) := by omega
    have hw68 : p + ↑m + 4 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw57, hw58, hw59, hw60, hw61, hw62, hw63, hw64, hw65, hw66, hw67, hw68, ite_true, ite_false]
    have hw69 : p + ↑m + 4 - 1 - (p + ↑m) = (3) := by omega
    try rw [hw69]
    have hw70 : p + ↑m + 4 - (p + ↑m) = (4) := by omega
    try rw [hw70]
    have hw71 : p + ↑m + 4 + 1 - (p + ↑m) = (5) := by omega
    try rw [hw71]
    have hw72 : p + ↑m + 4 - (p + ↑m) = (4) := by omega
    try rw [hw72]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · dsimp [step, S_wave_0, S_wave_1]
    have hw73 : ¬ (i - 1 < p) := by omega
    have hw74 : ¬ (i < p) := by omega
    have hw75 : ¬ (i + 1 < p) := by omega
    have hw76 : ¬ (i - 1 < p + ↑m + 2) := by omega
    have hw77 : ¬ (i < p + ↑m + 2) := by omega
    have hw78 : ¬ (i + 1 < p + ↑m + 2) := by omega
    have hw79 : i - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw80 : i < p + ↑m + 8 * ↑k + 1 := by omega
    have hw81 : i + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw82 : ¬ (i < p + ↑m + 1) := by omega
    have hw83 : i < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw73, hw74, hw75, hw76, hw77, hw78, hw79, hw80, hw81, hw82, hw83, ite_true, ite_false]
    have idx1 : i - 1 - (p + ↑m) = i - (p + ↑m) - 1 := by omega
    have idx2 : i + 1 - (p + ↑m) = i - (p + ↑m) + 1 := by omega
    try rw [idx1, idx2]
    have h_final := step_B0_to_B1 (i - (p + ↑m))
    try rw [h_final]
  · subst h_r_m1
    dsimp [step, S_wave_0, S_wave_1]
    have hw84 : ¬(p + ↑m + 8 * ↑k - 1 - 1 < p) := by omega
    have hw85 : ¬(p + ↑m + 8 * ↑k - 1 - 1 < p + ↑m + 2) := by omega
    have hw86 : p + ↑m + 8 * ↑k - 1 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw87 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw88 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m + 2) := by omega
    have hw89 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw90 : ¬(p + ↑m + 8 * ↑k - 1 + 1 < p) := by omega
    have hw91 : ¬(p + ↑m + 8 * ↑k - 1 + 1 < p + ↑m + 2) := by omega
    have hw92 : p + ↑m + 8 * ↑k - 1 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw93 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw94 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m + 1) := by omega
    have hw95 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw84, hw85, hw86, hw87, hw88, hw89, hw90, hw91, hw92, hw93, hw94, hw95, ite_true, ite_false]
    have hw96 : p + ↑m + 8 * ↑k - 1 - 1 - (p + ↑m) = 8 * ↑k + (-2) := by omega
    try rw [hw96]
    have hw97 : p + ↑m + 8 * ↑k - 1 - (p + ↑m) = 8 * ↑k + (-1) := by omega
    try rw [hw97]
    have hw98 : p + ↑m + 8 * ↑k - 1 + 1 - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw98]
    have hw99 : p + ↑m + 8 * ↑k - 1 - (p + ↑m) = 8 * ↑k + (-1) := by omega
    try rw [hw99]
    have hw100 : (-2 : Int) % 8 = 6 := by decide
    have hw101 : (-1 : Int) % 8 = 7 := by decide
    simp only [B0, B1, mod_8k, hw100, hw101]
    dsimp [R]; try rfl
  · subst h_r_0
    dsimp [step, S_wave_0, S_wave_1]
    have hw102 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw103 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m + 2) := by omega
    have hw104 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw105 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw106 : ¬(p + ↑m + 8 * ↑k < p + ↑m + 2) := by omega
    have hw107 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 1 := by omega
    have hw108 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw109 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 2) := by omega
    have hw110 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw111 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw112 : ¬(p + ↑m + 8 * ↑k < p + ↑m + 1) := by omega
    have hw113 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw102, hw103, hw104, hw105, hw106, hw107, hw108, hw109, hw110, hw111, hw112, hw113, ite_true, ite_false]
    have hw114 : p + ↑m + 8 * ↑k - 1 - (p + ↑m) = 8 * ↑k + (-1) := by omega
    try rw [hw114]
    have hw115 : p + ↑m + 8 * ↑k - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw115]
    have hw116 : p + ↑m + 8 * ↑k - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw116]
    have hw117 : (-1 : Int) % 8 = 7 := by decide
    simp only [B0, B1, mod_8k, hw117]
    dsimp [R]; try rfl
  · subst h_r_1
    dsimp [step, S_wave_0, S_wave_1]
    have hw118 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p) := by omega
    have hw119 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m + 2) := by omega
    have hw120 : p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw121 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw122 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 2) := by omega
    have hw123 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw124 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p) := by omega
    have hw125 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m + 2) := by omega
    have hw126 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw127 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw128 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 1) := by omega
    have hw129 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    simp only [hw118, hw119, hw120, hw121, hw122, hw123, hw124, hw125, hw126, hw127, hw128, hw129, ite_true, ite_false]
    have hw130 : p + ↑m + 8 * ↑k + 1 - 1 - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw130]
    simp only [B0, B1, mod_8k]
    dsimp [R]; try rfl
  · subst h_r_2
    dsimp [step, S_wave_0, S_wave_1]
    have hw131 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p) := by omega
    have hw132 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m + 2) := by omega
    have hw133 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw134 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw135 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 2) := by omega
    have hw136 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw137 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p) := by omega
    have hw138 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m + 2) := by omega
    have hw139 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw140 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw141 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 1) := by omega
    have hw142 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 1) := by omega
    simp only [hw131, hw132, hw133, hw134, hw135, hw136, hw137, hw138, hw139, hw140, hw141, hw142, ite_true, ite_false]
    dsimp [R]; try rfl
  · subst h_r_3
    dsimp [step, S_wave_0, S_wave_1]
    have hw143 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p) := by omega
    have hw144 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m + 2) := by omega
    have hw145 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw146 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw147 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 2) := by omega
    have hw148 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw149 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p) := by omega
    have hw150 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m + 2) := by omega
    have hw151 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw152 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw153 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 1) := by omega
    have hw154 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 1) := by omega
    simp only [hw143, hw144, hw145, hw146, hw147, hw148, hw149, hw150, hw151, hw152, hw153, hw154, ite_true, ite_false]
    dsimp [R]; try rfl
  · dsimp [step, S_wave_0, S_wave_1]
    have hw155 : ¬(i - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw156 : ¬(i < p + ↑m + 8 * ↑k + 1) := by omega
    have hw157 : ¬(i + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw158 : ¬(i < p + ↑m + 8 * ↑k + 1) := by omega
    simp only [hw155, hw156, hw157, hw158, ite_false]
    repeat (split <;> (try omega))
    all_goals (first | rfl | (dsimp [R]; first | rfl | decide))

theorem step_wave_2 (m k : Nat) (hm : m ≥ 6) (hk : k ≥ 6) (p : Int) :
    step (S_wave_1 m k p) = S_wave_2 m k p := by
  funext i
  have h_cases : i ≤ p + ↑m - 2 ∨ i = p + ↑m - 1 ∨ i = p + ↑m ∨ i = p + ↑m + 1 ∨ i = p + ↑m + 2 ∨ i = p + ↑m + 3 ∨ (i > p + ↑m + 3 ∧ i < p + ↑m + 8 * ↑k - 1) ∨ i = p + ↑m + 8 * ↑k - 1 ∨ i = p + ↑m + 8 * ↑k ∨ i = p + ↑m + 8 * ↑k + 1 ∨ i = p + ↑m + 8 * ↑k + 2 ∨ i = p + ↑m + 8 * ↑k + 3 ∨ i > p + ↑m + 8 * ↑k + 3 := by omega
  rcases h_cases with h_l | h_pt_m1 | h_pt_0 | h_pt_1 | h_pt_2 | h_pt_3 | ⟨h_bulk_L, h_bulk_R⟩ | h_r_m1 | h_r_0 | h_r_1 | h_r_2 | h_r_3 | h_end
  · dsimp [step, S_wave_1, S_wave_2]
    have hw159 : i - 1 < p + ↑m + 1 := by omega
    have hw160 : i < p + ↑m + 1 := by omega
    have hw161 : i + 1 < p + ↑m + 1 := by omega
    have hw162 : i - 1 < p + ↑m := by omega
    have hw163 : i < p + ↑m := by omega
    have hw164 : i + 1 < p + ↑m := by omega
    simp only [hw159, hw160, hw161, hw162, hw163, hw164, ite_true, ite_false]
    have h_3way : i < p - 1 ∨ i = p - 1 ∨ i ≥ p := by omega
    rcases h_3way with h_lo | h_mid | h_hi
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : i + 1 < p := by omega
      simp only [hLp1, hLp2, hLp3, ite_true]
      decide
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : ¬(i + 1 < p) := by omega
      simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
      decide
    · have h_sub : i = p ∨ i > p := by omega
      rcases h_sub with h_eq | h_gt
      · have hLp1 : i - 1 < p := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
        decide
      · have hLp1 : ¬(i - 1 < p) := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_false]
        decide
  · subst h_pt_m1
    dsimp [step, S_wave_1, S_wave_2]
    have hw165 : ¬(p + ↑m - 1 - 1 < p) := by omega
    have hw166 : p + ↑m - 1 - 1 < p + ↑m + 1 := by omega
    have hw167 : ¬(p + ↑m - 1 < p) := by omega
    have hw168 : p + ↑m - 1 < p + ↑m + 1 := by omega
    have hw169 : ¬(p + ↑m - 1 + 1 < p) := by omega
    have hw170 : p + ↑m - 1 + 1 < p + ↑m + 1 := by omega
    have hw171 : ¬(p + ↑m - 1 < p) := by omega
    have hw172 : p + ↑m - 1 < p + ↑m := by omega
    simp only [hw165, hw166, hw167, hw168, hw169, hw170, hw171, hw172, ite_true, ite_false]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_0
    dsimp [step, S_wave_1, S_wave_2]
    have hw173 : ¬(p + ↑m - 1 < p) := by omega
    have hw174 : p + ↑m - 1 < p + ↑m + 1 := by omega
    have hw175 : ¬(p + ↑m < p) := by omega
    have hw176 : p + ↑m < p + ↑m + 1 := by omega
    have hw177 : ¬(p + ↑m + 1 < p) := by omega
    have hw178 : ¬(p + ↑m + 1 < p + ↑m + 1) := by omega
    have hw179 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw180 : ¬(p + ↑m < p) := by omega
    have hw181 : ¬(p + ↑m < p + ↑m) := by omega
    have hw182 : p + ↑m < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw173, hw174, hw175, hw176, hw177, hw178, hw179, hw180, hw181, hw182, ite_true, ite_false]
    have hw183 : p + ↑m + 1 - (p + ↑m) = (1) := by omega
    try rw [hw183]
    have hw184 : p + ↑m - (p + ↑m) = (0) := by omega
    try rw [hw184]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_1
    dsimp [step, S_wave_1, S_wave_2]
    have hw185 : ¬(p + ↑m + 1 - 1 < p) := by omega
    have hw186 : p + ↑m + 1 - 1 < p + ↑m + 1 := by omega
    have hw187 : ¬(p + ↑m + 1 < p) := by omega
    have hw188 : ¬(p + ↑m + 1 < p + ↑m + 1) := by omega
    have hw189 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw190 : ¬(p + ↑m + 1 + 1 < p) := by omega
    have hw191 : ¬(p + ↑m + 1 + 1 < p + ↑m + 1) := by omega
    have hw192 : p + ↑m + 1 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw193 : ¬(p + ↑m + 1 < p) := by omega
    have hw194 : ¬(p + ↑m + 1 < p + ↑m) := by omega
    have hw195 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw185, hw186, hw187, hw188, hw189, hw190, hw191, hw192, hw193, hw194, hw195, ite_true, ite_false]
    have hw196 : p + ↑m + 1 - (p + ↑m) = (1) := by omega
    try rw [hw196]
    have hw197 : p + ↑m + 1 + 1 - (p + ↑m) = (2) := by omega
    try rw [hw197]
    have hw198 : p + ↑m + 1 - (p + ↑m) = (1) := by omega
    try rw [hw198]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_2
    dsimp [step, S_wave_1, S_wave_2]
    have hw199 : ¬(p + ↑m + 2 - 1 < p) := by omega
    have hw200 : ¬(p + ↑m + 2 - 1 < p + ↑m + 1) := by omega
    have hw201 : p + ↑m + 2 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw202 : ¬(p + ↑m + 2 < p) := by omega
    have hw203 : ¬(p + ↑m + 2 < p + ↑m + 1) := by omega
    have hw204 : p + ↑m + 2 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw205 : ¬(p + ↑m + 2 + 1 < p) := by omega
    have hw206 : ¬(p + ↑m + 2 + 1 < p + ↑m + 1) := by omega
    have hw207 : p + ↑m + 2 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw208 : ¬(p + ↑m + 2 < p) := by omega
    have hw209 : ¬(p + ↑m + 2 < p + ↑m) := by omega
    have hw210 : p + ↑m + 2 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw199, hw200, hw201, hw202, hw203, hw204, hw205, hw206, hw207, hw208, hw209, hw210, ite_true, ite_false]
    have hw211 : p + ↑m + 2 - 1 - (p + ↑m) = (1) := by omega
    try rw [hw211]
    have hw212 : p + ↑m + 2 - (p + ↑m) = (2) := by omega
    try rw [hw212]
    have hw213 : p + ↑m + 2 + 1 - (p + ↑m) = (3) := by omega
    try rw [hw213]
    have hw214 : p + ↑m + 2 - (p + ↑m) = (2) := by omega
    try rw [hw214]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_3
    dsimp [step, S_wave_1, S_wave_2]
    have hw215 : ¬(p + ↑m + 3 - 1 < p) := by omega
    have hw216 : ¬(p + ↑m + 3 - 1 < p + ↑m + 1) := by omega
    have hw217 : p + ↑m + 3 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw218 : ¬(p + ↑m + 3 < p) := by omega
    have hw219 : ¬(p + ↑m + 3 < p + ↑m + 1) := by omega
    have hw220 : p + ↑m + 3 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw221 : ¬(p + ↑m + 3 + 1 < p) := by omega
    have hw222 : ¬(p + ↑m + 3 + 1 < p + ↑m + 1) := by omega
    have hw223 : p + ↑m + 3 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw224 : ¬(p + ↑m + 3 < p) := by omega
    have hw225 : ¬(p + ↑m + 3 < p + ↑m) := by omega
    have hw226 : p + ↑m + 3 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw215, hw216, hw217, hw218, hw219, hw220, hw221, hw222, hw223, hw224, hw225, hw226, ite_true, ite_false]
    have hw227 : p + ↑m + 3 - 1 - (p + ↑m) = (2) := by omega
    try rw [hw227]
    have hw228 : p + ↑m + 3 - (p + ↑m) = (3) := by omega
    try rw [hw228]
    have hw229 : p + ↑m + 3 + 1 - (p + ↑m) = (4) := by omega
    try rw [hw229]
    have hw230 : p + ↑m + 3 - (p + ↑m) = (3) := by omega
    try rw [hw230]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · dsimp [step, S_wave_1, S_wave_2]
    have hw231 : ¬ (i - 1 < p) := by omega
    have hw232 : ¬ (i < p) := by omega
    have hw233 : ¬ (i + 1 < p) := by omega
    have hw234 : ¬ (i - 1 < p + ↑m + 1) := by omega
    have hw235 : ¬ (i < p + ↑m + 1) := by omega
    have hw236 : ¬ (i + 1 < p + ↑m + 1) := by omega
    have hw237 : i - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw238 : i < p + ↑m + 8 * ↑k + 1 := by omega
    have hw239 : i + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw240 : ¬ (i < p + ↑m) := by omega
    have hw241 : i < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw231, hw232, hw233, hw234, hw235, hw236, hw237, hw238, hw239, hw240, hw241, ite_true, ite_false]
    have idx1 : i - 1 - (p + ↑m) = i - (p + ↑m) - 1 := by omega
    have idx2 : i + 1 - (p + ↑m) = i - (p + ↑m) + 1 := by omega
    try rw [idx1, idx2]
    have h_final := step_B1_to_B2 (i - (p + ↑m))
    try rw [h_final]
  · subst h_r_m1
    dsimp [step, S_wave_1, S_wave_2]
    have hw242 : ¬(p + ↑m + 8 * ↑k - 1 - 1 < p) := by omega
    have hw243 : ¬(p + ↑m + 8 * ↑k - 1 - 1 < p + ↑m + 1) := by omega
    have hw244 : p + ↑m + 8 * ↑k - 1 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw245 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw246 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m + 1) := by omega
    have hw247 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw248 : ¬(p + ↑m + 8 * ↑k - 1 + 1 < p) := by omega
    have hw249 : ¬(p + ↑m + 8 * ↑k - 1 + 1 < p + ↑m + 1) := by omega
    have hw250 : p + ↑m + 8 * ↑k - 1 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw251 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw252 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m) := by omega
    have hw253 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw242, hw243, hw244, hw245, hw246, hw247, hw248, hw249, hw250, hw251, hw252, hw253, ite_true, ite_false]
    have hw254 : p + ↑m + 8 * ↑k - 1 - 1 - (p + ↑m) = 8 * ↑k + (-2) := by omega
    try rw [hw254]
    have hw255 : p + ↑m + 8 * ↑k - 1 - (p + ↑m) = 8 * ↑k + (-1) := by omega
    try rw [hw255]
    have hw256 : p + ↑m + 8 * ↑k - 1 + 1 - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw256]
    have hw257 : p + ↑m + 8 * ↑k - 1 - (p + ↑m) = 8 * ↑k + (-1) := by omega
    try rw [hw257]
    have hw258 : (-2 : Int) % 8 = 6 := by decide
    have hw259 : (-1 : Int) % 8 = 7 := by decide
    simp only [B1, B2, mod_8k, hw258, hw259]
    dsimp [R]; try rfl
  · subst h_r_0
    dsimp [step, S_wave_1, S_wave_2]
    have hw260 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw261 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m + 1) := by omega
    have hw262 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw263 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw264 : ¬(p + ↑m + 8 * ↑k < p + ↑m + 1) := by omega
    have hw265 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 1 := by omega
    have hw266 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw267 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 1) := by omega
    have hw268 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw269 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw270 : ¬(p + ↑m + 8 * ↑k < p + ↑m) := by omega
    have hw271 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 1 := by omega
    simp only [hw260, hw261, hw262, hw263, hw264, hw265, hw266, hw267, hw268, hw269, hw270, hw271, ite_true, ite_false]
    have hw272 : p + ↑m + 8 * ↑k - 1 - (p + ↑m) = 8 * ↑k + (-1) := by omega
    try rw [hw272]
    have hw273 : p + ↑m + 8 * ↑k - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw273]
    have hw274 : p + ↑m + 8 * ↑k - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw274]
    have hw275 : (-1 : Int) % 8 = 7 := by decide
    simp only [B1, B2, mod_8k, hw275]
    dsimp [R]; try rfl
  · subst h_r_1
    dsimp [step, S_wave_1, S_wave_2]
    have hw276 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p) := by omega
    have hw277 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m + 1) := by omega
    have hw278 : p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw279 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw280 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 1) := by omega
    have hw281 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw282 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p) := by omega
    have hw283 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m + 1) := by omega
    have hw284 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw285 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw286 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m) := by omega
    have hw287 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    simp only [hw276, hw277, hw278, hw279, hw280, hw281, hw282, hw283, hw284, hw285, hw286, hw287, ite_true, ite_false]
    have hw288 : p + ↑m + 8 * ↑k + 1 - 1 - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw288]
    simp only [B1, B2, mod_8k]
    dsimp [R]; try rfl
  · subst h_r_2
    dsimp [step, S_wave_1, S_wave_2]
    have hw289 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p) := by omega
    have hw290 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m + 1) := by omega
    have hw291 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw292 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw293 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 1) := by omega
    have hw294 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw295 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p) := by omega
    have hw296 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m + 1) := by omega
    have hw297 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw298 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw299 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m) := by omega
    have hw300 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 1) := by omega
    simp only [hw289, hw290, hw291, hw292, hw293, hw294, hw295, hw296, hw297, hw298, hw299, hw300, ite_true, ite_false]
    dsimp [R]; try rfl
  · subst h_r_3
    dsimp [step, S_wave_1, S_wave_2]
    have hw301 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p) := by omega
    have hw302 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m + 1) := by omega
    have hw303 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw304 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw305 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 1) := by omega
    have hw306 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw307 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p) := by omega
    have hw308 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m + 1) := by omega
    have hw309 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw310 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw311 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m) := by omega
    have hw312 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 1) := by omega
    simp only [hw301, hw302, hw303, hw304, hw305, hw306, hw307, hw308, hw309, hw310, hw311, hw312, ite_true, ite_false]
    dsimp [R]; try rfl
  · dsimp [step, S_wave_1, S_wave_2]
    have hw313 : ¬(i - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw314 : ¬(i < p + ↑m + 8 * ↑k + 1) := by omega
    have hw315 : ¬(i + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw316 : ¬(i < p + ↑m + 8 * ↑k + 1) := by omega
    simp only [hw313, hw314, hw315, hw316, ite_false]
    repeat (split <;> (try omega))
    all_goals (first | rfl | (dsimp [R]; first | rfl | decide))

theorem step_wave_3 (m k : Nat) (hm : m ≥ 6) (hk : k ≥ 6) (p : Int) :
    step (S_wave_2 m k p) = S_wave_3 m k p := by
  funext i
  have h_cases : i ≤ p + ↑m - 3 ∨ i = p + ↑m - 2 ∨ i = p + ↑m - 1 ∨ i = p + ↑m ∨ i = p + ↑m + 1 ∨ i = p + ↑m + 2 ∨ (i > p + ↑m + 2 ∧ i < p + ↑m + 8 * ↑k - 1) ∨ i = p + ↑m + 8 * ↑k - 1 ∨ i = p + ↑m + 8 * ↑k ∨ i = p + ↑m + 8 * ↑k + 1 ∨ i = p + ↑m + 8 * ↑k + 2 ∨ i = p + ↑m + 8 * ↑k + 3 ∨ i = p + ↑m + 8 * ↑k + 4 ∨ i > p + ↑m + 8 * ↑k + 4 := by omega
  rcases h_cases with h_l | h_pt_m2 | h_pt_m1 | h_pt_0 | h_pt_1 | h_pt_2 | ⟨h_bulk_L, h_bulk_R⟩ | h_r_m1 | h_r_0 | h_r_1 | h_r_2 | h_r_3 | h_r_4 | h_end
  · dsimp [step, S_wave_2, S_wave_3]
    have hw317 : i - 1 < p + ↑m := by omega
    have hw318 : i < p + ↑m := by omega
    have hw319 : i + 1 < p + ↑m := by omega
    have hw320 : i - 1 < p + ↑m - 1 := by omega
    have hw321 : i < p + ↑m - 1 := by omega
    have hw322 : i + 1 < p + ↑m - 1 := by omega
    simp only [hw317, hw318, hw319, hw320, hw321, hw322, ite_true, ite_false]
    have h_3way : i < p - 1 ∨ i = p - 1 ∨ i ≥ p := by omega
    rcases h_3way with h_lo | h_mid | h_hi
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : i + 1 < p := by omega
      simp only [hLp1, hLp2, hLp3, ite_true]
      decide
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : ¬(i + 1 < p) := by omega
      simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
      decide
    · have h_sub : i = p ∨ i > p := by omega
      rcases h_sub with h_eq | h_gt
      · have hLp1 : i - 1 < p := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
        decide
      · have hLp1 : ¬(i - 1 < p) := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_false]
        decide
  · subst h_pt_m2
    dsimp [step, S_wave_2, S_wave_3]
    have hw323 : ¬(p + ↑m - 2 - 1 < p) := by omega
    have hw324 : p + ↑m - 2 - 1 < p + ↑m := by omega
    have hw325 : ¬(p + ↑m - 2 < p) := by omega
    have hw326 : p + ↑m - 2 < p + ↑m := by omega
    have hw327 : ¬(p + ↑m - 2 + 1 < p) := by omega
    have hw328 : p + ↑m - 2 + 1 < p + ↑m := by omega
    have hw329 : ¬(p + ↑m - 2 < p) := by omega
    have hw330 : p + ↑m - 2 < p + ↑m - 1 := by omega
    simp only [hw323, hw324, hw325, hw326, hw327, hw328, hw329, hw330, ite_true, ite_false]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m1
    dsimp [step, S_wave_2, S_wave_3]
    have hw331 : ¬(p + ↑m - 1 - 1 < p) := by omega
    have hw332 : p + ↑m - 1 - 1 < p + ↑m := by omega
    have hw333 : ¬(p + ↑m - 1 < p) := by omega
    have hw334 : p + ↑m - 1 < p + ↑m := by omega
    have hw335 : ¬(p + ↑m - 1 + 1 < p) := by omega
    have hw336 : ¬(p + ↑m - 1 + 1 < p + ↑m) := by omega
    have hw337 : p + ↑m - 1 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw338 : ¬(p + ↑m - 1 < p) := by omega
    have hw339 : ¬(p + ↑m - 1 < p + ↑m - 1) := by omega
    have hw340 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw331, hw332, hw333, hw334, hw335, hw336, hw337, hw338, hw339, hw340, ite_true, ite_false]
    have hw341 : p + ↑m - 1 + 1 - (p + ↑m) = (0) := by omega
    try rw [hw341]
    have hw342 : p + ↑m - 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw342]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_0
    dsimp [step, S_wave_2, S_wave_3]
    have hw343 : ¬(p + ↑m - 1 < p) := by omega
    have hw344 : p + ↑m - 1 < p + ↑m := by omega
    have hw345 : ¬(p + ↑m < p) := by omega
    have hw346 : ¬(p + ↑m < p + ↑m) := by omega
    have hw347 : p + ↑m < p + ↑m + 8 * ↑k + 1 := by omega
    have hw348 : ¬(p + ↑m + 1 < p) := by omega
    have hw349 : ¬(p + ↑m + 1 < p + ↑m) := by omega
    have hw350 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw351 : ¬(p + ↑m < p) := by omega
    have hw352 : ¬(p + ↑m < p + ↑m - 1) := by omega
    have hw353 : p + ↑m < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw343, hw344, hw345, hw346, hw347, hw348, hw349, hw350, hw351, hw352, hw353, ite_true, ite_false]
    have hw354 : p + ↑m - (p + ↑m) = (0) := by omega
    try rw [hw354]
    have hw355 : p + ↑m + 1 - (p + ↑m) = (1) := by omega
    try rw [hw355]
    have hw356 : p + ↑m - (p + ↑m + 1) = (-1) := by omega
    try rw [hw356]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_1
    dsimp [step, S_wave_2, S_wave_3]
    have hw357 : ¬(p + ↑m + 1 - 1 < p) := by omega
    have hw358 : ¬(p + ↑m + 1 - 1 < p + ↑m) := by omega
    have hw359 : p + ↑m + 1 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw360 : ¬(p + ↑m + 1 < p) := by omega
    have hw361 : ¬(p + ↑m + 1 < p + ↑m) := by omega
    have hw362 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw363 : ¬(p + ↑m + 1 + 1 < p) := by omega
    have hw364 : ¬(p + ↑m + 1 + 1 < p + ↑m) := by omega
    have hw365 : p + ↑m + 1 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw366 : ¬(p + ↑m + 1 < p) := by omega
    have hw367 : ¬(p + ↑m + 1 < p + ↑m - 1) := by omega
    have hw368 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw357, hw358, hw359, hw360, hw361, hw362, hw363, hw364, hw365, hw366, hw367, hw368, ite_true, ite_false]
    have hw369 : p + ↑m + 1 - 1 - (p + ↑m) = (0) := by omega
    try rw [hw369]
    have hw370 : p + ↑m + 1 - (p + ↑m) = (1) := by omega
    try rw [hw370]
    have hw371 : p + ↑m + 1 + 1 - (p + ↑m) = (2) := by omega
    try rw [hw371]
    have hw372 : p + ↑m + 1 - (p + ↑m + 1) = (0) := by omega
    try rw [hw372]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_2
    dsimp [step, S_wave_2, S_wave_3]
    have hw373 : ¬(p + ↑m + 2 - 1 < p) := by omega
    have hw374 : ¬(p + ↑m + 2 - 1 < p + ↑m) := by omega
    have hw375 : p + ↑m + 2 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw376 : ¬(p + ↑m + 2 < p) := by omega
    have hw377 : ¬(p + ↑m + 2 < p + ↑m) := by omega
    have hw378 : p + ↑m + 2 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw379 : ¬(p + ↑m + 2 + 1 < p) := by omega
    have hw380 : ¬(p + ↑m + 2 + 1 < p + ↑m) := by omega
    have hw381 : p + ↑m + 2 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw382 : ¬(p + ↑m + 2 < p) := by omega
    have hw383 : ¬(p + ↑m + 2 < p + ↑m - 1) := by omega
    have hw384 : p + ↑m + 2 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw373, hw374, hw375, hw376, hw377, hw378, hw379, hw380, hw381, hw382, hw383, hw384, ite_true, ite_false]
    have hw385 : p + ↑m + 2 - 1 - (p + ↑m) = (1) := by omega
    try rw [hw385]
    have hw386 : p + ↑m + 2 - (p + ↑m) = (2) := by omega
    try rw [hw386]
    have hw387 : p + ↑m + 2 + 1 - (p + ↑m) = (3) := by omega
    try rw [hw387]
    have hw388 : p + ↑m + 2 - (p + ↑m + 1) = (1) := by omega
    try rw [hw388]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · dsimp [step, S_wave_2, S_wave_3]
    have hw389 : ¬ (i - 1 < p) := by omega
    have hw390 : ¬ (i < p) := by omega
    have hw391 : ¬ (i + 1 < p) := by omega
    have hw392 : ¬ (i - 1 < p + ↑m) := by omega
    have hw393 : ¬ (i < p + ↑m) := by omega
    have hw394 : ¬ (i + 1 < p + ↑m) := by omega
    have hw395 : i - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw396 : i < p + ↑m + 8 * ↑k + 1 := by omega
    have hw397 : i + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw398 : ¬ (i < p + ↑m - 1) := by omega
    have hw399 : i < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw389, hw390, hw391, hw392, hw393, hw394, hw395, hw396, hw397, hw398, hw399, ite_true, ite_false]
    have idx1 : i - 1 - (p + ↑m) = i - (p + ↑m) - 1 := by omega
    have idx2 : i + 1 - (p + ↑m) = i - (p + ↑m) + 1 := by omega
    try rw [idx1, idx2]
    have h_final := step_B2_to_B0 (i - (p + ↑m))
    try rw [h_final]
    congr 1; omega
  · subst h_r_m1
    dsimp [step, S_wave_2, S_wave_3]
    have hw400 : ¬(p + ↑m + 8 * ↑k - 1 - 1 < p) := by omega
    have hw401 : ¬(p + ↑m + 8 * ↑k - 1 - 1 < p + ↑m) := by omega
    have hw402 : p + ↑m + 8 * ↑k - 1 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw403 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw404 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m) := by omega
    have hw405 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw406 : ¬(p + ↑m + 8 * ↑k - 1 + 1 < p) := by omega
    have hw407 : ¬(p + ↑m + 8 * ↑k - 1 + 1 < p + ↑m) := by omega
    have hw408 : p + ↑m + 8 * ↑k - 1 + 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw409 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw410 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m - 1) := by omega
    have hw411 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw400, hw401, hw402, hw403, hw404, hw405, hw406, hw407, hw408, hw409, hw410, hw411, ite_true, ite_false]
    have hw412 : p + ↑m + 8 * ↑k - 1 - 1 - (p + ↑m) = 8 * ↑k + (-2) := by omega
    try rw [hw412]
    have hw413 : p + ↑m + 8 * ↑k - 1 - (p + ↑m) = 8 * ↑k + (-1) := by omega
    try rw [hw413]
    have hw414 : p + ↑m + 8 * ↑k - 1 + 1 - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw414]
    have hw415 : p + ↑m + 8 * ↑k - 1 - (p + ↑m + 1) = 8 * ↑k + (-2) := by omega
    try rw [hw415]
    have hw416 : (-2 : Int) % 8 = 6 := by decide
    have hw417 : (-1 : Int) % 8 = 7 := by decide
    simp only [B2, B0, mod_8k, hw416, hw417]
    dsimp [R]; try rfl
  · subst h_r_0
    dsimp [step, S_wave_2, S_wave_3]
    have hw418 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw419 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m) := by omega
    have hw420 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw421 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw422 : ¬(p + ↑m + 8 * ↑k < p + ↑m) := by omega
    have hw423 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 1 := by omega
    have hw424 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw425 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m) := by omega
    have hw426 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw427 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw428 : ¬(p + ↑m + 8 * ↑k < p + ↑m - 1) := by omega
    have hw429 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw418, hw419, hw420, hw421, hw422, hw423, hw424, hw425, hw426, hw427, hw428, hw429, ite_true, ite_false]
    have hw430 : p + ↑m + 8 * ↑k - 1 - (p + ↑m) = 8 * ↑k + (-1) := by omega
    try rw [hw430]
    have hw431 : p + ↑m + 8 * ↑k - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw431]
    have hw432 : p + ↑m + 8 * ↑k - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw432]
    have hw433 : (-1 : Int) % 8 = 7 := by decide
    simp only [B2, B0, mod_8k, hw433]
    dsimp [R]; try rfl
  · subst h_r_1
    dsimp [step, S_wave_2, S_wave_3]
    have hw434 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p) := by omega
    have hw435 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m) := by omega
    have hw436 : p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m + 8 * ↑k + 1 := by omega
    have hw437 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw438 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m) := by omega
    have hw439 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw440 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p) := by omega
    have hw441 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m) := by omega
    have hw442 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw443 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw444 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 1) := by omega
    have hw445 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw434, hw435, hw436, hw437, hw438, hw439, hw440, hw441, hw442, hw443, hw444, hw445, ite_true, ite_false]
    have hw446 : p + ↑m + 8 * ↑k + 1 - 1 - (p + ↑m) = 8 * ↑k + (0) := by omega
    try rw [hw446]
    have hw447 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw447]
    simp only [B2, B0, mod_8k]
    dsimp [R]; try rfl
  · subst h_r_2
    dsimp [step, S_wave_2, S_wave_3]
    have hw448 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p) := by omega
    have hw449 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m) := by omega
    have hw450 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw451 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw452 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m) := by omega
    have hw453 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw454 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p) := by omega
    have hw455 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m) := by omega
    have hw456 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw457 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw458 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m - 1) := by omega
    have hw459 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw448, hw449, hw450, hw451, hw452, hw453, hw454, hw455, hw456, hw457, hw458, hw459, ite_true, ite_false]
    dsimp [R]; try rfl
  · subst h_r_3
    dsimp [step, S_wave_2, S_wave_3]
    have hw460 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p) := by omega
    have hw461 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m) := by omega
    have hw462 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw463 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw464 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m) := by omega
    have hw465 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw466 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p) := by omega
    have hw467 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m) := by omega
    have hw468 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw469 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw470 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m - 1) := by omega
    have hw471 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw460, hw461, hw462, hw463, hw464, hw465, hw466, hw467, hw468, hw469, hw470, hw471, ite_true, ite_false]
    dsimp [R]; try rfl
  · subst h_r_4
    dsimp [step, S_wave_2, S_wave_3]
    have hw472 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p) := by omega
    have hw473 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p + ↑m) := by omega
    have hw474 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw475 : ¬(p + ↑m + 8 * ↑k + 4 < p) := by omega
    have hw476 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m) := by omega
    have hw477 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw478 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p) := by omega
    have hw479 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p + ↑m) := by omega
    have hw480 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw481 : ¬(p + ↑m + 8 * ↑k + 4 < p) := by omega
    have hw482 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m - 1) := by omega
    have hw483 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw472, hw473, hw474, hw475, hw476, hw477, hw478, hw479, hw480, hw481, hw482, hw483, ite_true, ite_false]
    dsimp [R]; try rfl
  · dsimp [step, S_wave_2, S_wave_3]
    have hw484 : ¬(i - 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw485 : ¬(i < p + ↑m + 8 * ↑k + 1) := by omega
    have hw486 : ¬(i + 1 < p + ↑m + 8 * ↑k + 1) := by omega
    have hw487 : ¬(i < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw484, hw485, hw486, hw487, ite_false]
    repeat (split <;> (try omega))
    all_goals (first | rfl | (dsimp [R]; first | rfl | decide))

theorem step_wave_4 (m k : Nat) (hm : m ≥ 6) (hk : k ≥ 6) (p : Int) :
    step (S_wave_3 m k p) = S_wave_4 m k p := by
  funext i
  have h_cases : i ≤ p + ↑m - 4 ∨ i = p + ↑m - 3 ∨ i = p + ↑m - 2 ∨ i = p + ↑m - 1 ∨ i = p + ↑m ∨ i = p + ↑m + 1 ∨ (i > p + ↑m + 1 ∧ i < p + ↑m + 8 * ↑k) ∨ i = p + ↑m + 8 * ↑k ∨ i = p + ↑m + 8 * ↑k + 1 ∨ i = p + ↑m + 8 * ↑k + 2 ∨ i = p + ↑m + 8 * ↑k + 3 ∨ i = p + ↑m + 8 * ↑k + 4 ∨ i > p + ↑m + 8 * ↑k + 4 := by omega
  rcases h_cases with h_l | h_pt_m3 | h_pt_m2 | h_pt_m1 | h_pt_0 | h_pt_1 | ⟨h_bulk_L, h_bulk_R⟩ | h_r_0 | h_r_1 | h_r_2 | h_r_3 | h_r_4 | h_end
  · dsimp [step, S_wave_3, S_wave_4]
    have hw488 : i - 1 < p + ↑m - 1 := by omega
    have hw489 : i < p + ↑m - 1 := by omega
    have hw490 : i + 1 < p + ↑m - 1 := by omega
    have hw491 : i - 1 < p + ↑m - 2 := by omega
    have hw492 : i < p + ↑m - 2 := by omega
    have hw493 : i + 1 < p + ↑m - 2 := by omega
    simp only [hw488, hw489, hw490, hw491, hw492, hw493, ite_true, ite_false]
    have h_3way : i < p - 1 ∨ i = p - 1 ∨ i ≥ p := by omega
    rcases h_3way with h_lo | h_mid | h_hi
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : i + 1 < p := by omega
      simp only [hLp1, hLp2, hLp3, ite_true]
      decide
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : ¬(i + 1 < p) := by omega
      simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
      decide
    · have h_sub : i = p ∨ i > p := by omega
      rcases h_sub with h_eq | h_gt
      · have hLp1 : i - 1 < p := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
        decide
      · have hLp1 : ¬(i - 1 < p) := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_false]
        decide
  · subst h_pt_m3
    dsimp [step, S_wave_3, S_wave_4]
    have hw494 : ¬(p + ↑m - 3 - 1 < p) := by omega
    have hw495 : p + ↑m - 3 - 1 < p + ↑m - 1 := by omega
    have hw496 : ¬(p + ↑m - 3 < p) := by omega
    have hw497 : p + ↑m - 3 < p + ↑m - 1 := by omega
    have hw498 : ¬(p + ↑m - 3 + 1 < p) := by omega
    have hw499 : p + ↑m - 3 + 1 < p + ↑m - 1 := by omega
    have hw500 : ¬(p + ↑m - 3 < p) := by omega
    have hw501 : p + ↑m - 3 < p + ↑m - 2 := by omega
    simp only [hw494, hw495, hw496, hw497, hw498, hw499, hw500, hw501, ite_true, ite_false]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m2
    dsimp [step, S_wave_3, S_wave_4]
    have hw502 : ¬(p + ↑m - 2 - 1 < p) := by omega
    have hw503 : p + ↑m - 2 - 1 < p + ↑m - 1 := by omega
    have hw504 : ¬(p + ↑m - 2 < p) := by omega
    have hw505 : p + ↑m - 2 < p + ↑m - 1 := by omega
    have hw506 : ¬(p + ↑m - 2 + 1 < p) := by omega
    have hw507 : ¬(p + ↑m - 2 + 1 < p + ↑m - 1) := by omega
    have hw508 : p + ↑m - 2 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw509 : ¬(p + ↑m - 2 < p) := by omega
    have hw510 : ¬(p + ↑m - 2 < p + ↑m - 2) := by omega
    have hw511 : p + ↑m - 2 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw502, hw503, hw504, hw505, hw506, hw507, hw508, hw509, hw510, hw511, ite_true, ite_false]
    have hw512 : p + ↑m - 2 + 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw512]
    have hw513 : p + ↑m - 2 - (p + ↑m + 1) = (-3) := by omega
    try rw [hw513]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m1
    dsimp [step, S_wave_3, S_wave_4]
    have hw514 : ¬(p + ↑m - 1 - 1 < p) := by omega
    have hw515 : p + ↑m - 1 - 1 < p + ↑m - 1 := by omega
    have hw516 : ¬(p + ↑m - 1 < p) := by omega
    have hw517 : ¬(p + ↑m - 1 < p + ↑m - 1) := by omega
    have hw518 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw519 : ¬(p + ↑m - 1 + 1 < p) := by omega
    have hw520 : ¬(p + ↑m - 1 + 1 < p + ↑m - 1) := by omega
    have hw521 : p + ↑m - 1 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw522 : ¬(p + ↑m - 1 < p) := by omega
    have hw523 : ¬(p + ↑m - 1 < p + ↑m - 2) := by omega
    have hw524 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw514, hw515, hw516, hw517, hw518, hw519, hw520, hw521, hw522, hw523, hw524, ite_true, ite_false]
    have hw525 : p + ↑m - 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw525]
    have hw526 : p + ↑m - 1 + 1 - (p + ↑m + 1) = (-1) := by omega
    try rw [hw526]
    have hw527 : p + ↑m - 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw527]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_0
    dsimp [step, S_wave_3, S_wave_4]
    have hw528 : ¬(p + ↑m - 1 < p) := by omega
    have hw529 : ¬(p + ↑m - 1 < p + ↑m - 1) := by omega
    have hw530 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw531 : ¬(p + ↑m < p) := by omega
    have hw532 : ¬(p + ↑m < p + ↑m - 1) := by omega
    have hw533 : p + ↑m < p + ↑m + 8 * ↑k + 2 := by omega
    have hw534 : ¬(p + ↑m + 1 < p) := by omega
    have hw535 : ¬(p + ↑m + 1 < p + ↑m - 1) := by omega
    have hw536 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw537 : ¬(p + ↑m < p) := by omega
    have hw538 : ¬(p + ↑m < p + ↑m - 2) := by omega
    have hw539 : p + ↑m < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw528, hw529, hw530, hw531, hw532, hw533, hw534, hw535, hw536, hw537, hw538, hw539, ite_true, ite_false]
    have hw540 : p + ↑m - 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw540]
    have hw541 : p + ↑m - (p + ↑m + 1) = (-1) := by omega
    try rw [hw541]
    have hw542 : p + ↑m + 1 - (p + ↑m + 1) = (0) := by omega
    try rw [hw542]
    have hw543 : p + ↑m - (p + ↑m + 1) = (-1) := by omega
    try rw [hw543]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_1
    dsimp [step, S_wave_3, S_wave_4]
    have hw544 : ¬(p + ↑m + 1 - 1 < p) := by omega
    have hw545 : ¬(p + ↑m + 1 - 1 < p + ↑m - 1) := by omega
    have hw546 : p + ↑m + 1 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw547 : ¬(p + ↑m + 1 < p) := by omega
    have hw548 : ¬(p + ↑m + 1 < p + ↑m - 1) := by omega
    have hw549 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw550 : ¬(p + ↑m + 1 + 1 < p) := by omega
    have hw551 : ¬(p + ↑m + 1 + 1 < p + ↑m - 1) := by omega
    have hw552 : p + ↑m + 1 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw553 : ¬(p + ↑m + 1 < p) := by omega
    have hw554 : ¬(p + ↑m + 1 < p + ↑m - 2) := by omega
    have hw555 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw544, hw545, hw546, hw547, hw548, hw549, hw550, hw551, hw552, hw553, hw554, hw555, ite_true, ite_false]
    have hw556 : p + ↑m + 1 - 1 - (p + ↑m + 1) = (-1) := by omega
    try rw [hw556]
    have hw557 : p + ↑m + 1 - (p + ↑m + 1) = (0) := by omega
    try rw [hw557]
    have hw558 : p + ↑m + 1 + 1 - (p + ↑m + 1) = (1) := by omega
    try rw [hw558]
    have hw559 : p + ↑m + 1 - (p + ↑m + 1) = (0) := by omega
    try rw [hw559]
    dsimp [B0, B1, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · dsimp [step, S_wave_3, S_wave_4]
    have hw560 : ¬ (i - 1 < p) := by omega
    have hw561 : ¬ (i < p) := by omega
    have hw562 : ¬ (i + 1 < p) := by omega
    have hw563 : ¬ (i - 1 < p + ↑m - 1) := by omega
    have hw564 : ¬ (i < p + ↑m - 1) := by omega
    have hw565 : ¬ (i + 1 < p + ↑m - 1) := by omega
    have hw566 : i - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw567 : i < p + ↑m + 8 * ↑k + 2 := by omega
    have hw568 : i + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw569 : ¬ (i < p + ↑m - 2) := by omega
    have hw570 : i < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw560, hw561, hw562, hw563, hw564, hw565, hw566, hw567, hw568, hw569, hw570, ite_true, ite_false]
    have idx1 : i - 1 - (p + ↑m + 1) = i - (p + ↑m + 1) - 1 := by omega
    have idx2 : i + 1 - (p + ↑m + 1) = i - (p + ↑m + 1) + 1 := by omega
    try rw [idx1, idx2]
    have h_final := step_B0_to_B1 (i - (p + ↑m + 1))
    try rw [h_final]
  · subst h_r_0
    dsimp [step, S_wave_3, S_wave_4]
    have hw571 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw572 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m - 1) := by omega
    have hw573 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw574 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw575 : ¬(p + ↑m + 8 * ↑k < p + ↑m - 1) := by omega
    have hw576 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 2 := by omega
    have hw577 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw578 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 1) := by omega
    have hw579 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw580 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw581 : ¬(p + ↑m + 8 * ↑k < p + ↑m - 2) := by omega
    have hw582 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw571, hw572, hw573, hw574, hw575, hw576, hw577, hw578, hw579, hw580, hw581, hw582, ite_true, ite_false]
    have hw583 : p + ↑m + 8 * ↑k - 1 - (p + ↑m + 1) = 8 * ↑k + (-2) := by omega
    try rw [hw583]
    have hw584 : p + ↑m + 8 * ↑k - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw584]
    have hw585 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw585]
    have hw586 : p + ↑m + 8 * ↑k - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw586]
    have hw587 : (-2 : Int) % 8 = 6 := by decide
    have hw588 : (-1 : Int) % 8 = 7 := by decide
    simp only [B0, B1, mod_8k, hw587, hw588]
    dsimp [R]; try rfl
  · subst h_r_1
    dsimp [step, S_wave_3, S_wave_4]
    have hw589 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p) := by omega
    have hw590 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m - 1) := by omega
    have hw591 : p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw592 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw593 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 1) := by omega
    have hw594 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw595 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p) := by omega
    have hw596 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m - 1) := by omega
    have hw597 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw598 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw599 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 2) := by omega
    have hw600 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw589, hw590, hw591, hw592, hw593, hw594, hw595, hw596, hw597, hw598, hw599, hw600, ite_true, ite_false]
    have hw601 : p + ↑m + 8 * ↑k + 1 - 1 - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw601]
    have hw602 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw602]
    have hw603 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw603]
    have hw604 : (-1 : Int) % 8 = 7 := by decide
    simp only [B0, B1, mod_8k, hw604]
    dsimp [R]; try rfl
  · subst h_r_2
    dsimp [step, S_wave_3, S_wave_4]
    have hw605 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p) := by omega
    have hw606 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m - 1) := by omega
    have hw607 : p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw608 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw609 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m - 1) := by omega
    have hw610 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw611 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p) := by omega
    have hw612 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m - 1) := by omega
    have hw613 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw614 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw615 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m - 2) := by omega
    have hw616 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw605, hw606, hw607, hw608, hw609, hw610, hw611, hw612, hw613, hw614, hw615, hw616, ite_true, ite_false]
    have hw617 : p + ↑m + 8 * ↑k + 2 - 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw617]
    simp only [B0, B1, mod_8k]
    dsimp [R]; try rfl
  · subst h_r_3
    dsimp [step, S_wave_3, S_wave_4]
    have hw618 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p) := by omega
    have hw619 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m - 1) := by omega
    have hw620 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw621 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw622 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m - 1) := by omega
    have hw623 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw624 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p) := by omega
    have hw625 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m - 1) := by omega
    have hw626 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw627 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw628 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m - 2) := by omega
    have hw629 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw618, hw619, hw620, hw621, hw622, hw623, hw624, hw625, hw626, hw627, hw628, hw629, ite_true, ite_false]
    dsimp [R]; try rfl
  · subst h_r_4
    dsimp [step, S_wave_3, S_wave_4]
    have hw630 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p) := by omega
    have hw631 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p + ↑m - 1) := by omega
    have hw632 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw633 : ¬(p + ↑m + 8 * ↑k + 4 < p) := by omega
    have hw634 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m - 1) := by omega
    have hw635 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw636 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p) := by omega
    have hw637 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p + ↑m - 1) := by omega
    have hw638 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw639 : ¬(p + ↑m + 8 * ↑k + 4 < p) := by omega
    have hw640 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m - 2) := by omega
    have hw641 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw630, hw631, hw632, hw633, hw634, hw635, hw636, hw637, hw638, hw639, hw640, hw641, ite_true, ite_false]
    dsimp [R]; try rfl
  · dsimp [step, S_wave_3, S_wave_4]
    have hw642 : ¬(i - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw643 : ¬(i < p + ↑m + 8 * ↑k + 2) := by omega
    have hw644 : ¬(i + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw645 : ¬(i < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw642, hw643, hw644, hw645, ite_false]
    repeat (split <;> (try omega))
    all_goals (first | rfl | (dsimp [R]; first | rfl | decide))

theorem step_wave_5 (m k : Nat) (hm : m ≥ 6) (hk : k ≥ 6) (p : Int) :
    step (S_wave_4 m k p) = S_wave_5 m k p := by
  funext i
  have h_cases : i ≤ p + ↑m - 5 ∨ i = p + ↑m - 4 ∨ i = p + ↑m - 3 ∨ i = p + ↑m - 2 ∨ i = p + ↑m - 1 ∨ i = p + ↑m ∨ (i > p + ↑m ∧ i < p + ↑m + 8 * ↑k) ∨ i = p + ↑m + 8 * ↑k ∨ i = p + ↑m + 8 * ↑k + 1 ∨ i = p + ↑m + 8 * ↑k + 2 ∨ i = p + ↑m + 8 * ↑k + 3 ∨ i = p + ↑m + 8 * ↑k + 4 ∨ i > p + ↑m + 8 * ↑k + 4 := by omega
  rcases h_cases with h_l | h_pt_m4 | h_pt_m3 | h_pt_m2 | h_pt_m1 | h_pt_0 | ⟨h_bulk_L, h_bulk_R⟩ | h_r_0 | h_r_1 | h_r_2 | h_r_3 | h_r_4 | h_end
  · dsimp [step, S_wave_4, S_wave_5]
    have hw646 : i - 1 < p + ↑m - 2 := by omega
    have hw647 : i < p + ↑m - 2 := by omega
    have hw648 : i + 1 < p + ↑m - 2 := by omega
    have hw649 : i - 1 < p + ↑m - 3 := by omega
    have hw650 : i < p + ↑m - 3 := by omega
    have hw651 : i + 1 < p + ↑m - 3 := by omega
    simp only [hw646, hw647, hw648, hw649, hw650, hw651, ite_true, ite_false]
    have h_3way : i < p - 1 ∨ i = p - 1 ∨ i ≥ p := by omega
    rcases h_3way with h_lo | h_mid | h_hi
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : i + 1 < p := by omega
      simp only [hLp1, hLp2, hLp3, ite_true]
      decide
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : ¬(i + 1 < p) := by omega
      simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
      decide
    · have h_sub : i = p ∨ i > p := by omega
      rcases h_sub with h_eq | h_gt
      · have hLp1 : i - 1 < p := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
        decide
      · have hLp1 : ¬(i - 1 < p) := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_false]
        decide
  · subst h_pt_m4
    dsimp [step, S_wave_4, S_wave_5]
    have hw652 : ¬(p + ↑m - 4 - 1 < p) := by omega
    have hw653 : p + ↑m - 4 - 1 < p + ↑m - 2 := by omega
    have hw654 : ¬(p + ↑m - 4 < p) := by omega
    have hw655 : p + ↑m - 4 < p + ↑m - 2 := by omega
    have hw656 : ¬(p + ↑m - 4 + 1 < p) := by omega
    have hw657 : p + ↑m - 4 + 1 < p + ↑m - 2 := by omega
    have hw658 : ¬(p + ↑m - 4 < p) := by omega
    have hw659 : p + ↑m - 4 < p + ↑m - 3 := by omega
    simp only [hw652, hw653, hw654, hw655, hw656, hw657, hw658, hw659, ite_true, ite_false]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m3
    dsimp [step, S_wave_4, S_wave_5]
    have hw660 : ¬(p + ↑m - 3 - 1 < p) := by omega
    have hw661 : p + ↑m - 3 - 1 < p + ↑m - 2 := by omega
    have hw662 : ¬(p + ↑m - 3 < p) := by omega
    have hw663 : p + ↑m - 3 < p + ↑m - 2 := by omega
    have hw664 : ¬(p + ↑m - 3 + 1 < p) := by omega
    have hw665 : ¬(p + ↑m - 3 + 1 < p + ↑m - 2) := by omega
    have hw666 : p + ↑m - 3 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw667 : ¬(p + ↑m - 3 < p) := by omega
    have hw668 : ¬(p + ↑m - 3 < p + ↑m - 3) := by omega
    have hw669 : p + ↑m - 3 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw660, hw661, hw662, hw663, hw664, hw665, hw666, hw667, hw668, hw669, ite_true, ite_false]
    have hw670 : p + ↑m - 3 + 1 - (p + ↑m + 1) = (-3) := by omega
    try rw [hw670]
    have hw671 : p + ↑m - 3 - (p + ↑m + 1) = (-4) := by omega
    try rw [hw671]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m2
    dsimp [step, S_wave_4, S_wave_5]
    have hw672 : ¬(p + ↑m - 2 - 1 < p) := by omega
    have hw673 : p + ↑m - 2 - 1 < p + ↑m - 2 := by omega
    have hw674 : ¬(p + ↑m - 2 < p) := by omega
    have hw675 : ¬(p + ↑m - 2 < p + ↑m - 2) := by omega
    have hw676 : p + ↑m - 2 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw677 : ¬(p + ↑m - 2 + 1 < p) := by omega
    have hw678 : ¬(p + ↑m - 2 + 1 < p + ↑m - 2) := by omega
    have hw679 : p + ↑m - 2 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw680 : ¬(p + ↑m - 2 < p) := by omega
    have hw681 : ¬(p + ↑m - 2 < p + ↑m - 3) := by omega
    have hw682 : p + ↑m - 2 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw672, hw673, hw674, hw675, hw676, hw677, hw678, hw679, hw680, hw681, hw682, ite_true, ite_false]
    have hw683 : p + ↑m - 2 - (p + ↑m + 1) = (-3) := by omega
    try rw [hw683]
    have hw684 : p + ↑m - 2 + 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw684]
    have hw685 : p + ↑m - 2 - (p + ↑m + 1) = (-3) := by omega
    try rw [hw685]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m1
    dsimp [step, S_wave_4, S_wave_5]
    have hw686 : ¬(p + ↑m - 1 - 1 < p) := by omega
    have hw687 : ¬(p + ↑m - 1 - 1 < p + ↑m - 2) := by omega
    have hw688 : p + ↑m - 1 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw689 : ¬(p + ↑m - 1 < p) := by omega
    have hw690 : ¬(p + ↑m - 1 < p + ↑m - 2) := by omega
    have hw691 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw692 : ¬(p + ↑m - 1 + 1 < p) := by omega
    have hw693 : ¬(p + ↑m - 1 + 1 < p + ↑m - 2) := by omega
    have hw694 : p + ↑m - 1 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw695 : ¬(p + ↑m - 1 < p) := by omega
    have hw696 : ¬(p + ↑m - 1 < p + ↑m - 3) := by omega
    have hw697 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw686, hw687, hw688, hw689, hw690, hw691, hw692, hw693, hw694, hw695, hw696, hw697, ite_true, ite_false]
    have hw698 : p + ↑m - 1 - 1 - (p + ↑m + 1) = (-3) := by omega
    try rw [hw698]
    have hw699 : p + ↑m - 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw699]
    have hw700 : p + ↑m - 1 + 1 - (p + ↑m + 1) = (-1) := by omega
    try rw [hw700]
    have hw701 : p + ↑m - 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw701]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_0
    dsimp [step, S_wave_4, S_wave_5]
    have hw702 : ¬(p + ↑m - 1 < p) := by omega
    have hw703 : ¬(p + ↑m - 1 < p + ↑m - 2) := by omega
    have hw704 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw705 : ¬(p + ↑m < p) := by omega
    have hw706 : ¬(p + ↑m < p + ↑m - 2) := by omega
    have hw707 : p + ↑m < p + ↑m + 8 * ↑k + 2 := by omega
    have hw708 : ¬(p + ↑m + 1 < p) := by omega
    have hw709 : ¬(p + ↑m + 1 < p + ↑m - 2) := by omega
    have hw710 : p + ↑m + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw711 : ¬(p + ↑m < p) := by omega
    have hw712 : ¬(p + ↑m < p + ↑m - 3) := by omega
    have hw713 : p + ↑m < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw702, hw703, hw704, hw705, hw706, hw707, hw708, hw709, hw710, hw711, hw712, hw713, ite_true, ite_false]
    have hw714 : p + ↑m - 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw714]
    have hw715 : p + ↑m - (p + ↑m + 1) = (-1) := by omega
    try rw [hw715]
    have hw716 : p + ↑m + 1 - (p + ↑m + 1) = (0) := by omega
    try rw [hw716]
    have hw717 : p + ↑m - (p + ↑m + 1) = (-1) := by omega
    try rw [hw717]
    dsimp [B1, B2, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · dsimp [step, S_wave_4, S_wave_5]
    have hw718 : ¬ (i - 1 < p) := by omega
    have hw719 : ¬ (i < p) := by omega
    have hw720 : ¬ (i + 1 < p) := by omega
    have hw721 : ¬ (i - 1 < p + ↑m - 2) := by omega
    have hw722 : ¬ (i < p + ↑m - 2) := by omega
    have hw723 : ¬ (i + 1 < p + ↑m - 2) := by omega
    have hw724 : i - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw725 : i < p + ↑m + 8 * ↑k + 2 := by omega
    have hw726 : i + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw727 : ¬ (i < p + ↑m - 3) := by omega
    have hw728 : i < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw718, hw719, hw720, hw721, hw722, hw723, hw724, hw725, hw726, hw727, hw728, ite_true, ite_false]
    have idx1 : i - 1 - (p + ↑m + 1) = i - (p + ↑m + 1) - 1 := by omega
    have idx2 : i + 1 - (p + ↑m + 1) = i - (p + ↑m + 1) + 1 := by omega
    try rw [idx1, idx2]
    have h_final := step_B1_to_B2 (i - (p + ↑m + 1))
    try rw [h_final]
  · subst h_r_0
    dsimp [step, S_wave_4, S_wave_5]
    have hw729 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw730 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m - 2) := by omega
    have hw731 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw732 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw733 : ¬(p + ↑m + 8 * ↑k < p + ↑m - 2) := by omega
    have hw734 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 2 := by omega
    have hw735 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw736 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 2) := by omega
    have hw737 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw738 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw739 : ¬(p + ↑m + 8 * ↑k < p + ↑m - 3) := by omega
    have hw740 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw729, hw730, hw731, hw732, hw733, hw734, hw735, hw736, hw737, hw738, hw739, hw740, ite_true, ite_false]
    have hw741 : p + ↑m + 8 * ↑k - 1 - (p + ↑m + 1) = 8 * ↑k + (-2) := by omega
    try rw [hw741]
    have hw742 : p + ↑m + 8 * ↑k - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw742]
    have hw743 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw743]
    have hw744 : p + ↑m + 8 * ↑k - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw744]
    have hw745 : (-2 : Int) % 8 = 6 := by decide
    have hw746 : (-1 : Int) % 8 = 7 := by decide
    simp only [B1, B2, mod_8k, hw745, hw746]
    dsimp [R]; try rfl
  · subst h_r_1
    dsimp [step, S_wave_4, S_wave_5]
    have hw747 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p) := by omega
    have hw748 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m - 2) := by omega
    have hw749 : p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw750 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw751 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 2) := by omega
    have hw752 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw753 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p) := by omega
    have hw754 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m - 2) := by omega
    have hw755 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw756 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw757 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 3) := by omega
    have hw758 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    simp only [hw747, hw748, hw749, hw750, hw751, hw752, hw753, hw754, hw755, hw756, hw757, hw758, ite_true, ite_false]
    have hw759 : p + ↑m + 8 * ↑k + 1 - 1 - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw759]
    have hw760 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw760]
    have hw761 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw761]
    have hw762 : (-1 : Int) % 8 = 7 := by decide
    simp only [B1, B2, mod_8k, hw762]
    dsimp [R]; try rfl
  · subst h_r_2
    dsimp [step, S_wave_4, S_wave_5]
    have hw763 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p) := by omega
    have hw764 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m - 2) := by omega
    have hw765 : p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw766 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw767 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m - 2) := by omega
    have hw768 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw769 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p) := by omega
    have hw770 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m - 2) := by omega
    have hw771 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw772 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw773 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m - 3) := by omega
    have hw774 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw763, hw764, hw765, hw766, hw767, hw768, hw769, hw770, hw771, hw772, hw773, hw774, ite_true, ite_false]
    have hw775 : p + ↑m + 8 * ↑k + 2 - 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw775]
    simp only [B1, B2, mod_8k]
    dsimp [R]; try rfl
  · subst h_r_3
    dsimp [step, S_wave_4, S_wave_5]
    have hw776 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p) := by omega
    have hw777 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m - 2) := by omega
    have hw778 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw779 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw780 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m - 2) := by omega
    have hw781 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw782 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p) := by omega
    have hw783 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m - 2) := by omega
    have hw784 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw785 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw786 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m - 3) := by omega
    have hw787 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw776, hw777, hw778, hw779, hw780, hw781, hw782, hw783, hw784, hw785, hw786, hw787, ite_true, ite_false]
    dsimp [R]; try rfl
  · subst h_r_4
    dsimp [step, S_wave_4, S_wave_5]
    have hw788 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p) := by omega
    have hw789 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p + ↑m - 2) := by omega
    have hw790 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw791 : ¬(p + ↑m + 8 * ↑k + 4 < p) := by omega
    have hw792 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m - 2) := by omega
    have hw793 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw794 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p) := by omega
    have hw795 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p + ↑m - 2) := by omega
    have hw796 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw797 : ¬(p + ↑m + 8 * ↑k + 4 < p) := by omega
    have hw798 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m - 3) := by omega
    have hw799 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw788, hw789, hw790, hw791, hw792, hw793, hw794, hw795, hw796, hw797, hw798, hw799, ite_true, ite_false]
    dsimp [R]; try rfl
  · dsimp [step, S_wave_4, S_wave_5]
    have hw800 : ¬(i - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw801 : ¬(i < p + ↑m + 8 * ↑k + 2) := by omega
    have hw802 : ¬(i + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw803 : ¬(i < p + ↑m + 8 * ↑k + 2) := by omega
    simp only [hw800, hw801, hw802, hw803, ite_false]
    repeat (split <;> (try omega))
    all_goals (first | rfl | (dsimp [R]; first | rfl | decide))

theorem step_wave_6 (m k : Nat) (hm : m ≥ 6) (hk : k ≥ 6) (p : Int) :
    step (S_wave_5 m k p) = S_wave_6 m k p := by
  funext i
  have h_cases : i ≤ p + ↑m - 6 ∨ i = p + ↑m - 5 ∨ i = p + ↑m - 4 ∨ i = p + ↑m - 3 ∨ i = p + ↑m - 2 ∨ i = p + ↑m - 1 ∨ (i > p + ↑m - 1 ∧ i < p + ↑m + 8 * ↑k) ∨ i = p + ↑m + 8 * ↑k ∨ i = p + ↑m + 8 * ↑k + 1 ∨ i = p + ↑m + 8 * ↑k + 2 ∨ i = p + ↑m + 8 * ↑k + 3 ∨ i = p + ↑m + 8 * ↑k + 4 ∨ i = p + ↑m + 8 * ↑k + 5 ∨ i > p + ↑m + 8 * ↑k + 5 := by omega
  rcases h_cases with h_l | h_pt_m5 | h_pt_m4 | h_pt_m3 | h_pt_m2 | h_pt_m1 | ⟨h_bulk_L, h_bulk_R⟩ | h_r_0 | h_r_1 | h_r_2 | h_r_3 | h_r_4 | h_r_5 | h_end
  · dsimp [step, S_wave_5, S_wave_6]
    have hw804 : i - 1 < p + ↑m - 3 := by omega
    have hw805 : i < p + ↑m - 3 := by omega
    have hw806 : i + 1 < p + ↑m - 3 := by omega
    have hw807 : i - 1 < p + ↑m - 4 := by omega
    have hw808 : i < p + ↑m - 4 := by omega
    have hw809 : i + 1 < p + ↑m - 4 := by omega
    simp only [hw804, hw805, hw806, hw807, hw808, hw809, ite_true, ite_false]
    have h_3way : i < p - 1 ∨ i = p - 1 ∨ i ≥ p := by omega
    rcases h_3way with h_lo | h_mid | h_hi
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : i + 1 < p := by omega
      simp only [hLp1, hLp2, hLp3, ite_true]
      decide
    · have hLp1 : i - 1 < p := by omega
      have hLp2 : i < p := by omega
      have hLp3 : ¬(i + 1 < p) := by omega
      simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
      decide
    · have h_sub : i = p ∨ i > p := by omega
      rcases h_sub with h_eq | h_gt
      · have hLp1 : i - 1 < p := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_true, ite_false]
        decide
      · have hLp1 : ¬(i - 1 < p) := by omega
        have hLp2 : ¬(i < p) := by omega
        have hLp3 : ¬(i + 1 < p) := by omega
        simp only [hLp1, hLp2, hLp3, ite_false]
        decide
  · subst h_pt_m5
    dsimp [step, S_wave_5, S_wave_6]
    have hw810 : ¬(p + ↑m - 5 - 1 < p) := by omega
    have hw811 : p + ↑m - 5 - 1 < p + ↑m - 3 := by omega
    have hw812 : ¬(p + ↑m - 5 < p) := by omega
    have hw813 : p + ↑m - 5 < p + ↑m - 3 := by omega
    have hw814 : ¬(p + ↑m - 5 + 1 < p) := by omega
    have hw815 : p + ↑m - 5 + 1 < p + ↑m - 3 := by omega
    have hw816 : ¬(p + ↑m - 5 < p) := by omega
    have hw817 : p + ↑m - 5 < p + ↑m - 4 := by omega
    simp only [hw810, hw811, hw812, hw813, hw814, hw815, hw816, hw817, ite_true, ite_false]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m4
    dsimp [step, S_wave_5, S_wave_6]
    have hw818 : ¬(p + ↑m - 4 - 1 < p) := by omega
    have hw819 : p + ↑m - 4 - 1 < p + ↑m - 3 := by omega
    have hw820 : ¬(p + ↑m - 4 < p) := by omega
    have hw821 : p + ↑m - 4 < p + ↑m - 3 := by omega
    have hw822 : ¬(p + ↑m - 4 + 1 < p) := by omega
    have hw823 : ¬(p + ↑m - 4 + 1 < p + ↑m - 3) := by omega
    have hw824 : p + ↑m - 4 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw825 : ¬(p + ↑m - 4 < p) := by omega
    have hw826 : ¬(p + ↑m - 4 < p + ↑m - 4) := by omega
    have hw827 : p + ↑m - 4 < p + ↑m + 8 * ↑k + 3 := by omega
    simp only [hw818, hw819, hw820, hw821, hw822, hw823, hw824, hw825, hw826, hw827, ite_true, ite_false]
    have hw828 : p + ↑m - 4 + 1 - (p + ↑m + 1) = (-4) := by omega
    try rw [hw828]
    have hw829 : p + ↑m - 4 - (p + ↑m + 2) = (-6) := by omega
    try rw [hw829]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m3
    dsimp [step, S_wave_5, S_wave_6]
    have hw830 : ¬(p + ↑m - 3 - 1 < p) := by omega
    have hw831 : p + ↑m - 3 - 1 < p + ↑m - 3 := by omega
    have hw832 : ¬(p + ↑m - 3 < p) := by omega
    have hw833 : ¬(p + ↑m - 3 < p + ↑m - 3) := by omega
    have hw834 : p + ↑m - 3 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw835 : ¬(p + ↑m - 3 + 1 < p) := by omega
    have hw836 : ¬(p + ↑m - 3 + 1 < p + ↑m - 3) := by omega
    have hw837 : p + ↑m - 3 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw838 : ¬(p + ↑m - 3 < p) := by omega
    have hw839 : ¬(p + ↑m - 3 < p + ↑m - 4) := by omega
    have hw840 : p + ↑m - 3 < p + ↑m + 8 * ↑k + 3 := by omega
    simp only [hw830, hw831, hw832, hw833, hw834, hw835, hw836, hw837, hw838, hw839, hw840, ite_true, ite_false]
    have hw841 : p + ↑m - 3 - (p + ↑m + 1) = (-4) := by omega
    try rw [hw841]
    have hw842 : p + ↑m - 3 + 1 - (p + ↑m + 1) = (-3) := by omega
    try rw [hw842]
    have hw843 : p + ↑m - 3 - (p + ↑m + 2) = (-5) := by omega
    try rw [hw843]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m2
    dsimp [step, S_wave_5, S_wave_6]
    have hw844 : ¬(p + ↑m - 2 - 1 < p) := by omega
    have hw845 : ¬(p + ↑m - 2 - 1 < p + ↑m - 3) := by omega
    have hw846 : p + ↑m - 2 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw847 : ¬(p + ↑m - 2 < p) := by omega
    have hw848 : ¬(p + ↑m - 2 < p + ↑m - 3) := by omega
    have hw849 : p + ↑m - 2 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw850 : ¬(p + ↑m - 2 + 1 < p) := by omega
    have hw851 : ¬(p + ↑m - 2 + 1 < p + ↑m - 3) := by omega
    have hw852 : p + ↑m - 2 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw853 : ¬(p + ↑m - 2 < p) := by omega
    have hw854 : ¬(p + ↑m - 2 < p + ↑m - 4) := by omega
    have hw855 : p + ↑m - 2 < p + ↑m + 8 * ↑k + 3 := by omega
    simp only [hw844, hw845, hw846, hw847, hw848, hw849, hw850, hw851, hw852, hw853, hw854, hw855, ite_true, ite_false]
    have hw856 : p + ↑m - 2 - 1 - (p + ↑m + 1) = (-4) := by omega
    try rw [hw856]
    have hw857 : p + ↑m - 2 - (p + ↑m + 1) = (-3) := by omega
    try rw [hw857]
    have hw858 : p + ↑m - 2 + 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw858]
    have hw859 : p + ↑m - 2 - (p + ↑m + 2) = (-4) := by omega
    try rw [hw859]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · subst h_pt_m1
    dsimp [step, S_wave_5, S_wave_6]
    have hw860 : ¬(p + ↑m - 1 - 1 < p) := by omega
    have hw861 : ¬(p + ↑m - 1 - 1 < p + ↑m - 3) := by omega
    have hw862 : p + ↑m - 1 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw863 : ¬(p + ↑m - 1 < p) := by omega
    have hw864 : ¬(p + ↑m - 1 < p + ↑m - 3) := by omega
    have hw865 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw866 : ¬(p + ↑m - 1 + 1 < p) := by omega
    have hw867 : ¬(p + ↑m - 1 + 1 < p + ↑m - 3) := by omega
    have hw868 : p + ↑m - 1 + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw869 : ¬(p + ↑m - 1 < p) := by omega
    have hw870 : ¬(p + ↑m - 1 < p + ↑m - 4) := by omega
    have hw871 : p + ↑m - 1 < p + ↑m + 8 * ↑k + 3 := by omega
    simp only [hw860, hw861, hw862, hw863, hw864, hw865, hw866, hw867, hw868, hw869, hw870, hw871, ite_true, ite_false]
    have hw872 : p + ↑m - 1 - 1 - (p + ↑m + 1) = (-3) := by omega
    try rw [hw872]
    have hw873 : p + ↑m - 1 - (p + ↑m + 1) = (-2) := by omega
    try rw [hw873]
    have hw874 : p + ↑m - 1 + 1 - (p + ↑m + 1) = (-1) := by omega
    try rw [hw874]
    have hw875 : p + ↑m - 1 - (p + ↑m + 2) = (-3) := by omega
    try rw [hw875]
    dsimp [B2, B0, R]
    repeat (split <;> (try omega))
    all_goals (first | rfl | decide)
  · dsimp [step, S_wave_5, S_wave_6]
    have hw876 : ¬ (i - 1 < p) := by omega
    have hw877 : ¬ (i < p) := by omega
    have hw878 : ¬ (i + 1 < p) := by omega
    have hw879 : ¬ (i - 1 < p + ↑m - 3) := by omega
    have hw880 : ¬ (i < p + ↑m - 3) := by omega
    have hw881 : ¬ (i + 1 < p + ↑m - 3) := by omega
    have hw882 : i - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw883 : i < p + ↑m + 8 * ↑k + 2 := by omega
    have hw884 : i + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw885 : ¬ (i < p + ↑m - 4) := by omega
    have hw886 : i < p + ↑m + 8 * ↑k + 3 := by omega
    simp only [hw876, hw877, hw878, hw879, hw880, hw881, hw882, hw883, hw884, hw885, hw886, ite_true, ite_false]
    have idx1 : i - 1 - (p + ↑m + 1) = i - (p + ↑m + 1) - 1 := by omega
    have idx2 : i + 1 - (p + ↑m + 1) = i - (p + ↑m + 1) + 1 := by omega
    try rw [idx1, idx2]
    have h_final := step_B2_to_B0 (i - (p + ↑m + 1))
    try rw [h_final]
    congr 1; omega
  · subst h_r_0
    dsimp [step, S_wave_5, S_wave_6]
    have hw887 : ¬(p + ↑m + 8 * ↑k - 1 < p) := by omega
    have hw888 : ¬(p + ↑m + 8 * ↑k - 1 < p + ↑m - 3) := by omega
    have hw889 : p + ↑m + 8 * ↑k - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw890 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw891 : ¬(p + ↑m + 8 * ↑k < p + ↑m - 3) := by omega
    have hw892 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 2 := by omega
    have hw893 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw894 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 3) := by omega
    have hw895 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw896 : ¬(p + ↑m + 8 * ↑k < p) := by omega
    have hw897 : ¬(p + ↑m + 8 * ↑k < p + ↑m - 4) := by omega
    have hw898 : p + ↑m + 8 * ↑k < p + ↑m + 8 * ↑k + 3 := by omega
    simp only [hw887, hw888, hw889, hw890, hw891, hw892, hw893, hw894, hw895, hw896, hw897, hw898, ite_true, ite_false]
    have hw899 : p + ↑m + 8 * ↑k - 1 - (p + ↑m + 1) = 8 * ↑k + (-2) := by omega
    try rw [hw899]
    have hw900 : p + ↑m + 8 * ↑k - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw900]
    have hw901 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw901]
    have hw902 : p + ↑m + 8 * ↑k - (p + ↑m + 2) = 8 * ↑k + (-2) := by omega
    try rw [hw902]
    have hw903 : (-2 : Int) % 8 = 6 := by decide
    have hw904 : (-1 : Int) % 8 = 7 := by decide
    simp only [B2, B0, mod_8k, hw903, hw904]
    dsimp [R]; try rfl
  · subst h_r_1
    dsimp [step, S_wave_5, S_wave_6]
    have hw905 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p) := by omega
    have hw906 : ¬(p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m - 3) := by omega
    have hw907 : p + ↑m + 8 * ↑k + 1 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw908 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw909 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 3) := by omega
    have hw910 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw911 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p) := by omega
    have hw912 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m - 3) := by omega
    have hw913 : ¬(p + ↑m + 8 * ↑k + 1 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw914 : ¬(p + ↑m + 8 * ↑k + 1 < p) := by omega
    have hw915 : ¬(p + ↑m + 8 * ↑k + 1 < p + ↑m - 4) := by omega
    have hw916 : p + ↑m + 8 * ↑k + 1 < p + ↑m + 8 * ↑k + 3 := by omega
    simp only [hw905, hw906, hw907, hw908, hw909, hw910, hw911, hw912, hw913, hw914, hw915, hw916, ite_true, ite_false]
    have hw917 : p + ↑m + 8 * ↑k + 1 - 1 - (p + ↑m + 1) = 8 * ↑k + (-1) := by omega
    try rw [hw917]
    have hw918 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw918]
    have hw919 : p + ↑m + 8 * ↑k + 1 - (p + ↑m + 2) = 8 * ↑k + (-1) := by omega
    try rw [hw919]
    have hw920 : (-1 : Int) % 8 = 7 := by decide
    simp only [B2, B0, mod_8k, hw920]
    dsimp [R]; try rfl
  · subst h_r_2
    dsimp [step, S_wave_5, S_wave_6]
    have hw921 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p) := by omega
    have hw922 : ¬(p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m - 3) := by omega
    have hw923 : p + ↑m + 8 * ↑k + 2 - 1 < p + ↑m + 8 * ↑k + 2 := by omega
    have hw924 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw925 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m - 3) := by omega
    have hw926 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw927 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p) := by omega
    have hw928 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m - 3) := by omega
    have hw929 : ¬(p + ↑m + 8 * ↑k + 2 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw930 : ¬(p + ↑m + 8 * ↑k + 2 < p) := by omega
    have hw931 : ¬(p + ↑m + 8 * ↑k + 2 < p + ↑m - 4) := by omega
    have hw932 : p + ↑m + 8 * ↑k + 2 < p + ↑m + 8 * ↑k + 3 := by omega
    simp only [hw921, hw922, hw923, hw924, hw925, hw926, hw927, hw928, hw929, hw930, hw931, hw932, ite_true, ite_false]
    have hw933 : p + ↑m + 8 * ↑k + 2 - 1 - (p + ↑m + 1) = 8 * ↑k + (0) := by omega
    try rw [hw933]
    have hw934 : p + ↑m + 8 * ↑k + 2 - (p + ↑m + 2) = 8 * ↑k + (0) := by omega
    try rw [hw934]
    simp only [B2, B0, mod_8k]
    dsimp [R]; try rfl
  · subst h_r_3
    dsimp [step, S_wave_5, S_wave_6]
    have hw935 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p) := by omega
    have hw936 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m - 3) := by omega
    have hw937 : ¬(p + ↑m + 8 * ↑k + 3 - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw938 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw939 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m - 3) := by omega
    have hw940 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw941 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p) := by omega
    have hw942 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m - 3) := by omega
    have hw943 : ¬(p + ↑m + 8 * ↑k + 3 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw944 : ¬(p + ↑m + 8 * ↑k + 3 < p) := by omega
    have hw945 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m - 4) := by omega
    have hw946 : ¬(p + ↑m + 8 * ↑k + 3 < p + ↑m + 8 * ↑k + 3) := by omega
    simp only [hw935, hw936, hw937, hw938, hw939, hw940, hw941, hw942, hw943, hw944, hw945, hw946, ite_true, ite_false]
    dsimp [R]; try rfl
  · subst h_r_4
    dsimp [step, S_wave_5, S_wave_6]
    have hw947 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p) := by omega
    have hw948 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p + ↑m - 3) := by omega
    have hw949 : ¬(p + ↑m + 8 * ↑k + 4 - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw950 : ¬(p + ↑m + 8 * ↑k + 4 < p) := by omega
    have hw951 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m - 3) := by omega
    have hw952 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw953 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p) := by omega
    have hw954 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p + ↑m - 3) := by omega
    have hw955 : ¬(p + ↑m + 8 * ↑k + 4 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw956 : ¬(p + ↑m + 8 * ↑k + 4 < p) := by omega
    have hw957 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m - 4) := by omega
    have hw958 : ¬(p + ↑m + 8 * ↑k + 4 < p + ↑m + 8 * ↑k + 3) := by omega
    simp only [hw947, hw948, hw949, hw950, hw951, hw952, hw953, hw954, hw955, hw956, hw957, hw958, ite_true, ite_false]
    dsimp [R]; try rfl
  · subst h_r_5
    dsimp [step, S_wave_5, S_wave_6]
    have hw959 : ¬(p + ↑m + 8 * ↑k + 5 - 1 < p) := by omega
    have hw960 : ¬(p + ↑m + 8 * ↑k + 5 - 1 < p + ↑m - 3) := by omega
    have hw961 : ¬(p + ↑m + 8 * ↑k + 5 - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw962 : ¬(p + ↑m + 8 * ↑k + 5 < p) := by omega
    have hw963 : ¬(p + ↑m + 8 * ↑k + 5 < p + ↑m - 3) := by omega
    have hw964 : ¬(p + ↑m + 8 * ↑k + 5 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw965 : ¬(p + ↑m + 8 * ↑k + 5 + 1 < p) := by omega
    have hw966 : ¬(p + ↑m + 8 * ↑k + 5 + 1 < p + ↑m - 3) := by omega
    have hw967 : ¬(p + ↑m + 8 * ↑k + 5 + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw968 : ¬(p + ↑m + 8 * ↑k + 5 < p) := by omega
    have hw969 : ¬(p + ↑m + 8 * ↑k + 5 < p + ↑m - 4) := by omega
    have hw970 : ¬(p + ↑m + 8 * ↑k + 5 < p + ↑m + 8 * ↑k + 3) := by omega
    simp only [hw959, hw960, hw961, hw962, hw963, hw964, hw965, hw966, hw967, hw968, hw969, hw970, ite_true, ite_false]
    dsimp [R]; try rfl
  · dsimp [step, S_wave_5, S_wave_6]
    have hw971 : ¬(i - 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw972 : ¬(i < p + ↑m + 8 * ↑k + 2) := by omega
    have hw973 : ¬(i + 1 < p + ↑m + 8 * ↑k + 2) := by omega
    have hw974 : ¬(i < p + ↑m + 8 * ↑k + 3) := by omega
    simp only [hw971, hw972, hw973, hw974, ite_false]
    repeat (split <;> (try omega))
    all_goals (first | rfl | (dsimp [R]; first | rfl | decide))

end CA
