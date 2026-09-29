# AGENTS.md — Mandatory Instructions for All Agents

> **Read this file completely before making any change.**
>
> This repository is intentionally developed in small, reviewable increments.  
> Do not improvise broad redesigns, do not "improve" unrelated systems, and do not assume that code which compiles or an asset which exports is automatically acceptable.

---

# 1. Project Goal

**FundamentalFight** is a topological combat game.

The core idea is:

- the world is visually rendered in 3D,
- but the gameplay topology is fundamentally 2D,
- the ground is a tiled 2D manifold,
- crags, cacti, players, and strings occupy or interact with that manifold,
- persistent strings act as topological obstacles,
- lassoing, winding, pulling, contracting, trapping, cutting, and changing the topology of the map are the primary mechanics,
- complex winding patterns should feel like **casting spells using topology**.

The game should not become a rope-physics simulator.

The implementation should prioritize:

1. mathematically precise game rules,
2. deterministic behavior,
3. machine-checkable correctness where appropriate,
4. simple and readable gameplay,
5. visually pleasant voxel presentation,
6. very small reviewable development steps.

---

# 2. Core Mathematical Model

Unless a task explicitly says otherwise, assume the game is based on a **strictly 2D topological gameplay surface**.

The 3D rendering is only a visual realization.

Do **not** silently change the game into a 3D knot/link topology problem.

The playable surface is conceptually

\[
M \setminus K
\]

where:

- \(M\) is the 2D gameplay manifold,
- \(K\) is the current obstacle set,
- obstacles may include crags, cacti, persistent strings, and other blocked structures.

Persistent strings are topological obstacles and cannot be crossed freely.

Crags act as holes/puncture-like obstacles.

When obstacles are added or removed, the topology of the playable space changes.

Old loop/path classes may change under the appropriate induced maps.

For many planar cases, the relevant fundamental group is expected to reduce to a free group.

Prefer representations which make:

- word reduction,
- path classes,
- loop triviality,
- induced maps,
- obstacle updates,
- legal homotopies,

explicit and testable.

Do not replace exact topology with geometric heuristics unless the task explicitly permits an approximation.

---

# 3. Bend 2 Is the Primary Proof-Bearing Math Layer

Bend 2 is the preferred formal/computational core for proof-relevant game mathematics.

Examples of functions which should not silently become heuristic black boxes:

- "is this loop word trivial in this group?"
- "are these two paths equivalent?"
- "does this move preserve the required invariant?"
- "is this move legal?"
- "does this move sequence produce a winning state?"
- "is there a winning move within at most X steps?"
- "does removing this obstacle induce the expected change in topology?"

Whenever practical, important correctness claims should be expressed as laws/specifications and checked by Bend's proof system.

Use the Bend 2 workflow intentionally:

- laws/specifications belong in clearly identifiable proof/spec files,
- proofs should be machine-checkable,
- use Bend's proof-verification tooling,
- prefer proof-producing or certificate-producing algorithms over unchecked Boolean claims where useful.

Lean may be used for:

- deeper formalization,
- metatheory,
- independent verification,
- mathematics that is significantly easier to express in Lean.

But Lean is **not automatically required behind every Bend computation**.

Do not invent a fake "Bend computes, Lean always validates" architecture unless explicitly requested.

---

# 4. Core Gameplay Assumptions

The current intended gameplay loop is:

1. A player throws a lasso.
2. The lasso catches some subset of crags, players, or other valid targets.
3. Closing the lasso creates a persistent loop/string.
4. Persistent strings remain in the world and obstruct future strands.
5. A player may pull a string.
6. Pulling attempts to tighten the string to a canonical or locally canonical valid representative without crossing forbidden obstacles.
7. The resulting topological configuration determines a discrete gameplay effect.
8. Certain configurations may:
   - move the player,
   - move another object,
   - break crags,
   - cut strings,
   - trap/capture enemies,
   - crush or sever enemy components,
   - craft new terrain.
9. A string can be recovered if it can be retracted along a legal homotopy.
10. Otherwise it remains committed until the topology changes.

The game should prefer **discrete topological outcomes** over continuous force simulation.

Examples:

- taut around one crag → movement anchor,
- taut around two breakable crags → both may break,
- taut around three crags → stable non-breaking configuration,
- taut around enemy + crag → pin/drag/constrain,
- taut against cactus → string may be cut,
- special capture/crush motifs → enemy damage or geometry change.

These are design rules, not all necessarily implemented yet.

Do not implement unapproved mechanics just because they are listed here.

---

# 5. Strings Have No HP

Strings do **not** have conventional health bars.

Avoid:

- string HP,
- damage-over-time rope degradation,
- arbitrary durability numbers,
- physics-based tensile simulation unless explicitly requested.

A string should generally be in a discrete state such as:

- present,
- loose,
- taut,
- grabbed,
- trapped,
- retractable,
- cut,
- destroyed.

If a string is destroyed, there should be a clear topological/gameplay reason.

---

