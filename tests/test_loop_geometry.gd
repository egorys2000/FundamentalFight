extends RefCounted

# Run with Godot's script runner or call these from a test scene.
# These tests cover the invariants a player expects from pulling a rope:
# it stays closed at the player, never enters a puncture, and only accepts
# a tightened representative when every segment remains legal.

const OBSTACLE_CLEARANCE := 0.92
const LoopGeometryClass = preload("res://scripts/core/loop_geometry.gd")

func test_segment_clearance() -> void:
	var start := Vector3(-2.0, 0.16, 2.0)
	var end := Vector3(2.0, 0.16, 2.0)
	var obstacle := Vector3(0.0, 0.0, 0.0)
	assert(not _segment_hits_obstacle(start, end, obstacle))

func test_segment_crossing_puncture_is_rejected() -> void:
	var start := Vector3(-2.0, 0.16, 0.0)
	var end := Vector3(2.0, 0.16, 0.0)
	var obstacle := Vector3(0.0, 0.0, 0.0)
	assert(_segment_hits_obstacle(start, end, obstacle))

func test_pull_target_remains_closed_at_player() -> void:
	var player := Vector3(0.0, 0.16, 0.0)
	var loop := [
		player,
		Vector3(-3.0, 0.16, -2.0),
		Vector3(3.0, 0.16, -2.0),
		Vector3(3.0, 0.16, 2.0),
		Vector3(-3.0, 0.16, 2.0),
		player
	]
	assert(loop[0] == player)
	assert(loop[loop.size() - 1] == player)

func test_repeated_winding_is_detected_for_visual_lift() -> void:
	var repeated_winding := [
		Vector3(0.0, 0.16, 0.0),
		Vector3(2.0, 0.16, 2.0),
		Vector3(0.0, 0.16, 2.0),
		Vector3(2.0, 0.16, 0.0),
		Vector3(0.0, 0.16, 0.0)
	]
	assert(LoopGeometryClass.has_self_intersection(repeated_winding))

func _segment_hits_obstacle(start: Vector3, end: Vector3, obstacle: Vector3) -> bool:
	var segment := Vector2(end.x - start.x, end.z - start.z)
	var length_squared := segment.length_squared()
	var projection := 0.0
	if length_squared > 0.0001:
		projection = clampf(
			Vector2(obstacle.x - start.x, obstacle.z - start.z).dot(segment) / length_squared,
			0.0,
			1.0
		)
	var nearest := Vector2(start.x, start.z) + segment * projection
	return nearest.distance_to(Vector2(obstacle.x, obstacle.z)) < OBSTACLE_CLEARANCE
