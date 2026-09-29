# A deliberately small free-word core.
# Pos{n} and Neg{n} are the two orientations of a crag generator.

import Base

type Letter:
  Pos{generator: Nat}
  Neg{generator: Nat}

type Word:
  Nil{}
  Cons{head: Letter, tail: Word}

def inverse(a, b) -> Bool:
  match a b:
    case Pos{x} Neg{y}:
      Cmp.is_eq(Nat.cmp(x, y))
    case Neg{x} Pos{y}:
      Cmp.is_eq(Nat.cmp(x, y))
    case _ _:
      False{}

def push(letter, word) -> Word:
  match word:
    case Nil{}:
      Cons{head: letter, tail: Nil{}}
    case Cons{head, tail}:
      match inverse(letter, head):
        case True{}:
          tail
        case False{}:
          Cons{head: letter, tail: word}

def reduce(word) -> Word:
  match word:
    case Nil{}:
      Nil{}
    case Cons{head, tail}:
      push(head, reduce(tail))