# 6. Cacti

Cacti are currently the canonical "scissor" terrain object.

Conceptually:

- a cactus cuts/destroys a string under a valid pull/contraction interaction,
- it should not behave as a generic passive damage collider unless explicitly requested.

Do not automatically make every visual contact with a cactus destroy a string.

The exact cutting rule must remain explicit and deterministic.

---

# 7. Enemy Strings

Enemy strings are genuine gameplay obstacles.

They should not be treated as decorative splines.

They should affect:

- reachable regions,
- legal winding routes,
- retractability,
- path classes,
- future lasso placement.

Current open design areas include:

- local manual grabbing and repositioning of enemy string segments,
- dragging a string around nearby terrain,
- trapping enemy strings,
- possibly hooking strings using other strings.

Do not choose among these open alternatives without a task explicitly asking for a decision.

For now, preserve the fundamental rule:

> Existing strings matter topologically and are not freely crossed.

---

# 8. Player Bodies

A player/enemy body may eventually be:

- extended rather than point-like,
- multi-component,
- deformable in its combinatorial geometry,
- severable by valid string patterns.

Losing a limb/component may change:

- available movement,
- reach,
- lasso capabilities,
- tactical options,
- geometry.

Do not assume every player is permanently a single circular capsule.

For early prototypes, simple placeholder geometry is acceptable.

---

# 9. Map Representation

The map is discrete for gameplay placement.

Use a square grid.

A tile may contain or reference things such as:

- ground,
- crag,
- cactus,
- player,
- anchor,
- special terrain,
- crafted object.

Movement may snap to grid coordinates.

However:

> Strings should visually appear continuous.

Do not render strings as ugly staircase/grid-line paths unless a task explicitly requires a debug representation.

The internal topology may use discrete/combinatorial data while the presentation interpolates smooth curves.

---

# 10. Rendering and Art Direction

The game is visually 3D.

Target style:

- voxel / low-poly,
- bird-view,
- orthographic or near-orthographic camera,
- clean readable silhouettes,
- strong but tasteful lighting,
- attractive shadows,
- pleasant ambient occlusion,
- restrained reflections,
- cohesive palette,
- readable gameplay objects.

The goal is **pleasant and atmospheric**, not photorealistic.

Use Godot 4.

Prefer the Forward+ renderer unless a task explicitly requires otherwise.

Do not add expensive visual systems without a reason.

The renderer is capable enough; the main challenge is art direction and visual feedback.

---

# 11. Visual Agents Must Never Work Blind

A visual task is **not complete** merely because:

- Blender exported a `.glb`,
- Godot loaded the scene,
- the game runs,
- a mesh exists,
- a shader compiles.

For visual changes, use a deterministic visual feedback loop whenever possible.

Recommended workflow:

1. Build or update the asset/scene.
2. Open/render it in a fixed benchmark scene.
3. Capture one or more deterministic screenshots.
4. Inspect:
   - silhouette,
   - scale,
   - framing,
   - lighting,
   - readability,
   - overlap,
   - material appearance,
   - whether the object looks intentional rather than procedural/random.
5. Only then consider the task complete.

For Blender assets, prefer fixed camera turntable renders.

For Godot visual changes, prefer fixed test scenes and fixed cameras.

If the agent cannot visually inspect the result, say so explicitly and do **not** claim the result "looks good."

---

# 12. Visual Language

Unless a task overrides this:

## Camera

- bird-view,
- orthographic or nearly orthographic,
- stable composition,
- no unnecessary camera distortion.

## Voxel Geometry

- chunky,
- readable at gameplay distance,
- intentional silhouette,
- avoid random voxel noise,
- avoid shapeless procedural blobs,
- avoid thin fragile protrusions unless meaningful.

## Crags

- broad and grounded,
- asymmetrical,
- readable as natural stone structures,
- 2–4 dominant masses are usually better than many tiny details,
- should look good from the actual gameplay camera, not only in a close-up render.

## Materials

- mostly matte,
- avoid plastic-looking surfaces,
- restrained roughness variation,
- subtle material variation is welcome.

## Lighting

- one clear key light,
- coherent shadow direction,
- ambient fill,
- soft contact shadowing,
- avoid excessive bloom,
- avoid overexposed highlights.

## Strings

- readable against terrain,
- visually continuous,
- smooth enough to read as ropes/energy strands,
- may use subtle emissive emphasis when active,
- should not disappear against background materials.

---

# 13. Small Steps Only

This project must be developed in small increments.

The user reviews changes frequently.

Do not implement five systems at once.

Do not "finish the whole feature" unless asked.

When given a task, prefer the smallest complete slice that proves the idea.

Example progression:

1. map only,
2. map + crags,
3. player movement,
4. one visible string,
5. one persistent string,
6. winding around a crag,
7. pulling,
8. cutting,
9. enemy interaction,
10. crafting,
11. advanced topology.

If asked for step 2, do not silently implement step 7.

---

# 14. Do Not Modify Unrelated Systems

