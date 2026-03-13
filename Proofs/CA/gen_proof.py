import sys

def conds_S21(): return ["{i} = p", "p < {i} ∧ {i} ≤ p + (↑m + 1)"]
def conds_S10(): return ["{i} = p", "{i} = p + 1", "p + 1 < {i} ∧ {i} ≤ p + (↑m + 1)"]
def conds_S20(): return ["{i} = p", "{i} = p + 1", "p + 1 < {i} ∧ {i} ≤ p + (↑m + 1)"]
def conds_S1(): return ["p ≤ {i} ∧ {i} < p + (↑m + 2)"]

def evaluate_cond_S21(idx, name):
    # idx: offset from p
    if idx == 0: return [True, False]
    if idx > 0 and name != "m+2": return [False, True] # S21 has 1s up to p+m+1
    return [False, False]

def evaluate_cond_S10(idx, name):
    if idx == 0: return [True, False, False]
    if idx == 1: return [False, True, False]
    if idx > 1 and name != "m+2": return [False, False, True]
    return [False, False, False]

def evaluate_cond_S20(idx, name):
    if idx == 0: return [True, False, False]
    if idx == 1: return [False, True, False]
    if idx > 1 and name != "m+2": return [False, False, True]
    return [False, False, False]

def evaluate_cond_S1(idx, name):
    if idx >= 0 and name != "m+2" and name != "m+3": return [True]
    return [False]

def build_shows(conds_func, eval_func, target_str, idx, name):
    conds = conds_func()
    truth_vals = eval_func(idx, name)
    out = []
    for c, is_true in zip(conds, truth_vals):
        c_sub = c.replace("{i}", target_str)
        if is_true:
            out.append(f"show {c_sub} from by omega")
        else:
            out.append(f"show ¬({c_sub}) from by omega")
    return out

cases = [
    ("h1 : i ≤ p - 2", "i", -2, "left"),
    ("h2 : i = p - 1", "p - 1", -1, "p-1"),
    ("h3 : i = p", "p", 0, "p"),
    ("h4 : i = p + 1", "p + 1", 1, "p+1"),
    ("h5 : i = p + 2", "p + 2", 2, "p+2"),
    ("h6 : p + 2 < i ∧ i < p + (↑m + 1)", "i", 3, "mid"), # uses i
    ("h7 : i = p + (↑m + 1)", "p + (↑m + 1)", 5, "m+1"),
    ("h8 : i = p + (↑m + 1) + 1", "p + (↑m + 1) + 1", 6, "m+2"),
    ("h9 : p + (↑m + 1) + 1 < i", "i", 7, "m+3")
]

simp_tail = "R, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false"

def generate_theorem(name, S_in, S_out, is_step1=False):
    S_funcs = {"S21": (conds_S21, evaluate_cond_S21), "S10": (conds_S10, evaluate_cond_S10), "S20": (conds_S20, evaluate_cond_S20), "S1": (conds_S1, evaluate_cond_S1)}
    c_in, e_in = S_funcs[S_in]
    c_out, e_out = S_funcs[S_out]
    
    print(f"theorem {name} (m : Nat) (hm : m ≥ 1) (p : Int) :")
    print(f"    step ({S_in} m p) = {S_out} m p := by")
    print(f"  funext i; simp only [step, {S_in}, {S_out}]")
    
    local_cases = cases
    if is_step1: # step 1 grouped interior
        local_cases = [
            ("h1 : i ≤ p - 2", "i", -2, "left"),
            ("h2 : i = p - 1", "p - 1", -1, "p-1"),
            ("h3 : i = p", "p", 0, "p"),
            ("h4 : i = p + 1", "p + 1", 1, "p+1"),
            ("h5 : p + 1 < i ∧ i < p + (↑m + 1)", "i", 2, "mid"),
            ("h6 : i = p + (↑m + 1)", "p + (↑m + 1)", 5, "m+1"),
            ("h7 : i = p + (↑m + 1) + 1", "p + (↑m + 1) + 1", 6, "m+2"),
            ("h8 : p + (↑m + 1) + 1 < i", "i", 7, "m+3")
        ]
        
    for h_line, rep_str, idx, cname in local_cases:
        print(f"  by_cases {h_line}")
        if "i =" in h_line:
            print(f"  · subst {h_line.split(':')[0].strip()}")
        else:
            print(f"  ·")
        
        # build show list
        shows = []
        if rep_str == "i":
            shows += build_shows(c_in, e_in, rep_str + " - 1", idx - 1, cname)
            shows += build_shows(c_in, e_in, rep_str, idx, cname)
            shows += build_shows(c_in, e_in, rep_str + " + 1", idx + 1, cname)
            shows += build_shows(c_out, e_out, rep_str, idx, cname)
        else:
            shows += build_shows(c_in, e_in, rep_str + " - 1", idx - 1, cname)
            shows += build_shows(c_in, e_in, rep_str, idx, cname)
            shows += build_shows(c_in, e_in, rep_str + " + 1", idx + 1, cname)
            shows += build_shows(c_out, e_out, rep_str, idx, cname)
            
        print(f"    simp only [{', '.join(shows)}, {simp_tail}]")
        
    print()

