# Minimal Core Specification — Topological Lasso Sandbox

## 0. Purpose

This document freezes the **minimal mechanics and mathematical model** required to build the first playable sandbox. Anything not specified here is deliberately out of scope until playtesting shows it is needed.

The game is a top-down, voxel-styled, 3D-rendered game whose **gameplay topology is strictly two-dimensional**. The visual presentation may be 3D, but all topological rules operate on a single ground surface.

The design goal is that manipulating loops feels like **casting topological spells**. The player should learn by seeing what loops do when tightened, not by reading algebra.

---

# 1. World model

## 1.1 Ground manifold

For the minimal sandbox, the playable ground is a finite rectangular planar region `M`.

The rendered map is discretized into square cells for placement and coarse movement purposes, but the topological model treats the ground as a continuous 2D surface.

The square grid is therefore a **gameplay lattice**, not the mathematical topology itself.

Each cell may contain at most the allowed combination of:

- empty ground,
- one crag,
- one cactus,
- a player body or body component,
- transient string geometry passing through the cell.

Exact occupancy rules may be tightened later.

## 1.2 Obstacles

The topology of the currently traversable/string-available space is determined by an obstacle set `K` embedded in `M`.

For the minimal core:

- **crags** are obstacle components and lasso anchors;
- **cacti** are obstacle components with a string-cutting rule;
- **persistent strings** are embedded curves that other strings cannot cross.

At any moment, the mathematical free space is conceptually

`X = M \ K`.

Player bodies are *not* automatically part of `K` for string topology: strings may pass across/through a player body while being tightened. Bodies are lassoable targets rather than absolute topological barriers.

---

# 2. Strict 2D string rule

All strings live in the same 2D gameplay manifold.

There is **no over/under crossing state** and no third topological height coordinate.

Two strings may touch only when a mechanic explicitly permits a local interaction. They may never freely cross.

This rule is foundational because persistent strings must alter the complement `X` and therefore alter future homotopy classes and movement possibilities.

---

# 3. Players

## 3.1 Minimal player body

For the first playable sandbox, a player may be represented mathematically by a point or small disk centered on a grid cell.

Visually, the player is a voxel character with nonzero height.

Later, players may become extended or multi-component bodies. That is not required for the first sandbox.

## 3.2 Basic movement

Players have two movement modes:

1. **Manual movement** — slow movement to adjacent/reachable grid cells.
2. **Lasso movement** — the primary fast movement mechanic: throw a loop around one or more crags, then pull.

For the first sandbox, implement manual movement first. Lasso movement is introduced after strings and pulling are visually stable.

Movement snaps to the grid for game-state purposes. Animation between cells may be smooth and continuous.

---

# 4. Crags

A crag is a rock-like terrain obstacle occupying one grid cell.

Mathematically, treat a crag as a small removed disk or puncture-like obstacle. For fundamental-group reasoning, a small disk obstacle may be replaced by a point up to homotopy where appropriate.

Crags have at least two future-capable categories:

- **breakable crag**;
- **unbreakable crag**.

The first sandbox only needs a visual distinction and the breakability flag.

Crags serve simultaneously as:

- topological holes;
- lasso anchors;
- locomotion anchors;
- ingredients in tightening/crafting patterns.

---

# 5. Cacti

A cactus occupies one grid cell and is a topological obstacle like a crag, but has a special rule:

> A string that is forced into a cactus as part of an explicit **pull/tighten/retract resolution** is cut.

Incidental overlap during animation must not silently destroy a string. Cutting occurs only as the resolved outcome of a legal game operation.

In the minimal sandbox, cutting destroys the affected entire persistent string object. Segment-level cutting and loose rope ends are extensions.

---

# 6. Strings and lassos

## 6.1 String object

A string is represented by:

- owner player;
- geometric embedded polyline/curve in `M`;
- attachment/start point at or associated with the owner;
- closed/open state;
- persistent/transient state;
- current topological class relative to obstacles, where defined.

Rendering is smooth and continuous even though the map is tiled.

## 6.2 Throwing a lasso

A lasso action creates a transient curve extending from the player.

The player directs the lasso around a chosen route. The exact aiming UX may be crude in the prototype.

The lasso may surround/catch a subset of:

- crags;
- cacti;
- player bodies.

It may not pass through crags, cacti, or persistent strings.

## 6.3 Closing a lasso

When a lasso closes, it becomes a **persistent loop**.

A persistent loop:

- remains in the map;
- is an obstacle to future strings;
- may later be pulled/tightened;
- may later be retracted/recovered if topology permits;
- may be cut by a cactus under the cutting rule.

Persistent loops are the central state-changing objects of the game.

