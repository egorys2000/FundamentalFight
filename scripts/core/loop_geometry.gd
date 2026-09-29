class_name LoopGeometry
extends RefCounted

static func simplify_path(points: Array[Vector3], minimum_spacing: float) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for point in points:
		if result.is_empty() or point.distance_to(result.back()) >= minimum_spacing:
			result.append(point)
	if result.size() >= 2:
		result[0] = points[0]
		result[result.size() - 1] = points[points.size() - 1]
	return result

static func point_inside_loop(point: Vector3, loop: Array) -> bool:
	var inside := false
	for i in range(loop.size() - 1):
		var a: Vector3 = loop[i]
		var b: Vector3 = loop[i + 1]
		if (a.z > point.z) != (b.z > point.z):
			var x_at_point := (b.x - a.x) * (point.z - a.z) / (b.z - a.z) + a.x
			if point.x < x_at_point:
				inside = not inside
	return inside

static func enclosed_crags(loop: Array, state: WorldState, cell_to_world: Callable) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in state.occupied:
		if state.is_crag(cell) and point_inside_loop(cell_to_world.call(cell), loop):
			result.append(cell)
	return result

static func encloses_puncture(loop: Array, state: WorldState, cell_to_world: Callable) -> bool:
	for cell in state.occupied:
		if point_inside_loop(cell_to_world.call(cell), loop):
			return true
	return false

static func is_trivial(loop: Array, state: WorldState, cell_to_world: Callable) -> bool:
	return not encloses_puncture(loop, state, cell_to_world)

static func grid_route(start: Vector2i, target: Vector2i, state: WorldState, cell_to_world: Callable, grid_width: int, grid_height: int) -> Array[Vector3]:
	var x_limit := (grid_width - 1) / 2
	var z_limit := (grid_height - 1) / 2
	if abs(start.x) > x_limit or abs(start.y) > z_limit or abs(target.x) > x_limit:
		return []
	if abs(target.y) > z_limit or state.is_obstacle(target):
		return []
	var frontier: Array[Vector2i] = [start]
	var parent: Dictionary = {start: start}
	var directions := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if current == target:
			break
		for direction in directions:
			var next: Vector2i = current + direction
			if abs(next.x) > x_limit or abs(next.y) > z_limit:
				continue
			if state.is_obstacle(next) or parent.has(next):
				continue
			parent[next] = current
			frontier.append(next)
	if not parent.has(target):
		return []
	var cells: Array[Vector2i] = []
	var cursor := target
	while cursor != start:
		cells.push_front(cursor)
		cursor = parent[cursor]
	cells.push_front(start)
	var result: Array[Vector3] = []
	for cell in cells:
		result.append(cell_to_world.call(cell))
	return result

static func has_self_intersection(loop: Array) -> bool:
	if loop.size() < 5:
		return false
	for first in range(loop.size() - 1):
		for second in range(first + 2, loop.size() - 1):
			if first == 0 and second == loop.size() - 2:
				continue
			if loop[first].distance_squared_to(loop[second]) < 0.0001:
				return true
			if _segments_intersect(loop[first], loop[first + 1], loop[second], loop[second + 1]):
				return true
	return false

static func tightened_loop(start: Array, player_position: Vector3, state: WorldState, cell_to_world: Callable, clearance: float, iterations: int, step: float) -> Array:
	if start.size() < 4:
		return []
	if not segments_clear(start, state, cell_to_world, clearance):
		return []
	var current: Array[Vector3] = []
	for point in start:
		current.append(point)
	current[0] = player_position
	current[current.size() - 1] = player_position
	var current_perimeter := _perimeter(current)
	for iteration in range(iterations):
		var changed := false
		for i in range(1, current.size() - 1):
			var previous: Vector3 = current[i - 1]
			var next: Vector3 = current[i + 1]
			var midpoint := (previous + next) * 0.5
			var proposed := _push_out_of_obstacles(current[i].lerp(midpoint, step), state, cell_to_world, clearance)
			var local_candidate := current.duplicate()
			local_candidate[i] = proposed
			if not segments_clear(local_candidate, state, cell_to_world, clearance):
				continue
			var proposed_perimeter := _perimeter(local_candidate)
			if proposed_perimeter < current_perimeter - 0.0001:
				current = local_candidate
				current_perimeter = proposed_perimeter
				changed = true
		if not changed:
			break
	# A legal representative is already a valid tightened result when no
	# inward relaxation can be made without changing its obstacle routing.
	return current

static func segments_clear(points: Array, state: WorldState, cell_to_world: Callable, clearance: float) -> bool:
	if points.size() < 2:
		return false
	for i in range(points.size() - 1):
		for cell in state.occupied:
			if segment_hits_obstacle(points[i], points[i + 1], cell_to_world.call(cell), clearance):
				return false
	return true

static func touches_cactus(points: Array, state: WorldState, cell_to_world: Callable, clearance: float) -> bool:
	for cell in state.occupied:
		if not state.is_cactus(cell):
			continue
		for i in range(points.size() - 1):
			if segment_hits_obstacle(points[i], points[i + 1], cell_to_world.call(cell), clearance):
				return true
	return false

static func segment_hits_obstacle(start: Vector3, end: Vector3, obstacle: Vector3, clearance: float) -> bool:
	var segment := Vector2(end.x - start.x, end.z - start.z)
	var length_squared := segment.length_squared()
	var projection := 0.0
	if length_squared > 0.0001:
		projection = clampf(Vector2(obstacle.x - start.x, obstacle.z - start.z).dot(segment) / length_squared, 0.0, 1.0)
	var nearest := Vector2(start.x, start.z) + segment * projection
	return nearest.distance_to(Vector2(obstacle.x, obstacle.z)) < clearance

static func _loop_center(points: Array) -> Vector3:
	var center := Vector3.ZERO
	var count := maxi(points.size() - 1, 1)
	for i in range(count):
		center += points[i]
	return center / count

static func _perimeter(points: Array) -> float:
	var result := 0.0
	for i in range(points.size() - 1):
		result += points[i].distance_to(points[i + 1])
	return result

static func _push_out_of_obstacles(point: Vector3, state: WorldState, cell_to_world: Callable, clearance: float) -> Vector3:
	var result := point
	for cell in state.occupied:
		var obstacle: Vector3 = cell_to_world.call(cell)
		var offset := Vector2(result.x - obstacle.x, result.z - obstacle.z)
		if offset.length() < clearance:
			var direction := offset.normalized()
			if direction.length_squared() < 0.01:
				direction = Vector2.RIGHT
			result.x = obstacle.x + direction.x * clearance
			result.z = obstacle.z + direction.y * clearance
	return result

static func _segments_intersect(first_start: Vector3, first_end: Vector3, second_start: Vector3, second_end: Vector3) -> bool:
	var a := Vector2(first_start.x, first_start.z)
	var b := Vector2(first_end.x, first_end.z)
	var c := Vector2(second_start.x, second_start.z)
	var d := Vector2(second_end.x, second_end.z)
	var first_turn := _orientation(a, b, c)
	var second_turn := _orientation(a, b, d)
	var third_turn := _orientation(c, d, a)
	var fourth_turn := _orientation(c, d, b)
	return first_turn != second_turn and third_turn != fourth_turn

static func _orientation(a: Vector2, b: Vector2, c: Vector2) -> int:
	var cross := (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
	if absf(cross) < 0.0001:
		return 0
	return 1 if cross > 0.0 else -1
