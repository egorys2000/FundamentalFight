extends RefCounted

const MechanicsCoreClass = preload("res://scripts/core/mechanics_core.gd")
const WorldStateClass = preload("res://scripts/core/world_state.gd")

var core: MechanicsCore

func before_each() -> void:
	var map := WorldStateClass.new()
	map.occupied = {
		Vector2i(1, 0): WorldStateClass.BREAKABLE_CRAG
	}
	core = MechanicsCoreClass.new(map)

func test_move_to_open_cell_is_accepted() -> void:
	before_each()
	assert(core.try_move_to(Vector2i(2, 0)))
	assert(core.player_cell == Vector2i(2, 0))

func test_move_into_puncture_is_rejected_without_state_change() -> void:
	before_each()
	assert(not core.try_move_to(Vector2i(1, 0)))
	assert(core.player_cell == Vector2i.ZERO)

func test_move_outside_manifold_bounds_is_rejected() -> void:
	before_each()
	assert(not core.try_move_to(Vector2i(8, 0)))
	assert(core.player_cell == Vector2i.ZERO)

func test_movement_is_deterministic_after_repeated_requests() -> void:
	before_each()
	var requests := [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)]
	for request in requests:
		assert(core.try_move_to(request))
	assert(core.player_cell == Vector2i(2, 1))

func test_nontrivial_lasso_movement_is_faster_than_manual() -> void:
	before_each()
	assert(core.movement_duration(false) > core.movement_duration(true))

func test_loop_inventory_is_authoritative() -> void:
	before_each()
	var loop: Array[Vector3] = [Vector3.ZERO, Vector3(1, 0, 0), Vector3.ZERO]
	core.add_loop(loop)
	assert(core.has_loops())
	assert(core.latest_loop() == loop)
	assert(core.remove_latest_loop())
	assert(not core.has_loops())
	assert(not core.remove_latest_loop())
