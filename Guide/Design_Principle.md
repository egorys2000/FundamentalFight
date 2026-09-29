# Task: Redesign and Upgrade Primitive 3D Voxel Models

You are a senior 3D voxel asset designer and technical environment artist.

You are given two very primitive blockout models. They currently read mostly as arbitrary stacked cuboids rather than intentional game assets.

Your task is to redesign them into visually rich, coherent voxel-style assets while preserving their broad identity, approximate scale, and original functional concept.

The goal is NOT photorealism.

The goal is:
- strong silhouette
- readable structure
- intentional shape hierarchy
- voxel-native geometry
- pleasant stylization
- believable construction
- enough detail to feel authored rather than procedurally assembled
- good readability from gameplay distance

The resulting models should look suitable for a polished stylized 3D voxel game.

---

# Critical Design Principle

Do NOT solve this task by simply adding more cubes.

The current models already suffer from:
- large undifferentiated box surfaces
- unclear function
- arbitrary protrusions
- weak silhouette
- almost no material language
- little or no secondary structure
- no meaningful detail hierarchy
- insufficient color/value separation
- little evidence of wear, construction, joints, seams, support, or functional logic

The redesign must replace this with deliberate visual structure.

Every geometric feature must serve at least one purpose:

1. improve silhouette
2. communicate function
3. communicate material
4. establish scale
5. create visual rhythm
6. create a focal area
7. explain how the object is constructed

Avoid decoration that exists only because "more detail looks better."

---

# MODELING WORKFLOW

Work in explicit passes.

Do not jump directly into small details.

## PASS 1 — Interpret the Existing Blockout

First inspect the current model and infer:

- what the object most likely represents
- which masses are structural
- which masses are attachments
- where its front/back/top/bottom are
- which areas should be visually dominant
- which elements can be redesigned freely
- which proportions should remain recognizable

Do not preserve accidental geometry merely because it exists in the blockout.

Treat the existing model as a composition and scale reference, not as finished geometry.

Before modeling, summarize your interpretation in 3–6 sentences.

---

# PASS 2 — Establish Primary Forms

Rebuild or adjust the main forms first.

Primary forms should account for roughly:

    60–75% of total visible mass

Use approximately:

    3–7 major masses

The model must have an immediately understandable silhouette.

Test it visually from:

- front
- rear
- left
- right
- three-quarter gameplay view
- slightly elevated gameplay camera

A completely black silhouette should still look intentional.

## Avoid

Do not leave the model as:

    box
    + smaller box
    + another box
    + random extrusion

Instead, establish:

- tapering
- stepped profiles
- cut-ins
- overhangs
- recesses
- offsets
- asymmetry
- clearly connected volumes

Large forms should relate to each other.

---

# PASS 3 — Secondary Forms

Add secondary geometry that explains the object.

Secondary forms should account for approximately:

    20–30% of visual information

Examples:

- structural supports
- frames
- housings
- armor plates
- side modules
- brackets
- beams
- railings
- rims
- lips
- doors
- vents
- hatches
- mechanical joints
- foundation pieces
- panel groups
- roof structures
- buttresses
- pipes
- channels
- access platforms

Secondary geometry must break up the overly large flat surfaces visible in the current models.

Large wall-like faces should almost never remain completely featureless unless the emptiness is compositionally intentional.

---

# PASS 4 — Tertiary Detail

Only after the primary and secondary forms work, add small detail.

Tertiary detail should represent roughly:

    5–10% of the visual hierarchy

Examples:

- bolts
- panel seams
- handles
- hinges
- small vents
- warning plates
- cables
- small pipes
- maintenance covers
- brackets
- steps
- edge wear
- tiny missing blocks
- trim
- fastening points

Do NOT cover every surface equally.

Detail must be clustered.

Good:

    quiet surface
    quiet surface
    medium-detail region
    focal high-detail cluster
    quiet surface

Bad:

    every square meter has random small cubes

---

# INFORMATION DENSITY

Use deliberate contrast between quiet and busy regions.

Target approximately:

    35–55% quiet surfaces
    30–45% medium-complexity surfaces
    10–20% high-detail focal regions

The current models are almost entirely "quiet primitive mass."

The redesign should introduce controlled complexity rather than uniform complexity.

---

# SILHOUETTE DESIGN

The current silhouettes are too rectangular and accidental.

Improve them using:

