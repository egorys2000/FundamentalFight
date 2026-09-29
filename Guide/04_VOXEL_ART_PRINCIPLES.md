# Voxel art principles

This document defines how Fundamental Fight uses voxel art. It is intentionally
stricter than “low-poly”: a voxel asset is a volume of occupied cells on one
regular lattice, later meshed for rendering.

## What a voxel is

A voxel is the 3D analogue of a pixel: a value sampled on a regular grid. The
asset's primary data is therefore integer cell coordinates plus state/material,
not a collection of freely positioned polygons. The Blender generator follows
this model and emits only exposed faces of occupied cells.

Asset coordinates use `(x, y, z)` with `y` as height/up, matching the game's
logical convention. Blender itself is Z-up, so the exporter performs an
explicit axis conversion; asset authors must not compensate by rotating
individual models.

The render lattice is currently `0.125 m`. Existing design motifs are expanded
to this finer lattice so silhouettes gain resolution without changing their
world/gameplay scale.

Sources consulted:

- [Voxel, Wikipedia](https://en.wikipedia.org/wiki/Voxel), for the grid and
  surface-rendering distinction.
- [MagicaVoxel](https://ephtracy.github.io/), for the established palette,
  model-grid, and orthographic voxel-workflow vocabulary.

## The Riftgarden Voxel style

Our own style is **Riftgarden Voxel**: a readable tactical diorama with
geological, stepped forms and a small amount of luminous game-language.

1. **Silhouette before detail.** At the intended bird-view camera, an object
   must be identifiable as a dark cutout before color or decoration is added.
2. **Stepped masses.** Large forms use terraces, ledges, tapers, and visible
   strata. A single rectangular extrusion is a placeholder, not a finished
   asset.
3. **Three scales of information.** Use a primary mass, secondary structural
   masses, then sparse micro-detail. Micro-detail must never repair a weak
   silhouette.
4. **Quantized asymmetry.** Natural objects should be irregular, but every
   irregularity is made from whole cells. Avoid mirrored procedural blobs and
   avoid random noise that destroys a readable design.
5. **Material tells gameplay.** Breakable rock, unbreakable rock, cactus, and
   player must differ in value and hue before lighting is applied. Gameplay
   categories cannot depend on texture detail.
6. **Palette is authored.** A normal asset uses one base, one shadow, one
   light/accent, and optionally one gameplay/emissive accent. More colors are
   earned by a design need, not by random per-voxel variation.
7. **Negative space is designed.** Gaps, notches, arches, and overhangs are
   useful only when they survive the camera distance and do not create
   accidental visual noise.
8. **No smoothness by stealth.** No bevels, smooth shading, rotated cubes,
   cylinders, curves, or fractional dimensions in authored assets. A render
   may use good lighting, ambient occlusion, and anti-aliasing; the geometry
   remains quantized.
9. **Lighting supports planes.** Use a broad warm key, restrained cool fill,
   contact shadows, and a dark neutral background. Do not use bloom to make
   an unreadable object appear detailed.
10. **Gameplay scale wins.** The asset is judged in the actual Godot
    orthographic camera, not only in a close Blender render.
11. **Landmarks can dominate.** A crag that anchors an irreversible-looking
    loop should be a landmark, not a pebble. Vertical scale communicates
    commitment: the player is wrapping a cliff, not tying a stone.

## Proportion rules

- The smallest gameplay-recognizable feature is at least 2 cells wide.
- A hero silhouette should have at least three height bands.
- The main hero uses a tall vertical silhouette and a broad hat brim as its
  recognition cue; the face/visor must remain readable from the gameplay view.
- Anchor crags should read as mountains: many times the hero's height when they
  represent loops that are visually difficult or impossible to unwind.
- Primary mass: roughly 60–80% of occupied cells.
- Secondary masses: roughly 15–35%.
- Micro-details: no more than 10% and preferably grouped in 2–4 cell motifs.
- Keep a one-cell visual separation between accent motifs where possible.

These are review heuristics, not mathematical laws. They prevent a common
failure mode where an asset is technically voxelized but reads as a noisy pile
of cubes.

## Asset review checklist

Before exporting:

- Is the silhouette identifiable in a 64 px thumbnail?
- Is the object still readable with materials disabled?
- Are all occupied cells on integer coordinates?
- Is the object connected unless floating pieces are intentional?
- Does the palette communicate its gameplay category?
- Are the top, front, and shadow-facing planes intentionally varied?
- Does the object fit the logical grid cell and collision footprint?
- Does it look like it belongs beside the other Riftgarden assets?