---

# 7. Pulling / tightening

There is deliberately **no continuous rope physics model** in the core rules.

No Hooke-law tension, rope HP, force integration, or physically simulated elasticity is required.

Instead:

> Pulling requests a deformation of the selected string toward a canonical or sufficiently stable **tight representative** of its current homotopy class, subject to current obstacles and non-crossing rules.

The rendered animation may look physical: slack disappears, the loop slides around rocks, and curves become taut. However, the game-state transition is combinatorial/topological.

## 7.1 Tightening invariant

Unless a break/cut/crafting rule fires, pulling:

- preserves the relevant homotopy class;
- does not allow a string to cross crags, cacti, or other strings;
- may allow the string to pass over a player body because bodies are targets, not topological walls;
- terminates in a resolved tight configuration.

## 7.2 Resolved configurations

The minimal rules should support these recognizable motifs:

- **one crag**: loop tightens around one crag; this can act as a locomotion anchor;
- **two breakable crags**: a tight loop around exactly two breakable crags destroys both crags;
- **three or more crags**: no automatic crag break in the core; the loop remains as a stable topology-changing configuration;
- **enemy + crag**: eligible for a capture/pin effect;
- **enemy + multiple crags**: eligible for stronger capture/crush effects;
- **cactus reached during pull/retraction resolution**: affected string is cut;
- **blocked by another persistent string**: tightening stops unless a later explicit manipulation mechanic changes the configuration.

The exact combat numbers are not part of the core mathematical model.

---

# 8. Damage and capture

The game should not use “winding number = damage”. Damage comes from **recognized tightened motifs**.

For the first combat prototype, define only two semantic effects:

## 8.1 Capture / pin

A tightened loop containing an enemy and at least one suitable crag may put the enemy into a **captured/pinned** state.

Minimal implementation: captured enemy cannot use normal lasso movement until the responsible loop is removed or topology changes.

## 8.2 Crush

A tightened loop containing an enemy together with a specified multi-crag pattern may trigger **crush damage**.

For the first prototype, damage may simply subtract a fixed amount from a temporary health counter. The important part is that the trigger is the topological motif, not collision velocity or simulated force.

Later, damage may instead alter body geometry or sever body components.

---

# 9. String recovery

A player may attempt to recover a persistent string.

Recovery means retracting it back to its owner through a legal deformation.

If a legal homotopy/retraction exists without crossing current obstacles, the string is removed from the world and returned to the player’s available string pool.

If recovery is impossible under current topology, the string remains committed in the world until:

- an obstacle is removed;
- a string is cut;
- a crag is broken;
- another legal topology-changing action changes the complement.

This is strategically important: a deployed string can become trapped.

---

# 10. Enemy strings

Enemy strings are genuine embedded obstacles.

Core rule:

> A string may not freely cross another persistent string.

For the **minimal sandbox**, do not yet implement lasso-hooking of enemy strings.

Implement only:

1. enemy strings block placement/deformation of new strings;
2. the player may later gain a local **grab-and-drag** interaction when physically adjacent to an enemy string;
3. cactus cutting can remove strings.

The exact grab-and-drag topology is deferred until the baseline loop system is playable.

---

# 11. Number of strings

The sandbox architecture must support a finite number of concurrently available strings per player, but the exact cap is not locked.

Use a configurable parameter such as:

`MAX_STRINGS_PER_PLAYER`.

Recommended initial test value: `3`.

A persistent deployed string consumes one string slot until recovered or destroyed.

If the player has no free strings, they retain slow manual movement.

Do **not** build a finite total rope-length economy yet.

---

# 12. Crag crafting

The architecture must support creation of new crags as the outcome of a recognized tightened string motif.

For the first playable sandbox, crag crafting may be disabled.

For the first crafting experiment, use a deterministic rule such as:

> If a player tightens a valid loop around a specified pattern of existing crags and satisfies a local placement condition, a new breakable crag is created on a canonical eligible grid square.

The exact motif is intentionally not frozen before playtesting.

Crag creation is important because it lets players alter the topology and create future movement anchors.

---

# 13. Mathematical representation

## 13.1 Complement

At a game state `s`, define an obstacle subset `K_s` of the planar map and free space

`X_s = M \ K_s`.

The obstacle subset may contain crag disks/points, cactus disks/points, and persistent string curves.

## 13.2 Fundamental group / groupoid

Closed strings are represented by homotopy classes of loops in `X_s`, i.e. elements of

`pi_1(X_s, x0)`

for an appropriate basepoint.

Player movement and open string paths naturally require the **fundamental groupoid** or an equivalent path representation because endpoints vary.