- stepped profiles
- narrow/wide transitions
- asymmetric attachments
- deliberate top structures
- cut corners
- recesses
- projecting machinery
- structural supports
- negative spaces
- varying height

Create at least 3 recognizable silhouette events per major viewing angle.

For example:

    broad base
    narrowing middle
    offset upper module
    projecting side component

Do not make every layer centered.

Perfect symmetry is allowed only where the object logically demands it.

---

# SHAPE LANGUAGE

Choose a coherent shape language for each asset.

Examples:

## Industrial / Mechanical

Use:
- strong rectangular masses
- inset panels
- ribs
- vents
- pipes
- access hatches
- structural frames
- bolts
- protected edges

## Heavy machinery

Use:
- thick lower mass
- exposed functional modules
- reinforced joints
- large housings
- chunky supports
- occasional asymmetry
- visible maintenance areas

## Architectural

Use:
- clear facade hierarchy
- frame → opening → trim → inset
- repeating structural rhythm
- occasional interruption
- roofline articulation
- foundations

Do not mix unrelated visual languages without reason.

---

# FUNCTIONAL STORYTELLING

Every major feature should answer:

> Why is this here?

For every pipe:

    Where does it start?
    Where does it lead?

For every support:

    What does it support?

For every hatch:

    What could a person access through it?

For every protrusion:

    Is it mechanical, structural, protective, decorative, or functional?

For every recess:

    Why is the surface recessed?

The current blockout contains several arbitrary-looking protrusions.

Replace those with believable functional elements.

---

# SCALE CUES

The current models lack a sense of scale.

Add scale cues appropriate to the asset.

Possible cues:

- doors
- access panels
- steps
- railings
- handles
- ladders
- ventilation grilles
- bolts
- panel dimensions
- maintenance hatches

Use these sparingly.

Scale cues must be dimensionally consistent.

Do not mix a human-sized door with enormous micro-sized rivets.

---

# MATERIAL LANGUAGE

Materials must be distinguishable even without realistic textures.

Communicate material through BOTH:

1. color/value
2. geometry

Examples:

## Metal

Use:
- panels
- seams
- vents
- bolts
- reinforced edges
- inset access covers
- manufactured regularity

## Concrete

Use:
- large uninterrupted masses
- occasional seams
- chipped corners
- supports
- darker recesses
- restrained surface variation

## Wood

Use:
- beam structure
- planks
- irregular ends
- layered construction
- less perfectly machined geometry

## Stone

Use:
- clustered blocks
- varying block size
- chipped edges
- structural compression
- irregular but coherent rhythm

## Painted machinery

Use:
- one dominant body color
- darker structural components
- exposed metal
- warning/accent colors
- worn edges where appropriate

Do not communicate every material using only different flat colors.

---

# COLOR DESIGN

The current palette is extremely flat.

Build a controlled palette.

Use approximately:

    3–6 primary material colors
    1–3 darker variants
    1–2 highlight variants
    1 accent family

Avoid rainbow coloration.

Large color regions should correspond to meaningful construction/material regions.

Good example:

    dark structural frame
    medium body panels
    light exposed top surfaces
    small saturated accent

Do not randomly assign different colors to adjacent cubes.

---

# VALUE STRUCTURE

The model should remain readable in grayscale.

Create:

- light surfaces
- midtone body
- dark recesses
- deep shadow cavities
- occasional bright accents

Important features should have value contrast against their surroundings.

Do not let the entire asset collapse into one medium-dark mass.

---

# TOP SURFACES

The first reference model currently contains very bright, almost empty top surfaces.

These areas need deliberate treatment.

Do one or more of:

- add raised borders
- inset panels
- machinery
- hatches
- roof structures
- rails
- vents
- maintenance zones
- contrasting material patches
- stepped geometry

Large white polygons should not appear accidentally exposed.

If a top surface is meant to be bright, make it an intentional material choice.

---

# SIDE SURFACES

The huge vertical walls currently dominate the model.

Break them into hierarchy:

    main wall
    structural frame
    inset panel
    secondary module
    localized detail

Do not tile identical panels over the whole surface.

Use repetition with interruption.

Example rhythm:

    panel
    panel
    panel
    structural break
    service hatch
    panel
    vent cluster

---

# EDGES AND CORNERS

The models currently have extremely sharp, simple box edges.

Keep the voxel aesthetic, but add controlled edge treatment.

Possible approaches:

