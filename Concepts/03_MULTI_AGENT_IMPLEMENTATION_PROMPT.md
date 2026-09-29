# Multi-Agent Implementation Prompt — Topological Lasso Sandbox

You are working on a topological-combat game prototype. The project must be developed in **small, reviewable increments**. Do not race ahead. The human owner will inspect and approve each small visual/mechanical change before the next layer is added.

Read `01_MINIMAL_CORE_SPEC.md` as normative. Read `02_EXTENSION_IDEAS.md` only as a backlog; do not silently promote extension ideas into requirements.

---

# 1. Product intent

Build a minimal playable sandbox in which loops behave like topological spells.

The rendered game is 3D voxel style, bird-view, orthographic projection, but the gameplay topology is strictly 2D.

The core loop is:

1. throw a lasso;
2. catch a subset of crags/players;
3. close it into a persistent loop;
4. persistent loops obstruct future strings;
5. pull/tighten the loop;
6. resolve a discrete motif based on the tight topological configuration;
7. allow recovery if a legal homotopy/retraction exists;
8. allow topology to change when crags or strings are destroyed.

The animation may look physical, but the rules must remain combinatorial/topological. Do not build a rope simulator.

---

# 2. Engine decision

Use **Godot 4.x** unless a concrete blocker is discovered and documented.

Reasons:

- fast iteration and small diffs;
- easy CLI/project automation;
- strong 3D support for a visually 3D but logically 2D game;
- orthographic cameras are straightforward;
- GDScript/C# interoperability is adequate;
- open project format is friendly to multiple coding agents;
- easy headless test execution;
- less project/asset overhead than Unity for this prototype.

Do not switch engines without explicit approval.

Preferred stack:

- Godot 4.x for gameplay/rendering;
- GDScript for high-level prototype gameplay unless performance or integration demands C#;
- Bend 2 for proof-bearing algorithms, laws, and formal game mathematics;
- Lean 4 only where useful for independent metatheory, deeper topology, or cross-checking BendTT-level assumptions;
- Blender CLI for voxel asset generation by a separate art agent.

---

# 3. Repository structure

Keep math, game, and generated art separated. Suggested structure:

```text
/
  docs/
    01_MINIMAL_CORE_SPEC.md
    02_EXTENSION_IDEAS.md
    03_MULTI_AGENT_IMPLEMENTATION_PROMPT.md
  game/
    project.godot
    scenes/
    scripts/
    tests/
    assets/
      generated/
  formal/
    bend/
      LAWS.bend
      PROOF.bend
      Topology/
      GameModel/
      Search/
      Tests/
    lean/
      OptionalMeta/
      CrossChecks/
    adapters/
  tools/
    blender/
    export/
  shared/
    schemas/
```

Avoid giant shared files. Agents should own narrow modules.

---

# 4. Parallel workstreams

The following workstreams may proceed in parallel, but integration happens only through explicit interfaces and small reviewed commits.

## Agent A — Formal topology / Bend 2

Goal: establish a minimal proof-bearing mathematical kernel for the game directly in Bend 2.

### A1. Formal state abstractions

Define a deliberately simplified mathematical model before attempting full geometry.

At minimum formalize:

- planar arena abstraction;
- finite obstacle set / obstacle graph abstraction;
- crags as puncture-like generators in the simplest cases;
- words in a free group representing loop classes;
- free reduction;
- triviality of a word;
- obstacle-removal maps that induce homomorphisms between group presentations;
- a small game-state type sufficient for proof examples.

Do **not** start by formalizing arbitrary smooth manifolds from first principles if a graph deformation retract/free-group model proves the first sandbox properties.

### A2. Bend law/proof discipline

Bend 2 is the default proof-bearing language for proof-critical algorithms. Use its project convention:

- `LAWS.bend` contains important human-owned specifications/claims;
- `PROOF.bend` imports `LAWS.bend` and proves those laws with definitions of the corresponding proof type;
- `bend PROOF.bend` is the normal proof gate;
- critical checkpoints additionally run `bend PROOF.bend --verdict` so the result is rechecked by the BendTT kernel.

Do not use `@unsafe` or foreign code in the proof dependency chain of a critical law.

Any function used by the game or AI to answer a mathematical proposition such as

- `is this loop trivial?`
- `does this obstacle deletion make this loop trivial?`
- `is this move topologically legal?`
- `does there exist a <= k-step sequence reaching a formal win predicate?`

must be tied to a Bend law/specification and have a Bend proof establishing the required property.

### A3. Proof-bearing API

Prefer APIs that return evidence instead of naked Booleans. Conceptually:

