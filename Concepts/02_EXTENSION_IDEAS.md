# Secondary Extension Ideas — Do Not Treat as Core Requirements

This file deliberately separates attractive ideas from the frozen minimal sandbox. These mechanics should only be promoted into the core after the basic loop/pull/block/cut system is playable.

## 1. Local manual manipulation of enemy strings

Preferred extension over remote string-hooking.

If the player physically reaches an enemy strand, they may grab a nearby point and drag that local segment while respecting non-crossing constraints.

Possible actions:

- pull a strand around a crag;
- feed a strand around a cactus;
- move a local segment to change which region it separates;
- create or remove a local obstruction;
- prepare the strand for later cutting.

This is especially attractive because locomotion is itself constrained: simply reaching an enemy strand becomes a tactical achievement.

## 2. String hooking with another string

Alternative or later extension.

A newly thrown lasso may attach to an enemy strand instead of crossing it. Pulling then manipulates both structures according to an explicit topological rule.

Do not implement before local hand manipulation is tested; it may be redundant or harder to read.

## 3. Multi-component enemy bodies

Players/enemies may eventually be embedded graphs or unions of components rather than points/disks.

Potential consequences of tightening motifs:

- sever a limb/component;
- split an enemy body;
- alter reach or movement options;
- remove an attack capability;
- create new holes/components in the effective geometry;
- force a different strategy after topology-changing damage.

This should replace generic health damage where possible.

## 4. String count economy

Likely candidate: three active strings per player.

A deployed persistent string consumes one slot. A trapped string remains committed.

If no free strings remain:

- normal lasso movement is unavailable;
- slow manual movement remains;
- player may need to recover, cut, steal, or craft a string.

Exact cap remains a playtest variable.

## 5. String stealing

Potential rule:

- a cut string becomes a loose recoverable object;
- a player who reaches its free end may claim it;
- claiming increases their available string pool, possibly above the nominal starting count.

Alternative: only specifically severed enemy strings can be stolen.

This creates fights around cut-string locations instead of making cutting a purely destructive action.

## 6. Crag crafting from string motifs

Very promising extension.

Examples to test:

- a specific loop around three anchors creates one new breakable crag;
- a more complex word/pattern creates a cactus;
- special rare motifs create an unbreakable crag;
- construction location chosen by a canonical interior cell or by player-selected eligible cell inside the tightened region.

The goal is for terrain construction to feel like topological spellcasting.

## 7. More elaborate destruction rules

Current simple test rule:

- pull around exactly two breakable crags -> both break;
- three or more -> no automatic break.

Possible replacements:

- only specific cyclic ordering allows break;
- one unbreakable crag can act as an anvil that destroys a neighboring breakable crag;
- nested loops create different effects;
- crag type influences the resolved motif;
- destruction requires a cactus or another terrain feature.

Avoid continuous force simulation unless absolutely necessary.

## 8. Rich capture/crush spell vocabulary

Possible motifs:

- enemy + one crag -> pin;
- enemy + two crags -> crush;
- enemy + cactus -> sever a string/appendage rather than raw damage;
- enemy isolated in a bounded region -> capture;
- nested loops -> stronger or qualitatively different effect;
- several simultaneous loops -> composite spell.

Prefer a small number of visually learnable motifs over dozens of numerical modifiers.

## 9. Finite rope length

Not currently core.

Possible future economy:

- each player owns total rope length `L`;
- persistent strings reserve part of `L`;
- long loops trade strategic reach for future mobility;
- recovery restores length.

Only add if the finite string-count economy is insufficient.

## 10. Multiple altitude layers

Long-term idea only.

Each altitude is its own 2D manifold with its own obstacles/strings. Layers may be connected by bridges, point gluings, or disk-like portals.

This gives a graph-of-spaces flavor while preserving 2D topology locally.

Do not conflate this with 3D string crossings. Strings on a given layer remain strictly 2D.

## 11. Advanced formal AI objectives

Once primitive predicates are proven, enemy search may ask certified bounded questions such as:

- does there exist a legal move sequence of length <= `k` reaching a win state?
- is every opponent reply of depth <= `m` answerable?
- can this string be recovered after a specified obstacle edit?
- can this candidate crag placement trap at least one enemy string?

The proof system should certify the proposition actually used by gameplay/search, not merely a loose approximation.

## 12. Visual ambitions

- dramatic voxel crags/cacti;
- tiny diorama-like arenas;
- orthographic bird-view;
- strong global illumination/reflections;
- beautiful water/wet-stone or polished mineral materials where appropriate;
- strings visually smooth and expressive despite voxel terrain;
- tightening should read like a spell resolving rather than a rope-physics simulation.
