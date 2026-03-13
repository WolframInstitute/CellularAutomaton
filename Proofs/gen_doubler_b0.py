#!/usr/bin/env python3
"""
Generate DoublerB0.lean - v13. Fixed from v12:
- Point case `rw` uses EXACT post-subst expressions (p + ↑m + val + dx, not p + ↑m + (val+dx))
- Right-end: prove all ¬ conditions including neighbors at p + m + 8k + val ± 1
"""

rule = 6424447839471
R_table = []
tmp = rule
for i in range(27):
    R_table.append(tmp % 3)
    tmp //= 3

B_vals = {
    "B0": [1, 1, 2, 2, 0, 1, 2, 1],
    "B1": [1, 2, 1, 1, 1, 2, 2, 0],
    "B2": [2, 2, 0, 1, 2, 1, 1, 1],
}

L_shifts = [2, 1, 0, -1, -2, -3, -4]
R_shifts = [1, 1, 1, 2, 2, 2, 3]
offsets = [0, 0, 0, 1, 1, 1, 2]
b_names = ["B0", "B1", "B2", "B0", "B1", "B2", "B0"]

def get_lean_expr(m_shift):
    if m_shift > 0: return f"p + ↑m + {m_shift}"
    elif m_shift < 0: return f"p + ↑m - {-m_shift}"
    else: return "p + ↑m"

def get_lean_r_expr(r_shift):
    if r_shift > 0: return f"p + ↑m + 8 * ↑k + {r_shift}"
    elif r_shift < 0: return f"p + ↑m + 8 * ↑k - {-r_shift}"
    else: return "p + ↑m + 8 * ↑k"

out = []
out.append("import CA.Doubler")
out.append("namespace CA")
out.append("set_option maxHeartbeats 200000000")
out.append("")

out.append("""def B0 (idx : Int) : Nat :=
  if idx % 8 = 0 then 1 else if idx % 8 = 1 then 1 else if idx % 8 = 2 then 2 else if idx % 8 = 3 then 2 else if idx % 8 = 4 then 0 else if idx % 8 = 5 then 1 else if idx % 8 = 6 then 2 else if idx % 8 = 7 then 1 else 0

def B1 (idx : Int) : Nat :=
  if idx % 8 = 0 then 1 else if idx % 8 = 1 then 2 else if idx % 8 = 2 then 1 else if idx % 8 = 3 then 1 else if idx % 8 = 4 then 1 else if idx % 8 = 5 then 2 else if idx % 8 = 6 then 2 else if idx % 8 = 7 then 0 else 0

def B2 (idx : Int) : Nat :=
  if idx % 8 = 0 then 2 else if idx % 8 = 1 then 2 else if idx % 8 = 2 then 0 else if idx % 8 = 3 then 1 else if idx % 8 = 4 then 2 else if idx % 8 = 5 then 1 else if idx % 8 = 6 then 1 else if idx % 8 = 7 then 1 else 0

@[simp] theorem mod_8k (k : Nat) (c : Int) : (8 * (k : Int) + c) % 8 = c % 8 := by omega
""")

for src, dst, dst_expr in [("B0", "B1", "B1 m"), ("B1", "B2", "B2 m"), ("B2", "B0", "B0 (m - 1)")]:
    out.append(f"theorem step_{src}_to_{dst} (m : Int) : R ({src} (m - 1) * 9 + {src} m * 3 + {src} (m + 1)) = {dst_expr} := by")
    out.append(f"  dsimp [{src}, {dst}, R]")
    out.append("  have hmod : m % 8 = 0 ∨ m % 8 = 1 ∨ m % 8 = 2 ∨ m % 8 = 3 ∨ m % 8 = 4 ∨ m % 8 = 5 ∨ m % 8 = 6 ∨ m % 8 = 7 := by omega")
    out.append("  rcases hmod with h | h | h | h | h | h | h | h")
    for i in range(8):
        m_minus = (i - 1) % 8; m_plus = (i + 1) % 8
        out.append(f"  · have h1 : (m - 1) % 8 = {m_minus} := (by omega); have h2 : (m + 1) % 8 = {m_plus} := (by omega); rw [h, h1, h2]; decide")
    out.append("")

