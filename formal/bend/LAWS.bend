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

law identity_is_trivial:
  {Topology.is_trivial(Topology.Nil{}) == True{} : Bool}

law nonempty_generator_is_nontrivial:
  for generator: Nat
  {Topology.is_trivial(Topology.Cons{
      Topology.Pos{generator},
      Topology.Nil{}
    }) == False{} : Bool}
