import os

header = """import CA.Doubler

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
"""
cases = [
    ("h1 : i ≤ p - 2", "i"),
    ("h2 : i = p - 1", "p - 1"),
    ("h3 : i = p", "p"),
    ("h4 : p < i ∧ i < p + ↑n", "i"),
    ("h5 : i = p + ↑n", "p + ↑n"),
    ("h6 : i = p + (↑n + 1)", "p + (↑n + 1)"),
    ("h7 : i = p + ↑n + 2", "p + ↑n + 2"),
    ("h8 : p + ↑n + 2 < i", "i")
]

cond_templates = [
    "p ≤ {x} - 1 ∧ {x} - 1 < p + (↑n + 1)",
    "{x} - 1 = p + (↑n + 1)",
    "p ≤ {x} ∧ {x} < p + (↑n + 1)",
    "{x} = p + (↑n + 1)",
    "p ≤ {x} + 1 ∧ {x} + 1 < p + (↑n + 1)",
    "{x} + 1 = p + (↑n + 1)",
    "p ≤ {x} ∧ {x} < p + ↑n",
    "{x} = p + ↑n",
    "p + ↑n < {x} ∧ {x} ≤ p + ↑n + 2"
]

true_matrix = {
    0: [], 1: [4], 2: [2, 4, 6], 3: [0, 2, 4, 6],
    4: [0, 2, 5, 7],
    5: [0, 3, 8],
    6: [1, 8],
    7: []
}

out = header
for c_idx, (case_desc, x_val) in enumerate(cases):
    out += f"  by_cases {case_desc}\n"
    if "i =" in case_desc:
        out += f"  · rw [{case_desc.split(':')[0].strip()}]; simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,\n"
    else:
        out += f"  · simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,\n"
        
    for i, c in enumerate(cond_templates):
        # We replace {x} with x_val, then we global replace `p + ↑n + 1` with `p + (↑n + 1)`
        cond_str = c.replace("{x}", x_val).replace("p + ↑n + 1", "p + (↑n + 1)")
        
        is_true = (i in true_matrix[c_idx])
        if is_true:
            out += f"      show {cond_str} from by omega"
        else:
            out += f"      show ¬({cond_str}) from by omega"
            
        if i < len(cond_templates) - 1:
            out += ",\n"
        else:
            out += "]\n"

    # For h8, we do a nested case split fallback
    if c_idx == 7:
        out += "  · simp only [R, step, S_in, S_out, ite_false, ite_true, if_neg, if_pos, true_and, and_true, and_self, false_and, and_false,\n"
        for i, c in enumerate(cond_templates):
            cond_str = c.replace("{x}", "i").replace("p + ↑n + 1", "p + (↑n + 1)")
            out += f"      show ¬({cond_str}) from by omega"
            if i < len(cond_templates) - 1:
                out += ",\n"
            else:
                out += "]\n"

out += "\nend CA\n"

with open("/Users/swish/src/wolfram/CASearch/Proofs/CA/DoublerTrans.lean", "w") as f:
    f.write(out)