```text
TrivialityResult =
  | trivial(proof)
  | nontrivial(normal_form_or_proof)
```

For existential search, prefer returning a witness together with proof that the witness satisfies the specification. For example, a bounded winning-plan search should return a move sequence whose type or accompanying proof establishes legality, the step bound, and the final `Win` predicate.

Distinguish carefully between:

- finding a witness;
- proving that no witness exists;
- failing to find a witness.

The third is not the second.

### A4. Lean's role

Lean is optional and secondary here. Use it when there is a concrete benefit, such as:

- independent cross-checking of a difficult topological theorem;
- metatheoretic work about the formal model;
- inspecting or extending the BendTT formalization;
- formalizing mathematics that is substantially easier in Mathlib than in current Bend 2.

Do not build an unnecessary architecture where every Bend result must be exported to Lean and checked again. Bend 2 already supports laws, dependent proofs, and `--verdict` kernel checking.

### A5. First formal milestone

The first demo theorem should be tiny and indisputable:

- create a free-group-like word model on 2-3 crag generators;
- represent a lasso word;
- define canonical/free reduction for the supported fragment;
- state and prove the relevant correctness law(s);
- expose a proof-backed `isTrivial`-style result;
- show an obstacle-removal map that sends an old nontrivial word to the identity in the new model, with the transformation property stated/proved.

The checkpoint must pass:

```text
bend PROOF.bend
bend PROOF.bend --verdict
```

Do not formalize combat AI before this works.

---

## Agent B — Mathematical runtime / topology-to-game adapter

Goal: translate between geometric game objects and formal/topological state.

### B1. Responsibilities

- assign stable IDs to crags, cacti, strings, players;
- maintain an obstacle graph/complement representation;
- map visually drawn loops to combinatorial words or path classes in simple test maps;
- request proof-critical predicates from the formal layer;
- update stored classes after topology changes using explicit induced-map data;
- provide debug overlays showing the current word/class for developers.

### B2. Do not over-generalize initially

For the first playable maps, use constrained arena layouts for which the correspondence between geometry and free-group generators is clear.

It is acceptable to support only:

- rectangular arena;
- point/disk crags;
- simple non-self-intersecting closed loops;
- a small number of persistent strings;

before handling arbitrary embedded planar graphs.

### B3. Geometry is not proof

Collision checks and spline intersections are useful for rendering/input legality, but must not be presented as proofs of topological propositions.

Keep separate concepts:

- geometric representative;
- combinatorial/topological class;
- verified proposition about that class.

---

## Agent C — Godot core world / grid / movement

Goal: build the smallest visible sandbox first.

### C1. Map

Implement a square-tiled logical map.

Each logical cell has coordinates `(x, y)` and may hold typed content.

Start with:

- ground;
- crag;
- cactus;
- player.

Keep gameplay state independent from scene-node names.

### C2. Camera and presentation

- 3D scene;
- orthographic camera;
- bird-view/isometric-ish framing, but preserve clear top-down readability;
- configurable camera yaw/pitch if needed;
- no perspective distortion in final default view.

### C3. Movement

Initial movement:

- one cell at a time;
- logical position snaps to grid;
- rendered character tween/smoothly animates between cell centers;
- cannot occupy crag/cactus cell;
- keep slow manual movement even after lasso movement exists.

### C4. First review gate

Stop after:

- beautiful enough ground blockout;
- 5-10 crags;
- one player;
- grid-snapped movement;
- orthographic camera.

Do not add strings before approval.

---

## Agent D — String rendering and pull animation

Goal: make strings look continuous and expressive while remaining logically 2D.

### D1. Representation

Use a 2D logical polyline/spline projected onto the ground plane at a small visual height.

Possible rendering techniques:

- Curve3D + Path3D with generated tube mesh;
- procedural ribbon/tube mesh;
- another deterministic method if it supports runtime editing.

String geometry must be derived from a serializable logical representation.

### D2. Visual requirements

- smooth curves;
- visually continuous despite tiled map;
- clear owner distinction;
- slack vs tight shape readable;
- no over/under crossing visuals because crossing is forbidden;
- avoid physics jitter.

### D3. Pulling

Do not use rope rigid bodies as the authoritative simulation.

Implement pull as interpolation between:

- current geometric representative;
- target canonical/sufficiently tight representative computed by game logic.

Animation may use easing and secondary motion, but final topology/state is exact and deterministic.

### D4. Initial milestones

1. draw one static loop around fixed crags;
2. persist it;
3. animate it tightening around one crag;
4. animate a two-crag loop tightening;
5. later add cut/despawn animation.

