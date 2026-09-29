extends Node3D

@export_category("Core Mechanics")
@export var enable_manual_movement := true
@export var enable_lasso_drawing := true
@export var enable_grid_snap := true
@export var enable_loop_persistence := true
@export var enable_obstacle_clearance := true
@export var enable_pull_tightening := true
@export var enable_string_recovery := true
@export var enable_cactus_cutting := true
@export_range(1, 8, 1) var max_strings_per_player := 3

const GRID_SIZE := 15
const CELL_SIZE := 2.35
const GROUND_Y := -0.42
const LOOP_HEIGHT := 0.16
const LOOP_WIDTH := 0.09
const OBSTACLE_CLEARANCE := 0.92
const GRID_SNAP_DISTANCE := 0.42
const WATER_Y := 0.22
const CRAG_SCALE := Vector3(0.46, 1.25, 0.46)
const CACTUS_SCALE := Vector3.ONE * 0.72
const PULL_ITERATIONS := 18
const PULL_STEP := 0.12

const GROUND_TILE := preload("res://assets/generated/ground_tile.glb")
const GROUND_TILE_GRASS := preload("res://assets/generated/ground_tile_grass.glb")
const CRAG_BREAKABLE := preload("res://assets/generated/crag_breakable.glb")
const CRAG_UNBREAKABLE := preload("res://assets/generated/crag_unbreakable.glb")
const CACTUS := preload("res://assets/generated/cactus.glb")
const PLAYER_ASSET := preload("res://assets/generated/player_placeholder.glb")

var world_state := WorldState.new()
var player_cell := Vector2i.ZERO
var player: Node3D
var camera: Camera3D
var status_label: Label
var loop_visual: Node3D
var loop_material: StandardMaterial3D
var loop_points: Array[Vector3] = []
var loop_caught_cells: Array[Vector2i] = []
var loop_pulled := false
var scene_built := false
var drawing_loop := false
var draw_points: Array[Vector3] = []
var occupied: Dictionary:
	get:
		return world_state.occupied
var water_cells: Array:
	get:
		return world_state.water_cells

