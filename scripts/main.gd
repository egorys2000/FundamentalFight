extends Node3D

const GRID_SIZE := 11
const CELL_SIZE := 1.6
const GROUND_Y := -0.42
const LOOP_HEIGHT := 0.16
const LOOP_WIDTH := 0.09

const GROUND_TILE := preload("res://assets/generated/ground_tile.glb")
const GROUND_TILE_GRASS := preload("res://assets/generated/ground_tile_grass.glb")
const CRAG_BREAKABLE := preload("res://assets/generated/crag_breakable.glb")
const CRAG_UNBREAKABLE := preload("res://assets/generated/crag_unbreakable.glb")
const CACTUS := preload("res://assets/generated/cactus.glb")
const PLAYER_ASSET := preload("res://assets/generated/player_placeholder.glb")

var player_cell := Vector2i(0, 0)
var player: Node3D
var camera: Camera3D
var status_label: Label
var loop_visual: Node3D
var loop_material: StandardMaterial3D
var loop_points: Array[Vector3] = []
var loop_caught_cells: Array[Vector2i] = []
var loop_pulled := false
var drawing_loop := false
var draw_points: Array[Vector3] = []
var occupied := {
	Vector2i(-3, -2): "crag_breakable",
	Vector2i(-1, 2): "crag_unbreakable",
	Vector2i(2, -2): "crag_breakable",
	Vector2i(3, 2): "crag_unbreakable",
	Vector2i(-4, 2): "crag_breakable",
	Vector2i(2, 3): "cactus"
}

func _ready() -> void:
	_build_environment()
	_build_obstacles()
	_build_player()
	loop_visual = Node3D.new()
	loop_visual.name = "PersistentLoop"
	add_child(loop_visual)
	loop_material = StandardMaterial3D.new()
	loop_material.albedo_color = Color("#f0d47a")
	loop_material.emission_enabled = true
	loop_material.emission = Color("#a66b26")
	loop_material.emission_energy_multiplier = 0.55
	_build_ui()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#071016")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#7896a0")
	environment.ambient_light_energy = 0.16
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = false
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 0.82
	environment.adjustment_contrast = 1.12
	environment.adjustment_saturation = 0.9
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.light_color = Color("#e9c995")
	sun.light_energy = 0.72
	sun.directional_shadow_max_distance = 40.0
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 8.0, 2.0)
	fill.omni_range = 30.0
	fill.light_energy = 0.42
	fill.light_color = Color("#83b3c5")
	add_child(fill)
	var warm_rim := OmniLight3D.new()
	warm_rim.position = Vector3(-7.0, 4.0, -6.0)
	warm_rim.omni_range = 18.0
	warm_rim.light_energy = 0.65
	warm_rim.light_color = Color("#bd654d")
	add_child(warm_rim)

	var limit := (GRID_SIZE - 1) / 2
	for x in range(-limit, limit + 1):
		for z in range(-limit, limit + 1):
			var tile_scene: PackedScene = GROUND_TILE_GRASS if (x + z) % 3 == 0 else GROUND_TILE
			var tile := tile_scene.instantiate() as Node3D
			tile.position = _cell_to_world(Vector2i(x, z)) + Vector3(0.0, GROUND_Y, 0.0)
			tile.scale = Vector3.ONE * CELL_SIZE / 2.0
			add_child(tile)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 14.2
	camera.near = 0.01
	camera.far = 100.0
	camera.position = Vector3(0.0, 18.5, 16.5)
	add_child(camera)
	camera.rotation_degrees = Vector3(-48.0, 0.0, 0.0)
	camera.current = true

func _build_obstacles() -> void:
	for cell in occupied:
		var kind: String = occupied[cell]
		var asset: PackedScene = CRAG_BREAKABLE
		if kind == "crag_unbreakable":
			asset = CRAG_UNBREAKABLE
		elif kind == "cactus":
			asset = CACTUS
		var root := asset.instantiate() as Node3D
		root.position = _cell_to_world(cell)
		root.position.y = GROUND_Y
		add_child(root)

func _build_player() -> void:
	player = PLAYER_ASSET.instantiate() as Node3D
	player.name = "Player"
	player.position = _cell_to_world(player_cell) + Vector3(0.0, GROUND_Y, 0.0)
	add_child(player)