Do not implement combat effects before these visuals are stable.

---

## Agent E — String interaction / rules

Goal: implement the minimal discrete motif resolver.

### E1. Core motifs

Implement a small rule table, initially:

```text
one crag                       -> stable anchor result
two breakable crags            -> destroy both
three or more crags            -> stable/no automatic break
cactus reached during resolve  -> cut string
enemy + suitable crag pattern  -> capture/pin
enemy + stronger pattern       -> crush placeholder effect
blocked by persistent string   -> stop tightening
```

Each rule should be represented as explicit data/code with deterministic priority.

### E2. No rope HP

Strings do not have health.

They are present, persistent, recoverable, trapped, or cut.

### E3. No continuous strain

Do not add numeric tension accumulation.

If a tiny scalar is needed purely for animation, it must not become an authoritative combat variable without explicit approval.

---

## Agent F — Enemy body and local manipulation

Do not begin until core strings work.

First enemy implementation:

- stationary target occupying one cell;
- lasso may pass across its body;
- valid capture/pin motif can change its state.

Later extension:

- local grab-and-drag of reachable enemy string;
- extended/multi-component enemy bodies;
- severing body components.

Do not invent these mechanics before approval.

---

## Agent G — Crafting and damage patterns

Do not begin until the loop/pull/cut sandbox is fun enough to justify extension.

Architecture should nevertheless keep motif evaluation modular.

Future examples:

- string pattern -> create crag;
- string pattern -> create cactus;
- enemy + crag motif -> capture;
- enemy + multi-crag motif -> crush;
- later topology-changing body damage.

Every crafted terrain object must be placed on a legal grid cell and then immediately become part of the obstacle/topology state.

---

## Agent H — Blender voxel art agent

Goal: generate replaceable art assets through Blender CLI without blocking mechanics.

### H1. Style

- voxel / low-poly diorama;
- strong silhouettes;
- readable from bird view;
- crags visually distinct from cacti;
- player readable at small screen footprint;
- attractive materials and lighting;
- “wonderful/breathtaking” final lighting is desirable, but gameplay readability wins.

### H2. Deliverables

Create separate assets for:

- ground tile variants;
- breakable crag;
- unbreakable crag;
- cactus;
- player placeholder;
- later enemy variants.

Export to a Godot-friendly format, preferably `.glb`.

### H3. Non-blocking rule

Gameplay agents must use primitive placeholders until generated assets are approved. Art work must never block mechanics.

---

# 5. Shared data model

Use stable, engine-independent IDs.

Suggested concepts:

```text
CellCoord(x, y)
ObjectId
PlayerId
StringId
CragId
CactusId

WorldState
  grid
  players
  crags
  cacti
  strings
  topology_revision
```

A persistent string should have at least:

```text
StringState
  id
  owner
  geometry_points_2d
  closed
  status
  caught_object_ids
  topology_class_debug_repr
  topology_revision_created
```

Do not store only scene references as game truth.

---

# 6. State transitions

All authoritative actions should be explicit state transitions, e.g.:

```text
MovePlayer
BeginLasso
ExtendLasso
CloseLasso
PullString
RecoverString
CutString
DestroyCrag
SpawnCrag
CaptureEnemy
CrushEnemy
```

Each transition should:

1. validate preconditions;
2. ask verified math services where required;
3. update logical state;
4. increment topology revision if obstacle topology changed;
5. emit events for animation/rendering.

Animations must not determine the result after the fact.

---

# 7. Testing strategy

## 7.1 Formal tests

Bend laws/proofs and examples for:

- word reduction;
- trivial/nontrivial examples;
- induced maps after deleting generators/obstacles;
- checked bounded move witnesses/certificates later.

`bend PROOF.bend` must be part of the normal test gate. Use `bend PROOF.bend --verdict` at review milestones and before trusting proof-critical changes.

## 7.2 Runtime unit tests

- no string crossing accepted;
- persistent string remains after close;
- two-crag rule destroys exactly intended crags;
- cactus only cuts during legal resolution;
- topology revision changes after cut/destroy/spawn;
- stale topology data is rejected/recomputed.

## 7.3 Golden scenario tests

Maintain tiny deterministic scenario files, e.g.:

```text
scenario_001_one_crag_anchor
scenario_002_two_crag_break
scenario_003_three_crag_stable
scenario_004_cactus_cut
scenario_005_string_blocks_string
scenario_006_capture_pin
```

Each scenario should be loadable directly for debugging.

---

# 8. Review discipline

The human owner explicitly wants to review **each small change**.