This is mandatory.

When working on a task:

- identify the files and systems actually required,
- make the smallest viable change,
- do not "clean up" unrelated code,
- do not rewrite architecture without permission,
- do not rename unrelated files,
- do not reformat the entire project,
- do not replace shaders, camera, lighting, or materials unless the task requires it,
- do not change math APIs to make a visual task easier,
- do not change art to make a logic task easier.

If an unrelated problem blocks progress, report it.

Do not silently solve it by redesigning another subsystem.

---

# 15. Agent Ownership / Parallel Work

Assume multiple agents may work in parallel.

Avoid conflicting edits.

Typical ownership boundaries:

- `formal/**` → topology / Bend / proofs,
- `scripts/topology/**` → runtime topology representation,
- `scripts/gameplay/**` → gameplay systems,
- `tools/blender/**` → Blender automation,
- `assets/generated/**` → generated assets,
- `scenes/**` → Godot scenes,
- `tests/**` → tests.

Before editing shared files:

- check whether the task really requires it,
- minimize shared-file edits,
- do not rewrite central project files casually.

Avoid having multiple agents freely modify the same main scene.

---

# 16. Determinism

Topology and gameplay state transitions should be deterministic.

Avoid hiding important behavior behind:

- physics instability,
- random collision order,
- frame-rate dependence,
- arbitrary floating-point thresholds,
- nondeterministic procedural generation.

Animation may be smooth and approximate.

Gameplay state must remain explicit.

The animation is allowed to look physical.

The underlying rule should remain topological/combinatorial.

---

# 17. Separation of Model and Presentation

Prefer a clean separation:

## Mathematical/game state

Contains:

- grid,
- obstacles,
- strings,
- path/loop topology,
- ownership,
- legal actions,
- resulting discrete state transitions.

## Presentation

Contains:

- meshes,
- curves,
- animation,
- shaders,
- particle effects,
- lighting,
- interpolation.

Do not let a spline animation define the authoritative topology.

Do not infer core game state from rendered geometry if the logical state is already known.

The game should know what a string means independently of how it is currently animated.

---

# 18. Testing

Every nontrivial mathematical/gameplay feature should have automated tests where feasible.

Especially test:

- word reduction,
- loop triviality,
- induced map behavior,
- obstacle insertion/removal,
- legal/illegal movement,
- legal/illegal string crossing,
- retractability,
- deterministic pull results,
- crag destruction rules,
- cactus cutting rules.

Prefer tiny canonical examples over giant integration tests.

Visual systems should have reproducible benchmark scenes.

---

# 19. Do Not Hallucinate Mathematics

If uncertain about a topological statement:

- stop,
- derive it carefully,
- consult the existing formalization/docs,
- or state the uncertainty.

Do not invent a theorem because it sounds plausible.

Distinguish carefully between:

- homotopy,
- homology,
- fundamental group,
- free-group words,
- planar graph complement,
- geometric embedding,
- isotopy,
- path equivalence,
- contractibility.

The game is deliberately based on real mathematics.

---

# 20. Do Not Hallucinate Visual Success

Never say:

- "this looks great,"
- "the lighting is beautiful,"
- "the silhouette is improved,"
- "the composition is correct,"

unless you actually inspected a render/screenshot.

If only code was changed, say exactly that.

---

# 21. Communicate Uncertainty

When a design choice is still open, preserve it as open.

Examples currently not fully locked:

- finite vs unlimited total rope length,
- exact number of active strings per player,
- exact enemy-string manipulation mechanic,
- exact crafting recipes for crags/cacti,
- exact damage motifs,
- exact rules for stealing/capturing strings.

Do not convert these into permanent architecture without approval.

---

# 22. Preferred Task Completion Format

At the end of a task, report:

## Changed

- exact files,
- exact behavior added/modified.

## Verified

- tests run,
- Bend checks run,
- Godot scene launched,
- Blender render inspected,
- screenshots checked.

## Not Changed

Mention important nearby systems deliberately left untouched.

## Open Issues

Only real unresolved problems.

Keep this concise.

---

# 23. First Principle

When in doubt, optimize for:

> **small, mathematically explicit, visually inspectable, reversible changes.**

Do not optimize for appearing autonomous.

Do not maximize the amount of code written.

A correct 50-line change that can be reviewed immediately is better than a 2,000-line "complete system" built on unverified assumptions.

---

# 24. Final Preflight Checklist

Before doing anything, ask yourself:

- Did I read this file fully?
- Do I understand whether this task is math, gameplay, visual, tooling, or mixed?
- Am I touching only necessary files?
- Am I preserving the strict 2D gameplay topology?
- Am I keeping game state separate from presentation?
- If this is proof-relevant, do I need a Bend law/proof/certificate?
- If this is visual, how will I inspect the rendered result?
- Am I introducing a mechanic that has not been approved?
- Can I make the change smaller?
- Can the user review this change immediately?

If any answer is unclear, reduce scope before proceeding.
