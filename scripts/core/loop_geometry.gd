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
	var center := _loop_center(current)
	for iteration in range(iterations):
		var candidate: Array[Vector3] = []
		for i in range(current.size()):
			if i == 0 or i == current.size() - 1:
				candidate.append(player_position)
				continue
			candidate.append(_push_out_of_obstacles(current[i].lerp(center, step), state, cell_to_world, clearance))
		if segments_clear(candidate, state, cell_to_world, clearance):
			current = candidate
			center = _loop_center(current)
		else:
			# A straight radial move can cross a puncture even when the
			# existing representative is legal. Keep that point in place
			# and continue relaxing the other points; this is not a
			# topological obstruction or a proof that the word is invalid.
			var partial := current.duplicate()
			var changed := false
			for i in range(1, current.size() - 1):
				var local_candidate := current.duplicate()
				local_candidate[i] = _push_out_of_obstacles(current[i].lerp(center, step), state, cell_to_world, clearance)
				if segments_clear(local_candidate, state, cell_to_world, clearance):
					partial = local_candidate
					changed = true
			if not changed:
				break
			current = partial
			center = _loop_center(current)
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
