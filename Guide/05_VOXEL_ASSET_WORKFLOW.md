# Voxel asset workflow

This is the production workflow for generated art. It keeps art replaceable
while making the important visual decisions explicit and reviewable.

## 1. Establish the contract

Every asset declares:

- logical footprint in game cells;
- voxel resolution (`0.25 m` currently);
- gameplay category;
- silhouette reference;
- palette roles;
- intended camera and thumbnail size.

The logical footprint is not the same thing as the mesh bounding box. A crag
can occupy one gameplay cell while using a taller voxel volume above it.

## 2. Build from a small sketch

Start with a top-down footprint and a side elevation represented as integer
rows. Build the primary mass first. Add terraces or arms only where they
improve the silhouette. Do not begin with surface noise.

The generator's `VoxelModel` is the sketchbook:

```python
model.box(-2, 0, -2, 4, 2, 4, shadow)
model.box(-1, 2, -1, 2, 3, 2, stone)
model.set(0, 5, 0, accent)
```

The coordinates are the design. The Blender mesh is a derived artifact.
Coordinates are logical `(x, y, z)` with `y` vertical; the exporter handles
Blender's Z-up convention.

## 3. Use palette roles

The project palette uses these roles:

| Role | Purpose |
| --- | --- |
| base | largest readable material mass |
| shadow | underside, foundation, deep crevice |
| light | exposed plane or secondary material |
| accent | sparse recognition cue |
| signal | emissive or high-contrast gameplay state |

Do not assign a unique material to every cell. Large contiguous color regions
make voxel forms legible; small accents should be deliberate landmarks.

## 4. Validate before export

The framework rejects:

- empty models;
- non-integer coordinates;
- unpainted cells;
- disconnected voxel islands;
- palettes larger than six materials.

An external grid check should also inspect exported GLB vertices. Exported
geometry is allowed to be a surface mesh, but every vertex must remain on the
declared lattice.

## 5. Preview like the game

Every generator run should produce:

- replaceable GLBs for Godot;
- a consistent orthographic preview;
- a grid-validation result;
- a short list of generated asset names.

The preview is not a beauty render. It is a design test for silhouette,
relative scale, palette separation, and camera readability.

## 6. Iteration order

When an asset is weak, fix it in this order:

1. footprint and silhouette;
2. proportion and stepped structure;
3. palette/value separation;
4. contact with ground and shadow;
5. secondary landmarks;
6. micro-detail and polish.

Never add detail before fixing the first failing item.

## 7. Planned evolution

The current framework intentionally uses a simple exposed-face mesher. The
next safe improvements are:

- greedy meshing for fewer coplanar faces without changing the voxel surface;
- face-orientation material rules for controlled top/side shading;
- reusable integer motifs for strata, foliage, stairs, and crystals;
- asset metadata emitted beside each GLB;
- generated thumbnail/contact-sheet review.

Do not switch to marching cubes or smooth procedural surfaces for this art
style. Those produce a different, non-block voxel language.

## Current hero and anchor contracts

The main hero is intentionally tall, with a long body, readable face band, and
wide hat brim. This gives the player a strong silhouette at bird-view scale.
Do not shrink the hero into a generic cube character without a design review.

Crags used as loop anchors are intentionally monumental: their voxel height
should read as mountain-scale and make the loop's commitment legible before
any topology rules are explained. Their base must remain connected to the
ground and their terraces must read as one geological mass.