func _build_ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top_bar := _panel(Vector2(24, 20), Vector2(520, 104), Color("#0b1820e8"), Color("#28424a"))
	canvas.add_child(top_bar)
	var eyebrow := _label("FIELD STUDY  /  01", 12, Color("#69b8b2"))
	eyebrow.position = Vector2(20, 14)
	top_bar.add_child(eyebrow)
	var title := _label("FUNDAMENTAL FIGHT", 25, Color("#f0c879"))
	title.position = Vector2(18, 32)
	top_bar.add_child(title)
	var subtitle := _label("TOPOLOGICAL LASSO SANDBOX", 12, Color("#9bb3b4"))
	subtitle.position = Vector2(20, 73)
	top_bar.add_child(subtitle)

	var objective := _panel(Vector2(24, 138), Vector2(222, 68), Color("#10232ae8"), Color("#28505a"))
	canvas.add_child(objective)
	var objective_title := _label("CURRENT OBJECTIVE", 11, Color("#69b8b2"))
	objective_title.position = Vector2(16, 10)
	objective.add_child(objective_title)
	var objective_text := _label("Explore the empty map", 15, Color("#e3e9d8"))
	objective_text.position = Vector2(16, 32)
	objective.add_child(objective_text)

	var telemetry := _panel(Vector2(270, 138), Vector2(364, 68), Color("#0b1820e8"), Color("#28424a"))
	canvas.add_child(telemetry)
	status_label = Label.new()
	status_label.position = Vector2(16, 18)
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("#d8e2d5"))
	telemetry.add_child(status_label)

	var controls := _panel(Vector2(24, 664), Vector2(650, 54), Color("#0b1820e8"), Color("#28424a"))
	controls.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(24, -78)
	canvas.add_child(controls)
	var help := Label.new()
	help.position = Vector2(18, 17)
	help.text = "WASD / ARROWS  MOVE     LEFT-DRAG  DRAW LOOP     P  TIGHTEN     X  REMOVE     R  RESET"
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color("#a8c2c0"))
	controls.add_child(help)
	_update_status()

func _panel(position: Vector2, size: Vector2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = position
	panel.size = size
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				_begin_loop_drawing(mouse_button.position)
			else:
				_finish_loop_drawing()
			return
	if event is InputEventMouseMotion and drawing_loop:
		var mouse_motion := event as InputEventMouseMotion
		_append_draw_point(mouse_motion.position)
		return
	if not event.is_pressed() or event.is_echo():
		return
	var key_event := event as InputEventKey
	if key_event != null and key_event.keycode == KEY_R:
		_move_player(Vector2i.ZERO)
		return
	if key_event != null and key_event.keycode == KEY_P:
		_pull_loop()
		return
	if key_event != null and key_event.keycode == KEY_X:
		_remove_loop()
		return
	var direction := Vector2i.ZERO
	if event.is_action_pressed("ui_up") or (key_event != null and key_event.keycode == KEY_W):
		direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down") or (key_event != null and key_event.keycode == KEY_S):
		direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left") or (key_event != null and key_event.keycode == KEY_A):
		direction = Vector2i(-1, 0)
	elif event.is_action_pressed("ui_right") or (key_event != null and key_event.keycode == KEY_D):
		direction = Vector2i(1, 0)
	if direction != Vector2i.ZERO:
		_move_player(player_cell + direction)

func _move_player(target: Vector2i) -> void:
	var limit := (GRID_SIZE - 1) / 2
	if abs(target.x) > limit or abs(target.y) > limit:
		return
	if occupied.has(target):
		status_label.text = "Blocked: %s at (%d, %d)" % [occupied[target].capitalize(), target.x, target.y]
		return
	player_cell = target
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(player, "position", _cell_to_world(player_cell) + Vector3(0.0, GROUND_Y, 0.0), 0.16)
	_update_status()

func _update_status() -> void:
	if status_label:
		var loop_state := "none"
		if not loop_points.is_empty():
			loop_state = "tight" if loop_pulled else "placed"
		status_label.text = "CELL  %02d, %02d     CRAGS  5     CACTUS  1\nLOOP  %s" % [player_cell.x, player_cell.y, loop_state.to_upper()]

func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)