header = """/-
  Rule110.Doubler
-/

namespace CA

def R (idx : Nat) : Nat :=
  match idx with
  |  0 => 0 |  1 => 0 |  2 => 0  |  3 => 2 |  4 => 1 |  5 => 2
  |  6 => 1 |  7 => 1 |  8 => 2  |  9 => 0 | 10 => 0 | 11 => 0
  | 12 => 1 | 13 => 1 | 14 => 2  | 15 => 1 | 16 => 2 | 17 => 1
  | 18 => 1 | 19 => 1 | 20 => 0  | 21 => 2 | 22 => 0 | 23 => 2
  | 24 => 1 | 25 => 1 | _  => 2

def Tape := Int → Nat
def step (tape : Tape) : Tape := fun i => R (tape (i - 1) * 9 + tape i * 3 + tape (i + 1))

def evolve (tape : Tape) : Nat → Tape
  | 0 => tape
  | t + 1 => step (evolve tape t)

def stepV (w : Nat) (hw : w > 0) (tape : Vector Nat w) : Vector Nat w :=
  Vector.ofFn fun (i : Fin w) =>
    R (tape[(i.val + w - 1) % w]'(Nat.mod_lt _ hw) % 3 * 9 + tape[i] % 3 * 3 + tape[(i.val + 1) % w]'(Nat.mod_lt _ hw) % 3)

def evolveV (w : Nat) (hw : w > 0) (tape : Vector Nat w) : Nat → Vector Nat w
  | 0 => tape
  | t + 1 => stepV w hw (evolveV w hw tape t)

theorem doubler_n1 : evolveV 16 (by omega) (#v[0,0,0,0,0,0,0,2,0,0,0,0,0,0,0,0]) 2 = (#v[0,0,0,0,0,0,0,1,1,0,0,0,0,0,0,0]) := by native_decide
theorem doubler_n2 : evolveV 20 (by omega) (#v[0,0,0,0,0,0,0,0,1,2,0,0,0,0,0,0,0,0,0,0]) 7 = (#v[0,0,0,0,0,0,0,0,1,1,1,1,0,0,0,0,0,0,0,0]) := by native_decide
theorem doubler_n3 : evolveV 30 (by omega) (#v[0,0,0,0,0,0,0,0,0,0,0,0,1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) 16 = (#v[0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0]) := by native_decide
theorem doubler_n4 : evolveV 40 (by omega) (#v[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) 21 = (#v[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) := by native_decide
theorem doubler_n5 : evolveV 50 (by omega) (#v[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) 28 = (#v[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,1,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]) := by native_decide

def S21 (m : Nat) (p : Int) : Tape := fun i => if i = p then 2 else if p < i ∧ i ≤ p + (↑m + 1) then 1 else 0
def S10 (m : Nat) (p : Int) : Tape := fun i => if i = p then 1 else if i = p + 1 then 0 else if p + 1 < i ∧ i ≤ p + (↑m + 1) then 1 else 0
def S20 (m : Nat) (p : Int) : Tape := fun i => if i = p then 2 else if i = p + 1 then 0 else if p + 1 < i ∧ i ≤ p + (↑m + 1) then 1 else 0
def S1 (m : Nat) (p : Int) : Tape := fun i => if p ≤ i ∧ i < p + (↑m + 2) then 1 else 0
"""

with open("DoublerGen.lean", "w") as f:
    f.write(header)
    
    old_stdout = sys.stdout
    sys.stdout = f
    
    generate_theorem("tail_step1", "S21", "S10", is_step1=True)
    generate_theorem("tail_step2", "S10", "S20")
    generate_theorem("tail_step3", "S20", "S1")
    
    sys.stdout = old_stdout
    
    f.write("""
theorem convergence_tail (m : Nat) (hm : m ≥ 1) (p : Int) :
    evolve (S21 m p) 3 = S1 m p := by
  simp only [evolve, tail_step1 m hm p, tail_step2 m hm p, tail_step3 m hm p]

end CA
""")

