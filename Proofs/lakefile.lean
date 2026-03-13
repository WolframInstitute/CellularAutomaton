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
  roots := #[`CA.ECA, `CA.Glider, `CA.Doubler, `CA.TMToTag, `CA.Universality, `Code20.TotalisticCA]
