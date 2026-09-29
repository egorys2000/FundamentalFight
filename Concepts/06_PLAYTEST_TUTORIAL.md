# Playtest Tutorial

This is the current hands-on guide for the prototype. It is intentionally kept
outside the game HUD so the play space stays quiet and readable.

## Read the board

- The tiled surface is the playable ground.
- Gold marks the player.
- Pale stone crags are breakable anchors.
- Violet crags are unbreakable anchors.
- Green forms are cacti and remain obstacles.
- Teal pools are shallow water cells. They are visual terrain for now and do
  not block movement.
- The glass frame and lights mark the boundary of the miniature world; they
  are presentation, not gameplay geometry.

## Controls

| Input | Action |
| --- | --- |
| `WASD` or arrow keys | Move one grid cell |
| Left-drag | Draw a loop across the ground |
| `P` | Tighten the current loop |
| `X` | Remove the current loop |
| `R` | Return the player to the origin |

## Suggested first experiment

1. Move around the outside of the crags.
2. Left-drag a closed path around the two pale crags.
3. Press `P` and watch the loop tighten.
4. Remove it with `X`, then draw a different path around a violet crag.
5. Compare the visual result without relying on a HUD rule explanation.

## Current prototype limits

The loop is currently a visual/topological interaction prototype. It does not
yet simulate rope physics, damage, enemy AI, or water movement. The tutorial
will be updated as each mechanic becomes playable.
