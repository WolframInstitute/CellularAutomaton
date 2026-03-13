import Lake
open Lake DSL

package «CA» where
  leanOptions := #[
    ⟨`autoImplicit, false⟩
  ]

-- Import shared TM/TagSystem infrastructure from TuringMachineSearch
require OneSidedTM from "../../TuringMachineSearch/Proofs"

@[default_target]
lean_lib «CA» where
  srcDir := "."
  roots := #[`CA.TestR0, `CA.ECA, `CA.Glider, `CA.Doubler, `CA.DoublerTrans, `CA.DoublerWave, `CA.DoublerFull, `CA.DoublerBridge, `CA.TestModulo, `CA.DoublerB0, `CA.TMToTag, `CA.Universality, `Code20.TotalisticCA]
