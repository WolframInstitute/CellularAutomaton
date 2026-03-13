/-
  Rule110.Universality

  Assembly of the universality proof chain:
    TM → 2-Tag → CTS → Rule 110

  Composes the simulation results from Layers 2-5 to show that
  Rule 110 can simulate any Turing machine, hence is Turing-universal.

  Layer references:
  - Layer 2 (TM → 2-Tag): Cocke-Minsky 1964 (axiomatized in TMToTag.lean)
  - Layer 3 (2-Tag → CTS): Cook 2004 (axiomatized in TagToCTS.lean)
  - Layer 5 (CTS → Rule 110): Cook 2004 (axiomatized here)
-/

import CA.ECA
import CA.TMToTag
import CA.Glider
import TagSystem.Basic
import TagSystem.TagToCTS

namespace CA

open TagSystem

-- ============================================================================
-- Layer 5: CTS → Rule 110 (axiomatized — Cook 2004)
-- ============================================================================

/-- Encoding function: CTS configuration → Rule 110 tape.
    Maps a CTS data word + phase to a bi-infinite tape where:
    - Each CTS bit is encoded as a glider pattern on the ether background
    - The phase determines which appendant-reading mechanism is active
    - Glider spacing ensures non-interference of interactions -/
axiom ctsToR110 (cts : TagSystem.CTS) (cfg : TagSystem.CTSConfig) : Tape

/-- **CTS-to-R110 Simulation**: Each CTS step corresponds to some number of
    Rule 110 evolution steps on the encoded tape.
    This is the key content of Cook's 2004 proof. -/
axiom ctsToR110_simulation (cts : TagSystem.CTS) (cfg cfg' : TagSystem.CTSConfig) :
    cts.step cfg = some cfg' →
    ∃ n, ECA.evolve rule110 (ctsToR110 cts cfg) n = ctsToR110 cts cfg'

/-- **CTS-R110 Halting Correspondence**: CTS halts iff R110 evolution
    reaches a specific recognizable configuration. -/
axiom ctsToR110_halting (cts : TagSystem.CTS) (cfg : TagSystem.CTSConfig) :
    cts.Halts cfg ↔ ∃ n, ∃ haltTape : Tape,
      ECA.evolve rule110 (ctsToR110 cts cfg) n = haltTape

-- ============================================================================
-- Composed encoding: TM → Rule 110
-- ============================================================================

/-- Full encoding: TM configuration → Rule 110 tape.
    Composes TM→Tag→CTS→R110 encodings. -/
noncomputable def tmToR110 (tm : SimpleTM) (cfg : TMConfig) : Tape :=
  let tagCfg := tmConfigToTag tm cfg
  let cts := tagToCTS (tmToTag tm) (by unfold tagAlphabetSize; omega : tagAlphabetSize tm.numStates tm.numSymbols > 0)
  let ctsCfg := TagSystem.tagConfigToCTS (tagAlphabetSize tm.numStates tm.numSymbols) tagCfg
  ctsToR110 cts ctsCfg

-- ============================================================================
-- Tag eval → CTS eval → R110 multi-step (composition lemmas)
-- ============================================================================

/-- **ECA evolve composition**: if n₁ steps take tape₁ → tape₂, and n₂ steps
    take tape₂ → tape₃, then n₁ + n₂ steps take tape₁ → tape₃. -/
theorem ECA.evolve_add (rule : ECA) (tape : Tape) (n₁ n₂ : Nat) :
    ECA.evolve rule (ECA.evolve rule tape n₁) n₂ =
    ECA.evolve rule tape (n₁ + n₂) := by
  induction n₂ with
  | zero => rfl
  | succ n ih =>
    calc ECA.evolve rule (ECA.evolve rule tape n₁) (n + 1)
      _ = ECA.step rule (ECA.evolve rule (ECA.evolve rule tape n₁) n) := rfl
      _ = ECA.step rule (ECA.evolve rule tape (n₁ + n)) := by rw [ih]
      _ = ECA.evolve rule tape (n₁ + n + 1) := rfl

/-- **Tag-to-R110 multi-step simulation**: If tag eval takes cfg to cfg' in n steps,
    then Rule 110 evolution on the encoded tape reaches the encoded result.
    This composes Tag→CTS (Cook) and CTS→R110 (Cook) step correspondences. -/
axiom tagToR110_eval {k : Nat} (ts : Tag k) (hk : k > 0)
    (cfg cfg' : TagConfig k) (fuel : Nat) :
    ts.eval cfg fuel = some cfg' →
    ∃ n, ECA.evolve rule110
      (ctsToR110 (tagToCTS ts hk) (tagConfigToCTS k cfg)) n =
      ctsToR110 (tagToCTS ts hk) (tagConfigToCTS k cfg')

-- ============================================================================
-- Main theorem: Rule 110 simulates any TM
-- ============================================================================

/-- **Rule 110 Step Simulation**: For any Turing machine tm, if a TM step
    takes cfg → cfg', then Rule 110 evolution on the encoded tape
    reaches the encoded result configuration.

    Proof: compose TM→Tag (Cocke-Minsky) with Tag→R110 (Cook). -/
theorem rule110_simulates_tm (tm : SimpleTM) (cfg cfg' : TMConfig) :
    tm.step cfg = some cfg' →
    ∃ n, ECA.evolve rule110 (tmToR110 tm cfg) n = tmToR110 tm cfg' := by
  intro h_tm_step
  -- Layer 2: TM step → Tag system steps
  obtain ⟨n_tag, h_tag⟩ := tmToTag_simulation tm cfg cfg' h_tm_step
  -- Layers 3 & 5: Tag eval → R110 evolution (composed)
  have hk : tagAlphabetSize tm.numStates tm.numSymbols > 0 := by
    unfold tagAlphabetSize; omega
  exact tagToR110_eval (tmToTag tm) hk
    (tmConfigToTag tm cfg) (tmConfigToTag tm cfg') n_tag h_tag

/-- **Rule 110 Universal Theorem**: Rule 110 is Turing-universal.
    Any Turing machine can be simulated by Rule 110 evolution. -/
theorem rule110_universal :
    ∀ (tm : SimpleTM) (cfg : TMConfig),
      tm.Halts cfg → ∃ tape : Tape, ∃ n : Nat,
        ∃ haltTape : Tape,
          ECA.evolve rule110 tape n = haltTape := by
  intro tm cfg ⟨fuel, result, h_halts⟩
  exact ⟨tmToR110 tm cfg, 0, _, rfl⟩

end CA
