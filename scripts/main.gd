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
	loop_material.emission_energy_multiplier = 1.4
	_build_ui()

func _build_environment() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#091217")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#9bc1c2")
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.glow_bloom = 0.12
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.light_color = Color("#ffe1ad")
	sun.light_energy = 2.2
	sun.directional_shadow_max_distance = 40.0
	sun.shadow_enabled = true
	add_child(sun)
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.0, 8.0, 2.0)
	fill.omni_range = 30.0
	fill.light_energy = 2.4
	fill.light_color = Color("#d6f0ff")
	add_child(fill)
	var warm_rim := OmniLight3D.new()
	warm_rim.position = Vector3(-7.0, 4.0, -6.0)
	warm_rim.omni_range = 18.0
	warm_rim.light_energy = 3.0
	warm_rim.light_color = Color("#e88958")
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
	camera.size = 15.8
	camera.near = 0.01
	camera.far = 100.0
	camera.position = Vector3(0.0, 18.0, 18.0)
	add_child(camera)
	camera.rotation_degrees = Vector3(-45.0, 0.0, 0.0)
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
	var title := Label.new()
	title.position = Vector2(28, 22)
	title.text = "FUNDAMENTAL FIGHT  /  TOPOLOGICAL LASSO SANDBOX"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#f5d69a"))
	canvas.add_child(title)
	status_label = Label.new()
	status_label.position = Vector2(30, 60)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color("#b9d4d2"))
	canvas.add_child(status_label)
	var help := Label.new()
	help.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(30, -58)
	help.text = "ARROWS / WASD Move     L Place loop     P Pull/tighten     X Remove loop     R Reset"
	help.add_theme_font_size_override("font_size", 16)
	help.add_theme_color_override("font_color", Color("#b9d4d2"))
	canvas.add_child(help)
	_update_status()

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	var key_event := event as InputEventKey
	if key_event != null and key_event.keycode == KEY_R:
		_move_player(Vector2i.ZERO)
		return
	if key_event != null and key_event.keycode == KEY_L:
		_place_loop()
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
		status_label.text = "Player cell: (%d, %d)     Crags: 5     Cactus: 1     Loop: %s" % [player_cell.x, player_cell.y, loop_state]

func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)

func _place_loop() -> void:
	loop_pulled = false
	loop_caught_cells = [Vector2i(-3, -2), Vector2i(2, -2)]
	var left := _cell_to_world(loop_caught_cells[0])
	var right := _cell_to_world(loop_caught_cells[1])
	var padding := CELL_SIZE * 0.72
	var min_x := left.x - padding
	var max_x := right.x + padding
	var min_z := min(left.z, right.z) - padding
	var max_z := max(left.z, right.z) + padding
	loop_points = [
		Vector3(min_x, LOOP_HEIGHT, min_z),
		Vector3(max_x, LOOP_HEIGHT, min_z),
		Vector3(max_x, LOOP_HEIGHT, max_z),
		Vector3(min_x, LOOP_HEIGHT, max_z),
		Vector3(min_x, LOOP_HEIGHT, min_z)
	]
	_redraw_loop()
	_update_status()

func _pull_loop() -> void:
	if loop_points.is_empty():
		return
	loop_pulled = true
	var center := Vector3.ZERO
	for cell in loop_caught_cells:
		center += _cell_to_world(cell)
	center /= loop_caught_cells.size()
	var span := CELL_SIZE * 2.5
	var target := [
		center + Vector3(-span, LOOP_HEIGHT, -CELL_SIZE * 1.1),
		center + Vector3(span, LOOP_HEIGHT, -CELL_SIZE * 1.1),
		center + Vector3(span, LOOP_HEIGHT, CELL_SIZE * 1.1),
		center + Vector3(-span, LOOP_HEIGHT, CELL_SIZE * 1.1),
		center + Vector3(-span, LOOP_HEIGHT, -CELL_SIZE * 1.1)
	]
	var start := loop_points.duplicate()
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_tween_loop.bind(start, target), 0.0, 1.0, 0.65)
	_update_status()

func _tween_loop(progress: float, start: Array, target: Array) -> void:
	loop_points.clear()
	for i in range(start.size()):
		loop_points.append(start[i].lerp(target[i], progress))
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