- 1-voxel chamfers
- stepped corners
- reinforced trim
- recessed borders
- chipped corners
- layered plates
- extruded edge bands

Do NOT bevel every edge equally.

Important silhouette edges may remain sharp.

Edge treatment should reinforce hierarchy.

---

# NEGATIVE SPACE

Introduce negative space where appropriate.

Examples:

- undercuts
- gaps between modules
- recessed maintenance channels
- openings
- structural arches
- space beneath overhangs
- separated machinery blocks

Negative space is critical for avoiding the appearance of a single solid cube.

---

# ASYMMETRY

The asset may have a broadly symmetrical structural base, but add controlled asymmetry.

Possible asymmetry:

- side maintenance module
- pipe cluster
- antenna
- damaged panel
- service platform
- vent group
- cable connection
- offset upper housing

Do not create random asymmetry.

Asymmetry must have an explanation.

---

# REPETITION AND RHYTHM

Use repetition to communicate construction.

Examples:

- ribs
- windows
- vents
- beams
- panel sections
- vertical supports

But interrupt repetition periodically.

Avoid procedural-looking patterns such as:

    vent vent vent vent vent vent vent

Prefer:

    vent vent vent
    blank structural section
    hatch
    vent vent

Variation should be subtle and intentional.

---

# VOXEL RESOLUTION

Choose a clear implied voxel scale and respect it.

Do not create inconsistent levels of detail.

For example, if a human door is roughly 5–8 voxels tall, do not add meaningless 1/10-voxel-sized mechanical details.

Keep voxel dimensions visually consistent.

The model should feel designed in voxel space rather than converted from a smooth high-poly asset.

---

# DO NOT OVER-VOXELIZE

Voxel art does NOT mean every contour needs staircase noise.

Keep large forms clean.

Use voxel stepping where it strengthens:

- silhouette
- curvature approximation
- damaged surfaces
- structural transitions

Do not turn every surface into jagged noise.

---

# MODEL 1 — SPECIFIC REDESIGN DIRECTION

The first model currently reads as:

- one enormous dark rectangular central body
- large bright top slabs
- a narrow tower made from stacked boxes
- small isolated bright blocks
- an oversized dark-blue base/platform
- several protrusions that lack clear function

Redesign it as a coherent heavy industrial / technological structure.

Potential interpretation:

    heavy machine
    reactor module
    industrial tower
    defensive installation
    power unit
    processing machine

Do NOT radically change its footprint.

Improve it as follows:

### Base

The blue base should become an intentional foundation.

Add:

- stepped foundation layers
- structural corners
- attachment points
- possibly channels or rails
- visible relationship between the machine body and base

The machine must look physically supported by the base.

### Main Body

Break the giant flat dark wall into 3–5 large structural regions.

Possible pattern:

    outer frame
    recessed central panel
    lower service panel
    vertical structural supports
    side machinery block

Introduce depth changes of approximately:

    1–4 voxel units

Avoid decorative checkerboarding.

### Upper Body

The current upper stacked cubes should become one coherent assembly.

For example:

    central core
    raised housing
    exhaust/vent section
    side attachment
    top maintenance structure

Different pieces should overlap and interlock visually.

### Side Protrusions

Turn arbitrary blocks into:

- vents
- conduits
- access units
- armored housings
- sensor pods
- structural brackets

### Top

Replace empty white regions with an intentional roof/service area.

Possible features:

- recessed hatch
- two vent clusters
- narrow access walkway
- raised machinery block
- warning stripe/accent
- protective rim

### Focal Area

Choose ONE focal region.

For example:

    illuminated reactor/service panel

or

    large front mechanical hatch

or

    upper machinery assembly

Increase contrast and detail there.

Everything else should support it.

---

# MODEL 2 — SPECIFIC REDESIGN DIRECTION

The second model currently reads almost entirely as a cross-shaped assembly of rectangular prisms.

It needs much stronger structural interpretation.

Preserve the broad central-plus-side-arms composition, but transform it into a meaningful object.

Potential interpretations:

    drone
    machine hub
    suspended device
    sci-fi junction
    mechanical cross-module
    turret-like assembly
    energy distribution unit

Choose ONE interpretation and design consistently around it.

### Central Body

The central vertical mass should become a strong core.

Add hierarchy:

    central housing
    inset front
    lower extension
    top cap
    side attachment interfaces

Avoid one continuous featureless column.

### Horizontal Arms

The side arms should not be identical rectangular beams.

Give them:

