extends RefCounted

const LoopGeometryClass = preload("res://scripts/core/loop_geometry.gd")
const WorldStateClass = preload("res://scripts/core/world_state.gd")

const CELL_SIZE := 1.0
const CLEARANCE := 0.35
const ITERATIONS := 18
const STEP := 0.12

var state: WorldState

func before_each() -> void:
	state = WorldStateClass.new()
	state.occupied = {
		Vector2i(-1, 0): WorldStateClass.BREAKABLE_CRAG,
		Vector2i(1, 0): WorldStateClass.BREAKABLE_CRAG
	}

func test_nontrivial_word_cases() -> void:
	var cases := {
		"a": ["a"],
		"a^2": ["a", "a"],
		"ab": ["a", "b"],
		"aba^-1": ["a", "b", "A"],
		"aba^-1b^-1": ["a", "b", "A", "B"],
		"a^2ba^-2": ["a", "a", "b", "A", "A"]
	}
	for name in cases:
		var reduced: Array = _reduce(cases[name])
		assert(not reduced.is_empty(), "%s must remain nontrivial" % name)

func test_inverse_pairs_reduce_to_identity() -> void:
	assert(_reduce(["a", "A"]).is_empty())
	assert(_reduce(["a", "a", "b", "A", "A", "B"]).is_empty())

func test_tightening_preserves_player_anchor_and_clearance() -> void:
	before_each()
	var player := Vector3(0.0, 0.16, -3.0)
	var start := _test_loop(player)
	var target: Array = LoopGeometryClass.tightened_loop(
		start,
		player,
		state,
		Callable(self, "_cell_to_world"),
		CLEARANCE,
		ITERATIONS,
		STEP
	)
	assert(not target.is_empty())
	assert(target[0] == player)
	assert(target[target.size() - 1] == player)
	assert(LoopGeometryClass.segments_clear(target, state, Callable(self, "_cell_to_world"), CLEARANCE))

func test_tightening_does_not_increase_perimeter() -> void:
	before_each()
	var player := Vector3(0.0, 0.16, -3.0)
	var start := _test_loop(player)
	var target: Array = LoopGeometryClass.tightened_loop(
		start,
		player,
		state,
		Callable(self, "_cell_to_world"),
		CLEARANCE,
		ITERATIONS,
		STEP
	)
	assert(not target.is_empty())
	assert(_perimeter(target) <= _perimeter(start) + 0.001)

func test_tightening_actually_shortens_a_loose_nontrivial_loop() -> void:
	before_each()
	var player := Vector3(0.0, 0.16, -3.0)
	var start := _test_loop(player)
	var target: Array = LoopGeometryClass.tightened_loop(
		start,
		player,
		state,
		Callable(self, "_cell_to_world"),
		CLEARANCE,
		72,
		0.2
	)
	assert(not target.is_empty())
	assert(_perimeter(target) < _perimeter(start) - 0.01)

func test_every_animation_frame_stays_outside_holes() -> void:
	before_each()
	var player := Vector3(0.0, 0.16, -3.0)
	var start := _test_loop(player)
	var target: Array = LoopGeometryClass.tightened_loop(
		start,
		player,
		state,
		Callable(self, "_cell_to_world"),
		CLEARANCE,
		ITERATIONS,
		STEP
	)
	assert(not target.is_empty())
	for frame in range(21):
		var progress := float(frame) / 20.0
		var intermediate: Array[Vector3] = []
		for i in range(start.size()):
			intermediate.append(start[i].lerp(target[i], progress))
		assert(intermediate[0] == player)
		assert(intermediate[intermediate.size() - 1] == player)
		assert(LoopGeometryClass.segments_clear(
			intermediate,
			state,
			Callable(self, "_cell_to_world"),
			CLEARANCE
		))

func _test_loop(player: Vector3) -> Array[Vector3]:
	return [
		player,
		Vector3(-3.0, 0.16, -3.0),
		Vector3(-3.0, 0.16, 3.0),
		Vector3(3.0, 0.16, 3.0),
		Vector3(3.0, 0.16, -3.0),
		player
	]

func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)

func _perimeter(points: Array) -> float:
	var result := 0.0
	for i in range(points.size() - 1):
		result += points[i].distance_to(points[i + 1])
	return result

func _reduce(word: Array) -> Array:
	var stack: Array = []
	for letter in word:
		if not stack.is_empty() and _inverse(stack.back(), letter):
			stack.pop_back()
		else:
			stack.append(letter)
	return stack

func _inverse(left: String, right: String) -> bool:
	return (
		(left == "a" and right == "A")
		or (left == "A" and right == "a")
		or (left == "b" and right == "B")
		or (left == "B" and right == "b")
	)
