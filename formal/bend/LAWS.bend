# Minimal proof boundary for the first sandbox.
# A loop is modeled as a word in signed crag generators.

import Base
import ./main.bend as Topology

law inverse_pair_cancels:
  for generator: Nat
  {Topology.reduce(Topology.Cons{
      Topology.Pos{generator},
      Topology.Cons{Topology.Neg{generator}, Topology.Nil{}}
    }) == Topology.Nil{} : Topology.Word}
