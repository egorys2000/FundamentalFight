# Voxel design mechanics

This is the deeper design model behind the generator. Voxel quality is not
produced by increasing polygon count. It comes from making shape, value, and
rhythm survive quantization.

## 1. Resolution is information bandwidth

Moving from `0.25 m` to `0.125 m` only helps if the added cells describe new
information. Repeating every old cell as a `2 x 2 x 2` block increases file
size but does not improve the design. The framework now keeps world scale
constant while authoring mountain layers, ridges, ledges, and ravines on the
finer lattice.

Use resolution for:

- silhouette changes;
- plane breaks;
- narrow ledges and gaps;
- material boundaries;
- recognition features.

Do not spend it on random noise.

## 2. Shape is a hierarchy

Every asset should be readable at three distances:

### Thumbnail distance

Only the outer contour, largest value masses, and one recognition cue survive.
This is where a mountain must look like a mountain and the hero must look like
a hat-wearing traveler.

### Gameplay distance

Secondary terraces, arms, paths, faces, and gameplay markings become legible.
This is the authoritative view for Fundamental Fight.

### Inspection distance

Small chips, strata offsets, vegetation clusters, and emissive cells reward
close inspection. They are never allowed to contradict the larger form.

## 3. Voxel silhouettes use rhythm

A good contour is not a staircase with a constant step. It alternates cadence:
long run, short run, corner, pause, then another run. This creates geological
or designed rhythm while remaining grid-authored.

For mountains, use:

- broad foothills;
- a few major shelves;
- offset upper masses;
- a narrowing summit;
- asymmetry between the readable front and the shadow side.

Avoid the “wedding cake” failure mode: identical centered squares stacked
vertically.

## 4. Planes are designed, not shaded into existence

Voxel faces are flat planes. Lighting can separate them, but it cannot invent a
missing ledge or ridge. Use occupied-cell changes to create:

- top planes for readable light;
- front planes for material identity;
- side planes for depth;
- underside planes for weight and contact;
- recessed planes for shadow.

At least one plane transition should occur before a major color transition.
Otherwise the palette looks painted onto a primitive.

## 5. Palette follows material logic

Use a value ramp per material:

`deep -> base -> exposed -> signal`

The deep tone belongs in foundations and crevices, the base in the dominant
mass, the exposed tone on selected top/forward planes, and signal colors only
on landmarks or gameplay states. Hue shifts should support value shifts; a
random rainbow is not material variation.

## 6. Controlled irregularity

Natural voxel forms need variation, but random cell noise produces visual
static. Use deterministic influences instead:

- a ridge has a direction;
- a strata band has a thickness;
- a ravine has a path;
- a ledge has a support;
- a chip has a parent plane.

An irregular cell must answer “what larger feature does this belong to?”

## 7. Structural plausibility

Even stylized assets need a believable load path. A floating ledge should be
supported by a pillar or connected shelf. A mountain should widen toward its
base. A hat brim should attach to a head. The framework therefore validates
connectivity, while the artist remains responsible for mass and support.

## 8. Design for the camera

Orthographic bird-view compresses depth. Bias important recognition features
toward the camera-facing side, exaggerate vertical separation, and reserve
high-contrast accents for locations that remain visible through neighboring
forms. Review both a 64 px thumbnail and the in-game camera.

## 9. What “more detail” means here

The correct order is:

1. richer silhouette;
2. stronger primary/secondary mass relationship;
3. deliberate plane changes;
4. material stratification;
5. recognition landmarks;
6. sparse micro-detail.

If the first three are weak, adding more voxels only creates a higher
resolution bad model.
