# Current asset design notes

This pass treats the previous generated meshes as blockout references only.
The assets now follow the design-principle document as authored voxel models.

## Crag / mountain

The crag is a geological anchor for an intentionally committed loop. Its
primary form is a wide foothill-to-summit mass. Its secondary forms are
buttresses, offset terraces, a split summit ridge, and a saddle. Dark fissure
regions and sparse exposed strata provide focal detail without covering every
surface in noise.

Breakable and unbreakable crags share the same construction language. The
unbreakable variant has an embedded luminous seam, so the gameplay distinction
is structural and material rather than a floating symbol.

## Hero

The player is a tall field cartographer. The broad hat is the recognition
silhouette, the long coat establishes scale, the dark opening and visor create
the face focal area, and the asymmetric side tool gives the character a reason
to carry an offset attachment. Boots, belt/opening, shoulder satchel, and
beacon are clustered secondary details rather than random surface cubes.

## Review outcome

- Primary masses are readable from the gameplay preview.
- Secondary masses explain construction and scale.
- Detail is clustered around the summit seam, fissures, and hero face/gear.
- All geometry remains integer-cell authored at the `0.125 m` render lattice.
- Connectivity validation remains enabled; decorative geometry must attach to
  the supporting mass.

The next visual review should focus on the in-Godot orthographic camera and
whether the mountain silhouette is too dominant for the playable map, not on
preserving any of the old mesh topology.