- connection joints
- narrower roots or reinforced roots
- end modules
- underside structure
- occasional asymmetry

Create a clear transition:

    central hub → connector → arm → terminal module

### Top Cap

The light top block should become a deliberate top module.

Possible function:

- sensor
- power cell
- maintenance access
- control module
- light source

Integrate it structurally into the core.

### Depth

Currently the model reads almost like a flat arrangement.

Increase three-dimensionality by adding:

- front protrusions
- rear modules
- recessed sections
- layered arm depth
- under-structure
- top/bottom variation

It should remain interesting when rotated.

### Color

Use at least:

- main body tone
- darker structural tone
- lighter secondary material
- small accent color

Avoid making the entire asset one nearly uniform green mass.

---

# LIGHTING-AWARE DESIGN

The object should read under simple game lighting.

Geometry must do most of the work.

Do not rely on complex materials or post-processing to hide weak modeling.

Test under:

- neutral daylight
- warm directional light
- low-angle side light

Ensure cavities create useful shadows.

Ensure protrusions catch highlights.

---

# GAMEPLAY-DISTANCE TEST

Render the model from at least three distances:

## Close

Small tertiary details visible.

## Medium

Secondary structure visible.

## Far

Only primary shape and color blocking remain.

At far distance the model must still have:

- recognizable silhouette
- identifiable front/back
- recognizable major components
- clear value separation

If the asset only looks good close up, simplify or strengthen major forms.

---

# CAMERA ROTATION TEST

Rotate the model 360°.

No side should feel unfinished.

Avoid the common failure mode:

    detailed front
    completely flat back

The back may be simpler, but should still contain construction logic.

---

# DETAIL BUDGET

Do not blindly maximize geometry.

Prioritize:

1. silhouette
2. main form hierarchy
3. functional secondary structure
4. material separation
5. focal detail
6. tertiary decoration

If something does not improve one of these, remove it.

---

# PROCEDURAL-LOOK FAILURE MODES TO AVOID

Absolutely avoid:

- random cubes glued to surfaces
- random noise
- evenly distributed greebles
- identical details repeated everywhere
- arbitrary color patches
- excessive symmetry
- huge empty rectangular walls
- disconnected floating pieces
- tiny details without medium-scale structure
- every surface having the same complexity
- features with no plausible function
- changing the model into a smooth conventional mesh and merely pixelating it afterward

---

# SELF-CRITIQUE LOOP

After each modeling pass, critically inspect the model.

Ask:

## Silhouette
Would I recognize it in solid black?

## Hierarchy
Can I immediately identify:
- primary forms
- secondary forms
- detail?

## Function
Can I explain what the main parts do?

## Material
Can I tell materials apart without labels?

## Scale
Do I understand approximately how large this object is?

## Rhythm
Are repeated structures broken by meaningful variation?

## Detail
Are details clustered rather than uniformly sprinkled?

## Composition
Is there one dominant focal area?

## Voxel language
Does this look designed as voxel art, rather than crude low-poly modeling?

If the answer is no, revise before proceeding.

---

# ITERATION REQUIREMENT

Do not stop after one pass.

Perform at least:

    Blockout refinement
    ↓
    Primary-form critique
    ↓
    Secondary-form pass
    ↓
    Silhouette critique
    ↓
    Material/color pass
    ↓
    Detail pass
    ↓
    Gameplay-distance render
    ↓
    Final cleanup

After each critique, make concrete changes rather than merely describing problems.

---

# FINAL DELIVERABLES

For each asset produce:

1. Final 3D model
2. Clean object hierarchy / naming
3. Material palette
4. Front render
5. Rear render
6. Side render
7. Three-quarter beauty render
8. Gameplay-distance render
9. Short design explanation containing:
   - intended function
   - shape-language decisions
   - material choices
   - focal area
   - major changes from the original blockout

If using Blender, ensure the final asset can be exported cleanly to `.glb`.

Avoid unsupported procedural dependencies in the exported asset.

---

# FINAL QUALITY BAR

Do not ask:

> "Did I add enough detail?"

Ask:

> "Does every scale of the object contain meaningful structure?"

A successful result should have:

### Large scale
Recognizable silhouette and proportion.

### Medium scale
Construction, function, modules, panels, supports.

### Small scale
Localized accents, joints, vents, bolts, wear.

The model must look intentionally designed at all three scales.

The target is a polished voxel game asset, not a collection of primitives.
