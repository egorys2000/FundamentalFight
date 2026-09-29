class_name MechanicsCore
extends RefCounted

const DEFAULT_GRID_SIZE := 15
const MANUAL_MOVE_DURATION := 0.16
const LASSO_MOVE_DURATION := 0.055

var world_state: WorldState
var player_cell := Vector2i.ZERO
var loops: Array[Array] = []

func _init(map_state: WorldState = null, grid_size: int = DEFAULT_GRID_SIZE) -> void:
	world_state = map_state if map_state != null else WorldState.new()

func can_move_to(target: Vector2i, grid_size: int = DEFAULT_GRID_SIZE) -> bool:
	var limit := (grid_size - 1) / 2
	if abs(target.x) > limit or abs(target.y) > limit:
		return false
	return not world_state.is_obstacle(target)

func try_move_to(target: Vector2i, grid_size: int = DEFAULT_GRID_SIZE) -> bool:
	return try_move_to_rect(target, grid_size, grid_size)

func try_move_to_rect(target: Vector2i, width: int, height: int) -> bool:
	if abs(target.x) > (width - 1) / 2 or abs(target.y) > (height - 1) / 2:
		return false
	if world_state.is_obstacle(target):
		return false
	player_cell = target
	world_state.player_cell = target
	return true

func movement_duration(pulling_nontrivial: bool) -> float:
	return LASSO_MOVE_DURATION if pulling_nontrivial else MANUAL_MOVE_DURATION

func add_loop(points: Array[Vector3]) -> void:
	loops.append(points.duplicate())

func latest_loop() -> Array:
	if loops.is_empty():
		return []
	return loops.back().duplicate()

func remove_latest_loop() -> bool:
	if loops.is_empty():
		return false
	loops.pop_back()
	return true

func is_trivial_loop(points: Array, cell_to_world: Callable) -> bool:
	return LoopGeometry.is_trivial(points, world_state, cell_to_world)

func tightened_latest_loop(player_position: Vector3, cell_to_world: Callable, clearance: float, iterations: int, step: float) -> Array:
	var current := latest_loop()
	if current.is_empty():
		return []
	if is_trivial_loop(current, cell_to_world):
		var collapsed: Array[Vector3] = []
		for _point in current:
			collapsed.append(player_position)
		return collapsed
	return LoopGeometry.tightened_loop(current, player_position, world_state, cell_to_world, clearance, iterations, step)

func has_loops() -> bool:
	return not loops.is_empty()
