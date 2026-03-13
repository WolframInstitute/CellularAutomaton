def generate():
    cases = [
        ("h1 : i ≤ p - 2", "i"),
        ("h2 : i = p - 1", "p-1"),
        ("h3 : i = p", "p"),
        ("h4 : p < i ∧ i < p + ↑n", "i"),
        ("h5 : i = p + ↑n", "p + ↑n"),
        ("h6 : i = p + ↑n + 1", "p + ↑n + 1"),
        ("h7 : i = p + ↑n + 2", "p + ↑n + 2"),
        ("h8 : p + ↑n + 2 < i", "i")
    ]
    conds = [
        ("C1_l", "p ≤ {x}-1 ∧ {x}-1 < p + (↑n + 1)"), ("C2_l", "{x}-1 = p + (↑n + 1)"),
        ("C1_c", "p ≤ {x} ∧ {x} < p + (↑n + 1)"),     ("C2_c", "{x} = p + (↑n + 1)"),
        ("C1_r", "p ≤ {x}+1 ∧ {x}+1 < p + (↑n + 1)"), ("C2_r", "{x}+1 = p + (↑n + 1)"),
        ("Out1", "p ≤ {x} ∧ {x} < p + ↑n"),
        ("Out2", "{x} = p + ↑n"),
        ("Out3", "p + ↑n < {x} ∧ {x} ≤ p + ↑n + 2")
    ]

    print("theorem step_transition (n : Nat) (hn : n ≥ 1) (p : Int) :")
    print("    step (S_in n p) = S_out n p := by")
    print("  funext i")
    
    for (proof_line, x_val) in cases:
        print(f"  by_cases {proof_line}")
        if "i =" in proof_line:
            print(f"  · rw [{proof_line.split(':')[0].strip()}]; simp only [s_lemmas,")
        else:
            print(f"  · simp only [s_lemmas,")
            
        for cond_name, cond_fmt in conds:
            cond = cond_fmt.replace("{x}", x_val)
            print(f"      show ??? ({cond}) from by omega,")
        print("      ]")
        
generate()