Therefore:

- commits must be narrow;
- no “while I was here” features;
- no large refactors mixed with mechanics;
- attach a screenshot/video/GIF for visible changes where practical;
- explain exactly what changed and what remains placeholder;
- stop at each milestone until approved.

If uncertain, implement the smaller version.

---

# 9. Initial task ordering

This ordering is mandatory unless blocked.

## Phase 0 — Skeleton

1. create Godot project;
2. create orthographic camera;
3. create square logical map;
4. add placeholder ground;
5. add a handful of crags;
6. add player;
7. implement grid-snapped manual movement;
8. run headless/basic tests;
9. present for review.

**STOP. Do not implement strings yet.**

## Phase 1 — Visual loop only

After approval:

1. create one string renderer;
2. allow a hardcoded or debug-authored closed loop around crags;
3. persist it;
4. make representation serializable;
5. present for review.

**STOP.**

## Phase 2 — Non-crossing and topology sync

After approval:

1. reject a second string path that crosses the first;
2. add obstacle/topology revision state;
3. add debug display of caught crags/path class where available;
4. present for review.

**STOP.**

## Phase 3 — Pull animation

After approval:

1. define canonical test tightening around one crag;
2. animate current curve to target curve;
3. repeat for two and three crags;
4. no destruction yet if that complicates debugging;
5. present for review.

**STOP.**

## Phase 4 — First motif effects

After approval:

1. two-breakable-crag destruction;
2. cactus cut;
3. recovery/retraction;
4. present for review.

**STOP.**

## Phase 5 — Verified math bridge

In parallel, formal agents should already have the Bend free-group kernel. Integrate one proof-critical predicate into an actual game/debug action.

Demonstrate end-to-end:

```text
Game geometry -> combinatorial word -> Bend proof-backed computation -> result -> game/debug UI
```

Present the relevant `law`, its proof definition, the runtime boundary, the test case, and successful outputs of `bend PROOF.bend` and `bend PROOF.bend --verdict`.

**STOP.**

## Phase 6 — Enemy capture

Only after approval:

1. add stationary enemy;
2. allow loops to include enemy body;
3. implement one capture/pin motif;
4. present for review.

---

# 10. Formal AI roadmap

Do not build sophisticated AI until the mathematical state model is stable.

When ready, use a proof/certificate architecture.

Example future query:

> Does player P have a legal sequence of at most `k` actions reaching `Win(state)`?

Recommended architecture:

1. define `LegalAction`, `step`, `Win`, and the bounded-plan specification in Bend;
2. state the correctness requirements as laws in `LAWS.bend`;
3. implement search in Bend so successful results carry or induce the proof required by the specification;
4. prove the corresponding laws in `PROOF.bend`;
5. run `bend PROOF.bend`, and use `--verdict` for critical checkpoints;
6. if no candidate is found, do **not** interpret that as a proof of impossibility unless the Bend development separately proves completeness of the bounded search.

For universal claims such as “every opponent response has a winning answer”, require an appropriately complete proof object/tree or a proved complete decision procedure.

Keep the distinction between:

- witness of existence;
- proof of impossibility;
- heuristic failure to find a witness.

This distinction is mandatory.

---

# 11. Coding standards

- deterministic core game state;
- render/animation separated from authoritative state transitions;
- stable IDs;
- explicit serialization;
- unit tests for topology-sensitive transitions;
- no hidden singleton state where avoidable;
- no unexplained magic numbers;
- feature flags for unfinished mechanics;
- debug overlays for geometry/topology mismatch;
- comments should explain invariants, not restate code.

---

# 12. Non-goals for now

Do not implement:

- 3D knot topology;
- over/under crossings;
- physical rope simulation;
- rope HP;
- network multiplayer;
- advanced procedural generation;
- full crafting economy;
- limb severing;
- string stealing;
- multiple manifold layers;
- complex combat balance;
- production UI.

---

# 13. Definition of success for the first sandbox

The first meaningful sandbox is successful when a player can:

1. walk on a small orthographic voxel map;
2. see several crags and at least one cactus;
3. create a smooth persistent loop around selected obstacles;
4. observe that persistent strings obstruct later string placement;
5. pull a loop and see it tighten deterministically;
6. break two crags through the designated motif;
7. cut a string through the cactus rule;
8. recover a string when topology permits;
9. observe at least one game decision backed by the verified math layer;
10. load tiny deterministic scenarios for experimentation.

At that point, stop adding mechanics and **play the sandbox**. The next mechanics should be chosen from observed failure modes and interesting emergent interactions, not from speculative feature accumulation.