func _ready() -> void:
	if scene_built:
		return
	scene_built = true
	_build_environment()
	_build_water()
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
	environment.fog_enabled = true
	environment.fog_light_color = Color("#365d63")
	environment.fog_light_energy = 0.18
	environment.fog_density = 0.006
	environment.fog_height = 1.2
	environment.fog_height_density = 0.16
	environment.fog_sky_affect = 0.35
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
	var water_light := OmniLight3D.new()
	water_light.position = Vector3(-4.0, 2.4, 4.0)
	water_light.omni_range = 12.0
	water_light.light_energy = 1.15
	water_light.light_color = Color("#3bc5bd")
	add_child(water_light)
	var terrarium_light := OmniLight3D.new()
	terrarium_light.position = Vector3(5.0, 3.0, -5.0)
	terrarium_light.omni_range = 14.0
	terrarium_light.light_energy = 0.85
	terrarium_light.light_color = Color("#d18a58")
	add_child(terrarium_light)

	var foundation_material := StandardMaterial3D.new()
	foundation_material.albedo_color = Color("#182b2c")
	foundation_material.roughness = 0.92
	var foundation_mesh := BoxMesh.new()
	foundation_mesh.size = Vector3(GRID_SIZE * CELL_SIZE + 0.8, 0.3, GRID_SIZE * CELL_SIZE + 0.8)
	var foundation := MeshInstance3D.new()
	foundation.mesh = foundation_mesh
	foundation.material_override = foundation_material
	foundation.position.y = GROUND_Y - 0.28
	add_child(foundation)
	_build_terrarium_frame()

	var limit := (GRID_SIZE - 1) / 2
	for x in range(-limit, limit + 1):
		for z in range(-limit, limit + 1):
			var tile_scene: PackedScene = GROUND_TILE_GRASS if (x + z) % 3 == 0 else GROUND_TILE
			var tile := tile_scene.instantiate() as Node3D
			tile.position = _cell_to_world(Vector2i(x, z)) + Vector3(0.0, GROUND_Y, 0.0)
			tile.scale = Vector3.ONE * (CELL_SIZE / 2.0) * 0.91
			add_child(tile)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 29.5
	camera.near = 0.01
	camera.far = 100.0
	camera.position = Vector3(14.0, 22.0, -18.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true

func _build_terrarium_frame() -> void:
	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color("#10252b")
	frame_material.metallic = 0.35
	frame_material.roughness = 0.3
	var glass_material := StandardMaterial3D.new()
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = Color(0.18, 0.62, 0.65, 0.055)
	glass_material.metallic = 0.1
	glass_material.roughness = 0.08
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var extent := GRID_SIZE * CELL_SIZE * 0.5 + 0.35
	var wall_height := 3.8
	var walls := [
		{"position": Vector3(0.0, wall_height * 0.5, -extent), "size": Vector3(extent * 2.0, wall_height, 0.035)},
		{"position": Vector3(0.0, wall_height * 0.5, extent), "size": Vector3(extent * 2.0, wall_height, 0.035)},
		{"position": Vector3(-extent, wall_height * 0.5, 0.0), "size": Vector3(0.035, wall_height, extent * 2.0)},
		{"position": Vector3(extent, wall_height * 0.5, 0.0), "size": Vector3(0.035, wall_height, extent * 2.0)},
	]
	for wall in walls:
		var glass_mesh := BoxMesh.new()
		glass_mesh.size = wall["size"]
		var glass := MeshInstance3D.new()
		glass.mesh = glass_mesh
		glass.material_override = glass_material
		glass.position = wall["position"]
		add_child(glass)
	for corner in [
		Vector3(-extent, wall_height * 0.5, -extent),
		Vector3(extent, wall_height * 0.5, -extent),
		Vector3(-extent, wall_height * 0.5, extent),
		Vector3(extent, wall_height * 0.5, extent),
	]:
		var post_mesh := BoxMesh.new()
		post_mesh.size = Vector3(0.16, wall_height, 0.16)
		var post := MeshInstance3D.new()
		post.mesh = post_mesh
		post.material_override = frame_material
		post.position = corner
		add_child(post)
	var cap_mesh := BoxMesh.new()
	cap_mesh.size = Vector3(extent * 2.0 + 0.3, 0.12, 0.12)
	for z in [-extent, extent]:
		var cap := MeshInstance3D.new()
		cap.mesh = cap_mesh
		cap.material_override = frame_material
		cap.position = Vector3(0.0, wall_height, z)
		add_child(cap)

func _build_water() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec4 water_color : source_color = vec4(0.08, 0.52, 0.56, 0.78);
void vertex() {
	VERTEX.y += sin(TIME * 1.4 + VERTEX.x * 2.2 + VERTEX.z * 1.7) * 0.018;
}
void fragment() {
	float ripple = sin(TIME * 1.2 + UV.x * 18.0 + UV.y * 13.0) * 0.035;
	ALBEDO = water_color.rgb + ripple;
	METALLIC = 0.18;
	ROUGHNESS = 0.16;
	EMISSION = water_color.rgb * 0.12;
	ALPHA = water_color.a;
}
"""
	var water_material := ShaderMaterial.new()
	water_material.shader = shader
	for cell in water_cells:
		var water_mesh := BoxMesh.new()
		water_mesh.size = Vector3(CELL_SIZE * 0.88, 0.06, CELL_SIZE * 0.88)
		var water := MeshInstance3D.new()
		water.mesh = water_mesh
		water.material_override = water_material
		water.position = _cell_to_world(cell) + Vector3(0.0, WATER_Y, 0.0)
		add_child(water)

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
		root.scale = CRAG_SCALE if kind.begins_with("crag") else CACTUS_SCALE
		add_child(root)

func _build_player() -> void:
	player = PLAYER_ASSET.instantiate() as Node3D
	player.name = "Player"
	player.position = _cell_to_world(player_cell) + Vector3(0.0, GROUND_Y, 0.0)
	player.scale = Vector3.ONE * 0.76
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
				if enable_lasso_drawing:
					_begin_loop_drawing(mouse_button.position)
			else:
				if enable_lasso_drawing:
					_finish_loop_drawing()
			return
	if event is InputEventMouseMotion and drawing_loop:
		var mouse_motion := event as InputEventMouseMotion
		_append_draw_point(mouse_motion.position)
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.is_pressed() or key_event.is_echo():
		return
	if key_event != null and key_event.keycode == KEY_R:
		_move_player(Vector2i.ZERO)
		return
	if key_event != null and key_event.keycode == KEY_P:
		if enable_pull_tightening:
			_pull_loop()
		return
	if key_event != null and key_event.keycode == KEY_X:
		if enable_string_recovery:
			_remove_loop()
		return
	var direction := Vector2i.ZERO
	if event.is_action_pressed("ui_up") or (key_event != null and key_event.keycode == KEY_W):
		direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_down") or (key_event != null and key_event.keycode == KEY_S):
		direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_left") or (key_event != null and key_event.keycode == KEY_A):
		direction = Vector2i(1, 0)
	elif event.is_action_pressed("ui_right") or (key_event != null and key_event.keycode == KEY_D):
		direction = Vector2i(-1, 0)
	if direction != Vector2i.ZERO:
		if enable_manual_movement:
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
	if enable_loop_persistence and not loop_points.is_empty():
		status_label.text = "A persistent loop is already deployed; press X to recover it"
		return
	if max_strings_per_player < 1:
		status_label.text = "No string slots available"
		return
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
	if enable_grid_snap:
		world_position = _snap_loop_point(world_position)
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
	loop_points = LoopGeometry.simplify_path(draw_points, CELL_SIZE * 0.12)
	draw_points.clear()
	loop_caught_cells = LoopGeometry.enclosed_crags(loop_points, world_state, _cell_to_world)
	loop_pulled = false
	_redraw_loop()
	_update_status()
	if not enable_loop_persistence:
		status_label.text = "Loop preview placed (persistence disabled)"

func _screen_to_ground(screen_position: Vector2) -> Vector3:
	var ray_origin := camera.project_ray_origin(screen_position)
	var ray_direction := camera.project_ray_normal(screen_position)
	if abs(ray_direction.y) < 0.0001:
		return Vector3.INF
	var distance := (LOOP_HEIGHT - ray_origin.y) / ray_direction.y
	if distance < 0.0:
		return Vector3.INF
	return ray_origin + ray_direction * distance

func _snap_loop_point(point: Vector3) -> Vector3:
	var grid_x := snappedf(point.x / CELL_SIZE, 1.0) * CELL_SIZE
	var grid_z := snappedf(point.z / CELL_SIZE, 1.0) * CELL_SIZE
	var snap_x: bool = absf(point.x - grid_x) <= GRID_SNAP_DISTANCE
	var snap_z: bool = absf(point.z - grid_z) <= GRID_SNAP_DISTANCE
	if snap_x:
		point.x = grid_x
	if snap_z:
		point.z = grid_z
	return point

func _simplify_loop_path(points: Array[Vector3]) -> Array[Vector3]:
	return LoopGeometry.simplify_path(points, CELL_SIZE * 0.12)

func _cells_inside_loop() -> Array[Vector2i]:
	return LoopGeometry.enclosed_crags(loop_points, world_state, _cell_to_world)

func _point_inside_loop(point: Vector3) -> bool:
	return LoopGeometry.point_inside_loop(point, loop_points)

func _pull_loop() -> void:
	if loop_points.is_empty():
		return
	loop_pulled = true
	var start: Array = loop_points.duplicate()
	var player_position := _cell_to_world(player_cell) + Vector3(0.0, LOOP_HEIGHT, 0.0)
	var target := _build_tightened_loop(start, player_position)
	if target.size() != start.size():
		loop_pulled = false
		status_label.text = "Pull blocked: no canonical tightened loop"
		return
	if enable_obstacle_clearance and not _loop_segments_clear(target):
		loop_pulled = false
		status_label.text = "Pull blocked: the tightened loop would cross an obstacle"
		return
	if enable_cactus_cutting and _loop_touches_cactus(target):
		_remove_loop()
		status_label.text = "Cactus cut the loop during tightening"
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_tween_loop.bind(start, target), 0.0, 1.0, 0.65)
	_update_status()

func _build_tightened_loop(start: Array, player_position: Vector3) -> Array:
	return LoopGeometry.tightened_loop(start, player_position, world_state, _cell_to_world, OBSTACLE_CLEARANCE, PULL_ITERATIONS, PULL_STEP)

func _loop_segments_clear(points: Array) -> bool:
	return LoopGeometry.segments_clear(points, world_state, _cell_to_world, OBSTACLE_CLEARANCE)

func _loop_touches_cactus(points: Array) -> bool:
	return LoopGeometry.touches_cactus(points, world_state, _cell_to_world, OBSTACLE_CLEARANCE)

func _segment_hits_obstacle(start: Vector3, end: Vector3, obstacle: Vector3) -> bool:
	return LoopGeometry.segment_hits_obstacle(start, end, obstacle, OBSTACLE_CLEARANCE)

func _tween_loop(progress: float, start: Array, target: Array) -> void:
	var point_count := mini(start.size(), target.size())
	var candidate: Array[Vector3] = []
	for i in range(point_count):
		var start_point: Vector3 = start[i]
		var target_point: Vector3 = target[i]
		candidate.append(start_point.lerp(target_point, progress))
	if not enable_obstacle_clearance or _loop_segments_clear(candidate):
		loop_points = candidate
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