func _begin_loop_drawing(screen_position: Vector2) -> void:
	var world_position := _screen_to_ground(screen_position)
	var player_position := _cell_to_world(player_cell) + Vector3(0.0, LOOP_HEIGHT, 0.0)
	if world_position == Vector3.INF or world_position.distance_to(player_position) > CELL_SIZE * 1.25:
		status_label.text = "Start the loop by dragging from the player"
		return
	drawing_loop = true
	draw_points = [player_position]
	loop_points = draw_points.duplicate()
	loop_pulled = false
	_redraw_loop()

func _append_draw_point(screen_position: Vector2) -> void:
	var world_position := _screen_to_ground(screen_position)
	if world_position == Vector3.INF or draw_points.is_empty():
		return
	world_position.y = LOOP_HEIGHT
	if world_position.distance_to(draw_points.back()) < CELL_SIZE * 0.08:
		return
	draw_points.append(world_position)
	loop_points = draw_points.duplicate()
	_redraw_loop()

func _finish_loop_drawing() -> void:
	if not drawing_loop:
		return
	drawing_loop = false
	if draw_points.size() < 4:
		draw_points.clear()
		loop_points.clear()
		_redraw_loop()
		_update_status()
		return
	var player_position := _cell_to_world(player_cell) + Vector3(0.0, LOOP_HEIGHT, 0.0)
	draw_points.append(player_position)
	loop_points = draw_points.duplicate()
	draw_points.clear()
	loop_caught_cells = _cells_inside_loop()
	loop_pulled = false
	_redraw_loop()
	_update_status()

func _screen_to_ground(screen_position: Vector2) -> Vector3:
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	if abs(ray_direction.y) < 0.0001:
		return Vector3.INF
	var distance := (LOOP_HEIGHT - ray_origin.y) / ray_direction.y
	if distance < 0.0:
		return Vector3.INF
	return ray_origin + ray_direction * distance

func _cells_inside_loop() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in occupied:
		if occupied[cell].begins_with("crag") and _point_inside_loop(_cell_to_world(cell)):
			result.append(cell)
	return result

func _point_inside_loop(point: Vector3) -> bool:
	var inside := false
	for i in range(loop_points.size() - 1):
		var a: Vector3 = loop_points[i]
		var b: Vector3 = loop_points[i + 1]
		if (a.z > point.z) != (b.z > point.z):
			var x_at_point := (b.x - a.x) * (point.z - a.z) / (b.z - a.z) + a.x
			if point.x < x_at_point:
				inside = not inside
	return inside

func _pull_loop() -> void:
	if loop_points.is_empty():
		return
	loop_pulled = true
	var center := Vector3.ZERO
	for cell in loop_caught_cells:
		center += _cell_to_world(cell)
	if loop_caught_cells.is_empty():
		center = _cell_to_world(player_cell)
	else:
		center /= loop_caught_cells.size()
	var start: Array = loop_points.duplicate()
	var target: Array = []
	for point in start:
		var offset: Vector3 = point - center
		target.append(center + Vector3(offset.x * 0.72, LOOP_HEIGHT, offset.z * 0.72))
	var player_position := _cell_to_world(player_cell) + Vector3(0.0, LOOP_HEIGHT, 0.0)
	if not target.is_empty():
		target[0] = player_position
		target[target.size() - 1] = player_position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_tween_loop.bind(start, target), 0.0, 1.0, 0.65)
	_update_status()

func _tween_loop(progress: float, start: Array, target: Array) -> void:
	loop_points.clear()
	var point_count := mini(start.size(), target.size())
	for i in range(point_count):
		var start_point: Vector3 = start[i]
		var target_point: Vector3 = target[i]
		loop_points.append(start_point.lerp(target_point, progress))
	_redraw_loop()

func _remove_loop() -> void:
	loop_points.clear()
	loop_caught_cells.clear()
	loop_pulled = false
	_redraw_loop()
	_update_status()

func _redraw_loop() -> void:
	for child in loop_visual.get_children():
		child.queue_free()
	if loop_points.size() < 2:
		return
	for i in range(loop_points.size() - 1):
		var start: Vector3 = loop_points[i]
		var end: Vector3 = loop_points[i + 1]
		var segment_mesh := BoxMesh.new()
		segment_mesh.size = Vector3(LOOP_WIDTH, LOOP_WIDTH, start.distance_to(end))
		var segment := MeshInstance3D.new()
		segment.mesh = segment_mesh
		segment.material_override = loop_material
		segment.position = (start + end) * 0.5
		segment.look_at(end, Vector3.UP)
		loop_visual.add_child(segment)