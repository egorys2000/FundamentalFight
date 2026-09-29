# Voxel asset framework

`generate_voxel_assets.py` is intentionally cell-based rather than primitive-based.

- `VOXEL_SIZE` defines the world size of one cubic cell (`0.125 m`).
- `VoxelModel.cells` stores occupied cells as integer `(x, y, z)` coordinates.
- Logical `y` is height/up. The mesher converts this to Blender's Z-up
  coordinate system before export.
- Current assets are authored at `0.25 m` design cells and expanded into
  `2 x 2 x 2` render voxels, giving more silhouette resolution without
  changing their gameplay/world scale.
- `VoxelModel.box(...)` fills an integer-aligned rectangular region.
- The surface mesher emits only faces whose neighboring cell is empty.
- Asset details must be added as occupied cells; do not add arbitrary Blender
  primitives, rotations, bevel modifiers, or non-grid dimensions.

This keeps the asset geometry on one regular lattice, which is the defining
constraint of voxel art. Materials can vary per cell, but the cell dimensions
and coordinates must remain integer-authored.

Generate and preview the kit with:

```text
blender -b --python tools/blender/generate_voxel_assets.py
```