for t in range(7):
    L_expr = get_lean_expr(L_shifts[t])
    R_expr = get_lean_r_expr(R_shifts[t])
    offset_expr = get_lean_expr(offsets[t])
    opts = []
    opts.append(f"def S_wave_{t} (m k : Nat) (p : Int) : Tape := fun i =>")
    opts.append(f"  if i < p then 0")
    opts.append(f"  else if i < {L_expr} then 1")
    opts.append(f"  else if i < {R_expr} then {b_names[t]} (i - ({offset_expr}))")
    opts.append(f"  else 0\n")
    out.append("\n".join(opts))

hw_id = 0
def get_hw():
    global hw_id
    hw_id += 1
    return f"hw{hw_id}"

for t in range(1, 7):
    src_B = b_names[t-1]
    dst_B = b_names[t]
    prev_L = L_shifts[t-1]
    curr_L = L_shifts[t]
    prev_R = R_shifts[t-1]
    curr_R = R_shifts[t]
    prev_off = offsets[t-1]
    curr_off = offsets[t]
    prev_off_expr = get_lean_expr(prev_off)
    curr_off_expr = get_lean_expr(curr_off)
    
    out.append(f"theorem step_wave_{t} (m k : Nat) (hm : m ≥ 6) (hk : k ≥ 6) (p : Int) :")
    out.append(f"    step (S_wave_{t-1} m k p) = S_wave_{t} m k p := by")
    out.append(f"  funext i")
    
    min_L = min(prev_L, curr_L) - 2
    max_L = max(prev_L, curr_L) + 2
    min_R = min(prev_R, curr_R) - 2
    max_R = max(prev_R, curr_R) + 2
    
    cases_strs = []
    names = []
    cases_strs.append(f"i ≤ {get_lean_expr(min_L)}")
    names.append("h_l")
    for pt_val in range(min_L + 1, max_L + 1):
        cases_strs.append(f"i = {get_lean_expr(pt_val)}")
        nm = f"h_pt_{pt_val}".replace('-', 'm')
        names.append(nm)
    cases_strs.append(f"(i > {get_lean_expr(max_L)} ∧ i < {get_lean_r_expr(min_R)})")
    names.append("⟨h_bulk_L, h_bulk_R⟩")
    for pt_val in range(min_R, max_R + 1):
        cases_strs.append(f"i = {get_lean_r_expr(pt_val)}")
        nm = f"h_r_{pt_val}".replace('-', 'm')
        names.append(nm)
    cases_strs.append(f"i > {get_lean_r_expr(max_R)}")
    names.append("h_end")
    
    or_tree = " ∨ ".join(cases_strs)
    out.append(f"  have h_cases : {or_tree} := by omega")
    out.append(f"  rcases h_cases with {' | '.join(names)}")
    
    # ====== LEFT BULK ======
    # All neighbors are in the 0-or-1 zone (< p → 0, ≥ p → 1).
    # We need to case-split on whether each neighbor is < p or ≥ p.
    # The valid cases are: i < p-1 (all 0s), i = p-1 ([0,0,1]), i ≥ p (all 1s)
    out.append(f"  · dsimp [step, S_wave_{t-1}, S_wave_{t}]")
    hw_list = []
    for cond in [f"i - 1 < {get_lean_expr(prev_L)}", f"i < {get_lean_expr(prev_L)}", f"i + 1 < {get_lean_expr(prev_L)}",
                 f"i - 1 < {get_lean_expr(curr_L)}", f"i < {get_lean_expr(curr_L)}", f"i + 1 < {get_lean_expr(curr_L)}"]:
        hn = get_hw(); out.append(f"    have {hn} : {cond} := by omega"); hw_list.append(hn)
    out.append(f"    simp only [{', '.join(hw_list)}, ite_true, ite_false]")
    # Now goal has: R((if i-1<p then 0 else 1)*9 + (if i<p then 0 else 1)*3 + (if i+1<p then 0 else 1)) = if i<p then 0 else 1
    # Case split on i relative to p
    out.append(f"    have h_3way : i < p - 1 ∨ i = p - 1 ∨ i ≥ p := by omega")
    out.append(f"    rcases h_3way with h_lo | h_mid | h_hi")
    # Case 1: i < p-1, all cells = 0, R(0)=0, target=0
    out.append(f"    · have hLp1 : i - 1 < p := by omega")
    out.append(f"      have hLp2 : i < p := by omega")
    out.append(f"      have hLp3 : i + 1 < p := by omega")
    out.append(f"      simp only [hLp1, hLp2, hLp3, ite_true]")
    out.append("      decide")
    # Case 2: i = p-1, cells = [0,0,1], R(1)=0, target=0
    out.append(f"    · have hLp1 : i - 1 < p := by omega")
    out.append(f"      have hLp2 : i < p := by omega")
    out.append(f"      have hLp3 : ¬(i + 1 < p) := by omega")
    out.append(f"      simp only [hLp1, hLp2, hLp3, ite_true, ite_false]")
    out.append("      decide")
    # Case 3: i ≥ p. Sub-cases: i=p → [0,1,1], i>p → [1,1,1]
    out.append(f"    · have h_sub : i = p ∨ i > p := by omega")
    out.append(f"      rcases h_sub with h_eq | h_gt")
    out.append(f"      · have hLp1 : i - 1 < p := by omega")
    out.append(f"        have hLp2 : ¬(i < p) := by omega")
    out.append(f"        have hLp3 : ¬(i + 1 < p) := by omega")
    out.append(f"        simp only [hLp1, hLp2, hLp3, ite_true, ite_false]")
    out.append("        decide")
    out.append(f"      · have hLp1 : ¬(i - 1 < p) := by omega")
    out.append(f"        have hLp2 : ¬(i < p) := by omega")
    out.append(f"        have hLp3 : ¬(i + 1 < p) := by omega")
    out.append(f"        simp only [hLp1, hLp2, hLp3, ite_false]")
    out.append("        decide")
    
    # ====== LEFT POINT CASES ======
    for pt_val in range(min_L + 1, max_L + 1):
        nm = f"h_pt_{pt_val}".replace('-', 'm')
        out.append(f"  · subst {nm}")
        out.append(f"    dsimp [step, S_wave_{t-1}, S_wave_{t}]")
        
        # After subst, i is replaced by (p + ↑m + pt_val) or (p + ↑m - |pt_val|)
        # Neighbors: (p + ↑m + pt_val) - 1 and (p + ↑m + pt_val) + 1
        # These are LITERAL expressions in the goal, NOT simplified
        
        # For the center cell i = p + ↑m + pt_val:
        # Source tape: if (p+m+pt_val) < p? No (since m≥6, pt_val > -6)
        #   if (p+m+pt_val) < p+m+prev_L? Depends on pt_val
        # etc.
        
        # Build the EXACT expression string after subst
        def pt_expr_str(pt):
            """Exact Lean expression for p + ↑m + pt"""
            if pt > 0: return f"p + ↑m + {pt}"
            elif pt < 0: return f"p + ↑m - {-pt}"
            else: return "p + ↑m"
        
        center_expr = pt_expr_str(pt_val)
        
        hw_list_pt = []
        # For each neighbor: the EXACT expression after subst is:
        # neighbor -1: (center_expr) - 1
        # neighbor 0: center_expr  
        # neighbor +1: (center_expr) + 1
        for dx_str, dx, dx_lean_suffix in [(" - 1", -1, " - 1"), ("", 0, ""), (" + 1", 1, " + 1")]:
            neighbor_expr = f"{center_expr}{dx_lean_suffix}"
            actual = pt_val + dx
            
            # ¬(neighbor < p)
            hn = get_hw()
            out.append(f"    have {hn} : ¬({neighbor_expr} < p) := by omega")
            hw_list_pt.append(hn)
            
            # is neighbor < prev_L?
            hn = get_hw()
            if actual < prev_L:
                out.append(f"    have {hn} : {neighbor_expr} < {get_lean_expr(prev_L)} := by omega")
                hw_list_pt.append(hn)
            else:
                out.append(f"    have {hn} : ¬({neighbor_expr} < {get_lean_expr(prev_L)}) := by omega")
                hw_list_pt.append(hn)
                hn = get_hw()
                out.append(f"    have {hn} : {neighbor_expr} < {get_lean_r_expr(prev_R)} := by omega")
                hw_list_pt.append(hn)
        
        # Target side
        hn = get_hw()
        out.append(f"    have {hn} : ¬({center_expr} < p) := by omega")
        hw_list_pt.append(hn)
        hn = get_hw()
        if pt_val < curr_L:
            out.append(f"    have {hn} : {center_expr} < {get_lean_expr(curr_L)} := by omega")
            hw_list_pt.append(hn)
        else:
            out.append(f"    have {hn} : ¬({center_expr} < {get_lean_expr(curr_L)}) := by omega")
            hw_list_pt.append(hn)
            hn = get_hw()
            out.append(f"    have {hn} : {center_expr} < {get_lean_r_expr(curr_R)} := by omega")
            hw_list_pt.append(hn)
        
        out.append(f"    simp only [{', '.join(hw_list_pt)}, ite_true, ite_false]")
        
        # Now resolve B-zone arguments to concrete values
        # After simp, B-zone cells have B0(neighbor_expr - (prev_off_expr))
        # We need to rw these to concrete integers
        for dx_str, dx, dx_lean_suffix in [(" - 1", -1, " - 1"), ("", 0, ""), (" + 1", 1, " + 1")]:
            actual = pt_val + dx
            if actual >= prev_L:
                neighbor_expr = f"{center_expr}{dx_lean_suffix}"
                idx_val = actual - prev_off
                hn = get_hw()
                out.append(f"    have {hn} : {neighbor_expr} - ({prev_off_expr}) = ({idx_val}) := by omega")
                out.append(f"    try rw [{hn}]")
        
        # Target B-zone argument
        if pt_val >= curr_L:
            idx_val = pt_val - curr_off
            hn = get_hw()
            out.append(f"    have {hn} : {center_expr} - ({curr_off_expr}) = ({idx_val}) := by omega")
            out.append(f"    try rw [{hn}]")
        
        # Now dsimp evaluates concrete B0/B1/B2 lookups and R
        out.append(f"    dsimp [{src_B}, {dst_B}, R]")
        out.append(f"    repeat (split <;> (try omega))")
        out.append(f"    all_goals (first | rfl | decide)")
        
    # ====== CENTER BULK ======
    out.append(f"  · dsimp [step, S_wave_{t-1}, S_wave_{t}]")
    hw_list = []
    for cond in ["i - 1 < p", "i < p", "i + 1 < p",
                f"i - 1 < {get_lean_expr(prev_L)}", f"i < {get_lean_expr(prev_L)}", f"i + 1 < {get_lean_expr(prev_L)}"]:
        hn = get_hw(); out.append(f"    have {hn} : ¬ ({cond}) := by omega"); hw_list.append(hn)
    for cond in [f"i - 1 < {get_lean_r_expr(prev_R)}", f"i < {get_lean_r_expr(prev_R)}", f"i + 1 < {get_lean_r_expr(prev_R)}"]:
        hn = get_hw(); out.append(f"    have {hn} : {cond} := by omega"); hw_list.append(hn)
    hn = get_hw(); out.append(f"    have {hn} : ¬ (i < {get_lean_expr(curr_L)}) := by omega"); hw_list.append(hn)
    hn = get_hw(); out.append(f"    have {hn} : i < {get_lean_r_expr(curr_R)} := by omega"); hw_list.append(hn)
    
    out.append(f"    simp only [{', '.join(hw_list)}, ite_true, ite_false]")
    out.append(f"    have idx1 : i - 1 - ({prev_off_expr}) = i - ({prev_off_expr}) - 1 := by omega")
    out.append(f"    have idx2 : i + 1 - ({prev_off_expr}) = i - ({prev_off_expr}) + 1 := by omega")
    out.append(f"    try rw [idx1, idx2]")
    out.append(f"    have h_final := step_{src_B}_to_{dst_B} (i - ({prev_off_expr}))")
    out.append(f"    try rw [h_final]")
    if prev_off != curr_off: 
        out.append(f"    congr 1; omega")
    
    # ====== RIGHT POINT CASES ======
    for pt_val in range(min_R, max_R + 1):
        nm = f"h_r_{pt_val}".replace('-', 'm')
        out.append(f"  · subst {nm}")
        out.append(f"    dsimp [step, S_wave_{t-1}, S_wave_{t}]")
        
        def r_pt_expr_str(v):
            if v > 0: return f"p + ↑m + 8 * ↑k + {v}"
            elif v < 0: return f"p + ↑m + 8 * ↑k - {-v}"
            else: return "p + ↑m + 8 * ↑k"
            
        center_r = r_pt_expr_str(pt_val)
        
        hw_list_r = []
        for dx_str, dx, dx_lean_suffix in [(" - 1", -1, " - 1"), ("", 0, ""), (" + 1", 1, " + 1")]:
            neighbor_r = f"{center_r}{dx_lean_suffix}"
            actual = pt_val + dx
            
            hn = get_hw()
            out.append(f"    have {hn} : ¬({neighbor_r} < p) := by omega"); hw_list_r.append(hn)
            hn = get_hw()
            out.append(f"    have {hn} : ¬({neighbor_r} < {get_lean_expr(prev_L)}) := by omega"); hw_list_r.append(hn)
            hn = get_hw()
            if actual < prev_R:
                out.append(f"    have {hn} : {neighbor_r} < {get_lean_r_expr(prev_R)} := by omega"); hw_list_r.append(hn)
            else:
                out.append(f"    have {hn} : ¬({neighbor_r} < {get_lean_r_expr(prev_R)}) := by omega"); hw_list_r.append(hn)
        
        # Target
        hn = get_hw()
        out.append(f"    have {hn} : ¬({center_r} < p) := by omega"); hw_list_r.append(hn)
        hn = get_hw()
        out.append(f"    have {hn} : ¬({center_r} < {get_lean_expr(curr_L)}) := by omega"); hw_list_r.append(hn)
        hn = get_hw()
        if pt_val < curr_R:
            out.append(f"    have {hn} : {center_r} < {get_lean_r_expr(curr_R)} := by omega"); hw_list_r.append(hn)
        else:
            out.append(f"    have {hn} : ¬({center_r} < {get_lean_r_expr(curr_R)}) := by omega"); hw_list_r.append(hn)
                
        out.append(f"    simp only [{', '.join(hw_list_r)}, ite_true, ite_false]")
        
        # Resolve B-zone offsets for neighbors in B-zone (EXACT post-subst expressions)
        for dx_str, dx, dx_lean_suffix in [(" - 1", -1, " - 1"), ("", 0, ""), (" + 1", 1, " + 1")]:
            actual = pt_val + dx
            if actual < prev_R:
                neighbor_r = f"{center_r}{dx_lean_suffix}"
                net = actual - prev_off
                hn = get_hw()
                out.append(f"    have {hn} : {neighbor_r} - ({prev_off_expr}) = 8 * ↑k + ({net}) := by omega")
                out.append(f"    try rw [{hn}]")
        
        # Target offset
        if pt_val < curr_R:
            net = pt_val - curr_off
            hn = get_hw()
            out.append(f"    have {hn} : {center_r} - ({curr_off_expr}) = 8 * ↑k + ({net}) := by omega")
            out.append(f"    try rw [{hn}]")
        
        # Fully concrete approach: compute everything in Python, emit have lemmas
        # After simp + rw, the source cells are B_src(8k+net_l), B_src(8k+net_c), B_src(8k+net_r)
        # and target is B_dst(8k+net_t). Use mod_8k to show (8k+c)%8 = c%8, then
        # emit concrete values for all B lookups and R.
        
        cell_vals = []
        b_src_vals = B_vals[src_B]
        for dx_str, dx, dx_lean_suffix in [(" - 1", -1, " - 1"), ("", 0, ""), (" + 1", 1, " + 1")]:
            actual = pt_val + dx
            if actual < prev_R:
                net = actual - prev_off
                mod_val = net % 8
                cell_vals.append(b_src_vals[mod_val])
            else:
                cell_vals.append(0)  # Outside B-zone = 0
        
        r_input = cell_vals[0] * 9 + cell_vals[1] * 3 + cell_vals[2]
        r_output = R_table[r_input]
        
        if pt_val < curr_R:
            b_dst_vals = B_vals[dst_B]
            net_t = pt_val - curr_off  
            mod_t = net_t % 8
            target_val = b_dst_vals[mod_t]
        else:
            target_val = 0
        
        assert r_output == target_val, f"Mismatch at right pt {pt_val} in step_wave_{t}: R({r_input})={r_output} != {target_val}"
        
        # Now emit the proof: compute R(source) concretely
        # The source argument expressions are already concrete (rw resolved them)
        # or they are 0 (outside B-zone). After simp, the goal should be:
        # R(src_cell_l * 9 + src_cell_c * 3 + src_cell_r) = target_val
        # where src_cell_x are either B_src(8k + net) or 0
        
        # Emit mod lemmas for negative values
        neg_mods = set()
        for dx_str, dx, dx_lean_suffix in [(" - 1", -1, " - 1"), ("", 0, ""), (" + 1", 1, " + 1")]:
            actual = pt_val + dx
            if actual < prev_R:
                net = actual - prev_off
                if net < 0:
                    neg_mods.add(net)
        if pt_val < curr_R:
            net_t = pt_val - curr_off  
            if net_t < 0:
                neg_mods.add(net_t)
        
        # Check if any neighbor or target is actually in B-zone
        any_in_bzone = False
        for dx in [-1, 0, 1]:
            if pt_val + dx < prev_R:
                any_in_bzone = True
        if pt_val < curr_R:
            any_in_bzone = True
        
        if any_in_bzone:
            if neg_mods:
                mod_lemmas = []
                for neg_val in sorted(neg_mods):
                    hn = get_hw()
                    mod_result = neg_val % 8
                    out.append(f"    have {hn} : ({neg_val} : Int) % 8 = {mod_result} := by decide")
                    mod_lemmas.append(hn)
                out.append(f"    simp only [{src_B}, {dst_B}, mod_8k, {', '.join(mod_lemmas)}]")
            else:
                out.append(f"    simp only [{src_B}, {dst_B}, mod_8k]")
        
        # After simp with B definitions and mod_8k, goal should be fully concrete
        out.append(f"    dsimp [R]; try rfl")
        
    # ====== RIGHT END ======
    out.append(f"  · dsimp [step, S_wave_{t-1}, S_wave_{t}]")
    hw_list_end = []
    for cond in [f"i - 1 < {get_lean_r_expr(prev_R)}", f"i < {get_lean_r_expr(prev_R)}", f"i + 1 < {get_lean_r_expr(prev_R)}",
                 f"i < {get_lean_r_expr(curr_R)}"]:
        hn = get_hw()
        out.append(f"    have {hn} : ¬({cond}) := by omega")
        hw_list_end.append(hn)
    out.append(f"    simp only [{', '.join(hw_list_end)}, ite_false]")
    out.append(f"    repeat (split <;> (try omega))")
    out.append(f"    all_goals (first | rfl | (dsimp [R]; first | rfl | decide))")
    out.append("")

out.append("end CA\n")

with open("/Users/swish/src/wolfram/CASearch/Proofs/CA/DoublerB0.lean", "w") as f:
    f.write("\n".join(out))

print(f"Generated {len(out)} lines")