In planar states that deformation-retract to a graph, the fundamental group is free and may be represented by reduced words in generators.

## 13.3 Word reduction

The minimal certified operation is:

`isTrivial(state, word) -> Bool / proof-bearing result`

meaning whether the represented loop is null-homotopic in the current free space.

For free groups this reduces to canonical free-word reduction after a proven correspondence between geometry and generators.

## 13.4 Topology changes

When an obstacle is removed, e.g. a string is cut or a crag destroyed:

`X_old -> X_new`

via the natural inclusion `i : X_old -> X_new`.

Existing loop classes are transported by the induced map

`i_* : pi_1(X_old) -> pi_1(X_new)`.

When an obstacle is added, the inclusion goes from the new complement into the old one. Existing geometric representatives must remain valid under the new obstacle placement; invalid placement actions are rejected.

## 13.5 Verified mathematics boundary

Any gameplay decision whose correctness depends on a topological proposition must have a formally specified mathematical counterpart.

Examples:

- whether a loop is trivial;
- whether a stored loop class becomes trivial after an obstacle removal;
- whether a path class is reachable without crossing obstacles;
- whether a player has a move sequence of bounded length satisfying a formally defined win predicate.

Bend 2 is the primary proof-bearing computational language for proof-critical game mathematics. Important mathematical rules must be stated as Bend laws and proved by Bend definitions. The project should keep human-authored specifications in `LAWS.bend` and machine/agent-authored proofs in `PROOF.bend`, and proof-bearing changes must pass both `bend PROOF.bend` and, for critical releases/checkpoints, `bend PROOF.bend --verdict`.

The `--verdict` path rechecks proofs with the small BendTT kernel whose metatheory is formalized in Lean. Lean may additionally be used for independent metatheory, deeper topology, or cross-checking difficult results, but it is not a mandatory runtime authority sitting behind every Bend function.

A proof-critical function should be designed so that a positive mathematical claim is accompanied by proof evidence in its type or is connected to a proved law. For search problems, returning a witness that itself satisfies the formal specification is preferred over trusting an opaque Boolean.

The game engine must never silently substitute an unrelated geometric heuristic for a proposition marked as proof-critical.

---

# 14. Rendering and animation contract

The game is rendered in 3D voxel style, top-down/bird-view, with orthographic projection.

The topology remains 2D.

Strings should look continuous and smooth:

- splines or densely sampled curves;
- smooth tightening animation;
- clear visual distinction between slack and tight state;
- no visible snapping to the square lattice except at deliberately grid-bound objects/positions.

The square grid should mainly govern:

- crag/cactus placement;
- player logical position;
- canonical spawn/crafting cells;
- pathfinding state.

---

# 15. Minimal implementation sequence

Do not implement everything at once.

Required review gates:

### Milestone 0 — Empty map
- orthographic camera;
- square voxel ground;
- visible grid logic;
- one controllable player;
- manual snapped movement.

### Milestone 1 — Crags
- place several crags on fixed cells;
- collisions/occupancy;
- no strings yet.

### Milestone 2 — One visual string
- player can create one closed loop around selected crags;
- loop is smoothly rendered;
- no tightening logic yet.

### Milestone 3 — Persistent obstacle
- closed loop persists;
- a second loop cannot cross the first;
- topology representation and geometry remain synchronized.

### Milestone 4 — Pull/tighten
- pull one loop around one/two/three crags;
- animate toward a canonical tight representative;
- demonstrate one-crag stable and two-crag break rule.

### Milestone 5 — Cactus
- add cactus tile;
- demonstrate pull/retract resolving into a cut.

### Milestone 6 — Proof-bearing math bridge
- state at least one nontrivial `isTrivial`-style law in Bend 2;
- provide a Bend proof/implementation that satisfies the law;
- require `bend PROOF.bend` to pass, and verify the checkpoint with `bend PROOF.bend --verdict`;
- runtime/game test must consume the proof-backed result.

### Milestone 7 — Enemy target
- add stationary enemy body;
- demonstrate capture/pin motif.

### Milestone 8 — Enemy strings
- enemy places one persistent blocking loop;
- player routing must respect it.

Only after explicit review should work proceed to local enemy-string manipulation, crafting, body severing, stealing strings, or AI search.

---

# 16. Explicitly out of scope for the minimal sandbox

- 3D knot/link topology;
- over/under crossings;
- continuous rope physics;
- rope HP;
- continuous strain simulation;
- finite rope length;
- multiple altitude manifolds;
- bridges/gluing between layers;
- body limb severing;
- string stealing;
- production-grade combat balance;
- sophisticated AI;
- procedural maps;
- networking.

These belong to the extension backlog.
