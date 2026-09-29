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
const LOOP_HEIGHT := 0.24
const LOOP_WIDTH := 0.045
const WINDING_LIFT := 0.14
const ROPE_SAMPLE_SPACING := 0.34
const ROPE_CONTACT_RADIUS := 1.02
const OBSTACLE_CLEARANCE := 0.92
const GRID_SNAP_DISTANCE := 0.42
const WATER_Y := 0.22
const CRAG_SCALE := Vector3(0.46, 1.25, 0.46)
const CACTUS_SCALE := Vector3.ONE * 0.72
const PULL_ITERATIONS := 72
const PULL_STEP := 0.2
const STRAIN_STIFFNESS := 42.0
const STRAIN_DAMPING := 10.5
const STRAIN_SETTLE_SPEED := 0.018
const STRAIN_SETTLE_ENERGY := 0.0008

const GROUND_TILE := preload("res://assets/generated/ground_tile.glb")
const CRAG_BREAKABLE := preload("res://assets/generated/crag_breakable.glb")
const CRAG_UNBREAKABLE := preload("res://assets/generated/crag_unbreakable.glb")
const CRAG_BREAKABLE_SPIRE := preload("res://assets/generated/crag_breakable_spire.glb")
const CRAG_UNBREAKABLE_SPIRE := preload("res://assets/generated/crag_unbreakable_spire.glb")
const CACTUS := preload("res://assets/generated/cactus.glb")
const CACTUS_TWIN := preload("res://assets/generated/cactus_twin.glb")
const CACTUS_LOW := preload("res://assets/generated/cactus_low.glb")
const PLAYER_ASSET := preload("res://assets/generated/player_placeholder.glb")

const MechanicsCoreClass = preload("res://scripts/core/mechanics_core.gd")

var mechanics = MechanicsCoreClass.new()
var world_state: WorldState = mechanics.world_state
var player_cell := Vector2i.ZERO
var player: Node3D
var camera: Camera3D
var status_label: Label
var loop_visual: Node3D
var loop_material: StandardMaterial3D
var loop_points: Array[Vector3] = []
var completed_loops: Array[Array] = []
var loop_caught_cells: Array[Vector2i] = []
var loop_pulled := false
var pull_start: Array[Vector3] = []
var pull_target: Array[Vector3] = []
var pull_progress := 0.0
var pull_velocity := 0.0
var pull_trivial := false
var strain_energy := 0.0
var strain_peak_energy := 0.0
var scene_built := false
var drawing_loop := false
var draw_points: Array[Vector3] = []
var draw_origin := Vector3.ZERO
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
	loop_material.albedo_color = Color("#7d183f")
	loop_material.emission_enabled = true
	loop_material.emission = Color("#c22f63")
	loop_material.emission_energy_multiplier = 0.28
	loop_material.metallic = 0.12
	loop_material.roughness = 0.3
	_build_ui()

func _process(delta: float) -> void:
	_advance_strain_animation(delta)

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
	foundation_material.metallic = 0.45
	foundation_material.roughness = 0.92
	var foundation_mesh := BoxMesh.new()
	foundation_mesh.size = Vector3(GRID_SIZE * CELL_SIZE + 1.5, 0.55, GRID_SIZE * CELL_SIZE + 1.5)
	var foundation := MeshInstance3D.new()
	foundation.mesh = foundation_mesh
	foundation.material_override = foundation_material
	foundation.position.y = GROUND_Y - 0.4
	add_child(foundation)
	var stand_material := StandardMaterial3D.new()
	stand_material.albedo_color = Color("#213b3b")
	stand_material.metallic = 0.28
	stand_material.roughness = 0.64
	var stand_mesh := BoxMesh.new()
	stand_mesh.size = Vector3(GRID_SIZE * CELL_SIZE + 2.6, 0.9, GRID_SIZE * CELL_SIZE + 2.6)
	var stand := MeshInstance3D.new()
	stand.mesh = stand_mesh
	stand.material_override = stand_material
	stand.position.y = -1.28
	add_child(stand)
	_build_terrarium_frame()
	_build_desk_and_lamps()

	var limit := (GRID_SIZE - 1) / 2
	for x in range(-limit, limit + 1):
		for z in range(-limit, limit + 1):
			var tile := GROUND_TILE.instantiate() as Node3D
			tile.position = _cell_to_world(Vector2i(x, z)) + Vector3(0.0, GROUND_Y, 0.0)
			tile.scale = Vector3.ONE * (CELL_SIZE / 2.0) * 0.91
			add_child(tile)

	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 35.0
	camera.near = 0.01
	camera.far = 100.0
	camera.position = Vector3(14.0, 22.0, -18.0)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.5, 0.0), Vector3.UP)
	camera.current = true

func _build_desk_and_lamps() -> void:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color("#5a3028")
	wood.roughness = 0.72
	var wood_edge := StandardMaterial3D.new()
	wood_edge.albedo_color = Color("#2b1719")
	wood_edge.roughness = 0.82
	var brass := StandardMaterial3D.new()
	brass.albedo_color = Color("#a97545")
	brass.metallic = 0.72
	brass.roughness = 0.27
	var desk_top := BoxMesh.new()
	desk_top.size = Vector3(54.0, 0.9, 42.0)
	var desk := MeshInstance3D.new()
	desk.mesh = desk_top
	desk.material_override = wood
	desk.position = Vector3(0.0, -2.05, 0.0)
	add_child(desk)
	var desk_front := BoxMesh.new()
	desk_front.size = Vector3(54.0, 0.28, 0.24)
	for z in [-21.0, 21.0]:
		var trim := MeshInstance3D.new()
		trim.mesh = desk_front
		trim.material_override = wood_edge
		trim.position = Vector3(0.0, -1.52, z)
		add_child(trim)
	var apron_mesh := BoxMesh.new()
	apron_mesh.size = Vector3(54.0, 1.7, 0.42)
	var apron := MeshInstance3D.new()
	apron.mesh = apron_mesh
	apron.material_override = wood_edge
	apron.position = Vector3(0.0, -2.95, 19.7)
	add_child(apron)
	var desk_leg_mesh := BoxMesh.new()
	desk_leg_mesh.size = Vector3(1.8, 4.8, 1.8)
	for x in [-23.0, 23.0]:
		for z in [-17.0, 17.0]:
			var leg := MeshInstance3D.new()
			leg.mesh = desk_leg_mesh
			leg.material_override = wood_edge
			leg.position = Vector3(x, -4.7, z)
			add_child(leg)
	_add_desk_lamp(Vector3(-20.0, -1.77, -12.0), Color("#f3b15f"), Color("#e37c45"))
	_add_desk_lamp(Vector3(20.0, -1.77, 12.0), Color("#8bd6ca"), Color("#3a928e"))

func _add_desk_lamp(origin: Vector3, bulb_color: Color, shade_color: Color) -> void:
	var stem_material := StandardMaterial3D.new()
	stem_material.albedo_color = Color("#302127")
	stem_material.metallic = 0.65
	stem_material.roughness = 0.28
	var shade_material := StandardMaterial3D.new()
	shade_material.albedo_color = shade_color
	shade_material.roughness = 0.54
	var bulb_material := StandardMaterial3D.new()
	bulb_material.albedo_color = bulb_color
	bulb_material.emission_enabled = true
	bulb_material.emission = bulb_color
	bulb_material.emission_energy_multiplier = 2.2
	var base_mesh := BoxMesh.new()
	base_mesh.size = Vector3(1.4, 0.22, 1.1)
	var base := MeshInstance3D.new()
	base.mesh = base_mesh
	base.material_override = stem_material
	base.position = origin + Vector3(0.0, 0.48, 0.0)
	add_child(base)
	var stem_mesh := BoxMesh.new()
	stem_mesh.size = Vector3(0.18, 1.45, 0.18)
	var stem := MeshInstance3D.new()
	stem.mesh = stem_mesh
	stem.material_override = stem_material
	stem.position = origin + Vector3(0.0, 1.32, 0.0)
	add_child(stem)
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(1.25, 0.16, 0.16)
	var arm := MeshInstance3D.new()
	arm.mesh = arm_mesh
	arm.material_override = stem_material
	arm.position = origin + Vector3(0.45, 2.12, 0.0)
	arm.rotation_degrees.z = -18.0
	add_child(arm)
	var shade_mesh := BoxMesh.new()
	shade_mesh.size = Vector3(1.05, 0.38, 0.72)
	var shade := MeshInstance3D.new()
	shade.mesh = shade_mesh
	shade.material_override = shade_material
	shade.position = origin + Vector3(0.88, 2.22, 0.0)
	shade.rotation_degrees.z = -18.0
	add_child(shade)
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.24
	bulb_mesh.height = 0.48
	var bulb := MeshInstance3D.new()
	bulb.mesh = bulb_mesh
	bulb.material_override = bulb_material
	bulb.position = origin + Vector3(0.82, 2.10, 0.0)
	add_child(bulb)
	var lamp_light := OmniLight3D.new()
	lamp_light.position = origin + Vector3(0.82, 2.05, 0.0)
	lamp_light.omni_range = 9.0
	lamp_light.light_energy = 1.25
	lamp_light.light_color = bulb_color
	add_child(lamp_light)

func _build_terrarium_frame() -> void:
	var frame_material := StandardMaterial3D.new()
	frame_material.albedo_color = Color("#10252b")
	frame_material.metallic = 0.35
	frame_material.roughness = 0.3
	var glass_material := StandardMaterial3D.new()
	glass_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_material.albedo_color = Color(0.16, 0.70, 0.72, 0.11)
	glass_material.metallic = 0.2
	glass_material.roughness = 0.04
	glass_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_material.no_depth_test = true
	var glass_edge_material := StandardMaterial3D.new()
	glass_edge_material.albedo_color = Color("#67d1c5")
	glass_edge_material.emission_enabled = true
	glass_edge_material.emission = Color("#1d756f")
	glass_edge_material.emission_energy_multiplier = 0.7
	glass_edge_material.metallic = 0.35
	glass_edge_material.roughness = 0.22
	var extent := GRID_SIZE * CELL_SIZE * 0.5 + 0.35
	var wall_height := 4.6
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
	var edge_mesh := BoxMesh.new()
	edge_mesh.size = Vector3(extent * 2.0, 0.07, 0.07)
	for y in [0.08, wall_height - 0.04]:
		for z in [-extent, extent]:
			var edge := MeshInstance3D.new()
			edge.mesh = edge_mesh
			edge.material_override = glass_edge_material
			edge.position = Vector3(0.0, y, z)
			add_child(edge)
	var side_edge_mesh := BoxMesh.new()
	side_edge_mesh.size = Vector3(0.07, 0.07, extent * 2.0)
	for y in [0.08, wall_height - 0.04]:
		for x in [-extent, extent]:
			var edge := MeshInstance3D.new()
			edge.mesh = side_edge_mesh
			edge.material_override = glass_edge_material
			edge.position = Vector3(x, y, 0.0)
			add_child(edge)
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
	var lid_material := StandardMaterial3D.new()
	lid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lid_material.albedo_color = Color(0.20, 0.75, 0.72, 0.035)
	lid_material.emission_enabled = true
	lid_material.emission = Color("#164b4c")
	lid_material.emission_energy_multiplier = 0.25
	lid_material.no_depth_test = true
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(extent * 2.0, 0.035, extent * 2.0)
	var lid := MeshInstance3D.new()
	lid.mesh = lid_mesh
	lid.material_override = lid_material
	lid.position.y = wall_height
	add_child(lid)

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
		if kind == "crag_breakable_spire":
			asset = CRAG_BREAKABLE_SPIRE
		elif kind == "crag_unbreakable":
			asset = CRAG_UNBREAKABLE
		elif kind == "crag_unbreakable_spire":
			asset = CRAG_UNBREAKABLE_SPIRE
		elif kind == "cactus":
			asset = CACTUS
		elif kind == "cactus_twin":
			asset = CACTUS_TWIN
		elif kind == "cactus_low":
			asset = CACTUS_LOW
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
	var top_bar := _panel(Vector2(28, 24), Vector2(300, 72), Color("#08151be8"), Color("#31545a"))
	canvas.add_child(top_bar)
	var eyebrow := _label("FIELD STUDY  /  01", 11, Color("#63c0b6"))
	eyebrow.position = Vector2(18, 12)
	top_bar.add_child(eyebrow)
	var title := _label("FUNDAMENTAL FIGHT", 20, Color("#f0c879"))
	title.position = Vector2(16, 33)
	top_bar.add_child(title)

	var telemetry := _panel(Vector2(28, 116), Vector2(258, 252), Color("#08151be8"), Color("#31545a"))
	canvas.add_child(telemetry)
	var telemetry_header := _label("SPECIMEN TELEMETRY", 11, Color("#63c0b6"))
	telemetry_header.position = Vector2(18, 16)
	telemetry.add_child(telemetry_header)
	var rule := ColorRect.new()
	rule.position = Vector2(18, 39)
	rule.size = Vector2(222, 1)
	rule.color = Color("#31545a")
	telemetry.add_child(rule)
	status_label = Label.new()
	status_label.position = Vector2(18, 55)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("#d8e2d5"))
	status_label.add_theme_constant_override("line_spacing", 9)
	telemetry.add_child(status_label)

	var objective := _panel(Vector2(28, 388), Vector2(258, 90), Color("#0c2024e8"), Color("#3d756e"))
	canvas.add_child(objective)
	var objective_code := _label("TASK  /  A-01", 10, Color("#63c0b6"))
	objective_code.position = Vector2(18, 14)
	objective.add_child(objective_code)
	var objective_text := _label("Map the empty\nspecimen field", 17, Color("#e3e9d8"))
	objective_text.position = Vector2(18, 34)
	objective.add_child(objective_text)

	var footer := _label("RIFTGARDEN OBSERVATORY", 10, Color("#527a7d"))
	footer.position = Vector2(30, 500)
	canvas.add_child(footer)
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
		direction = Vector2i(0, 1)
	elif event.is_action_pressed("ui_down") or (key_event != null and key_event.keycode == KEY_S):
		direction = Vector2i(0, -1)
	elif event.is_action_pressed("ui_left") or (key_event != null and key_event.keycode == KEY_A):
		direction = Vector2i(1, 0)
	elif event.is_action_pressed("ui_right") or (key_event != null and key_event.keycode == KEY_D):
		direction = Vector2i(-1, 0)
	if direction != Vector2i.ZERO:
		if enable_manual_movement:
			_move_player(player_cell + direction)

func _move_player(target: Vector2i) -> void:
	if not mechanics.try_move_to(target, GRID_SIZE):
		if occupied.has(target):
			status_label.text = "Blocked: %s at (%d, %d)" % [occupied[target].capitalize(), target.x, target.y]
		else:
			status_label.text = "Outside the playable manifold"
		return
	player_cell = mechanics.player_cell
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var move_duration := mechanics.movement_duration(_pulling_nontrivial_loop())
	tween.tween_property(player, "position", _cell_to_world(player_cell) + Vector3(0.0, GROUND_Y, 0.0), move_duration)
	_update_status()

func _update_status() -> void:
	if status_label:
		var loop_state := "none"
		if not completed_loops.is_empty() or drawing_loop:
			loop_state = "tight" if loop_pulled else "placed"
		status_label.text = "CELL        %02d, %02d\nCRAGS       05\nCACTUS      01\nLOOPS       %d\nLOOP        %s\nSTRAIN      %0.2f" % [player_cell.x, player_cell.y, completed_loops.size(), loop_state.to_upper(), strain_energy]

func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)

func _begin_loop_drawing(screen_position: Vector2) -> void:
	if completed_loops.size() >= max_strings_per_player:
		status_label.text = "String capacity reached (%d)" % max_strings_per_player
		return
	var world_position := _screen_to_ground(screen_position)
	var player_position := _cell_to_world(player_cell) + Vector3(0.0, LOOP_HEIGHT, 0.0)
	if world_position == Vector3.INF or _snap_loop_point(world_position).distance_to(player_position) > CELL_SIZE * 0.5:
		status_label.text = "Start the loop by dragging from the player"
		return
	drawing_loop = true
	draw_origin = player_position
	draw_points = [draw_origin]
	loop_points = draw_points.duplicate()
	loop_pulled = false
	_redraw_loop()

func _append_draw_point(screen_position: Vector2) -> void:
	var world_position := _screen_to_ground(screen_position)
	if world_position == Vector3.INF or draw_points.is_empty():
		return
	if enable_grid_snap:
		world_position = _snap_loop_point(world_position)
	if not _is_lasso_anchor_allowed(world_position):
		status_label.text = "Lasso anchor is outside the level box"
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
	# Releasing the mouse is not enough to close a lasso. The endpoint must
	# explicitly return to the player's anchor; until then the preview remains
	# an open rope and the player can continue drawing.
	if draw_points.size() < 2 or draw_points.back().distance_to(draw_origin) > CELL_SIZE * 0.5:
		_redraw_loop()
		_update_status()
		status_label.text = "Lasso still open: return the rope to the player to close it"
		return
	drawing_loop = false
	if draw_points.size() < 4:
		draw_points.clear()
		loop_points.clear()
		_redraw_loop()
		_update_status()
		return
	draw_points.append(draw_origin)
	loop_points = LoopGeometry.simplify_path(draw_points, CELL_SIZE * 0.12)
	draw_points.clear()
	if not _loop_points_within_level(loop_points):
		loop_points.clear()
		_redraw_loop()
		status_label.text = "Loop rejected: it leaves the level box"
		return
	if enable_obstacle_clearance and not LoopGeometry.segments_clear(loop_points, world_state, _cell_to_world, OBSTACLE_CLEARANCE):
		loop_points.clear()
		loop_caught_cells.clear()
		_redraw_loop()
		status_label.text = "Loop rejected: the drawn rope crossed a rock or cactus"
		return
	loop_caught_cells = LoopGeometry.enclosed_crags(loop_points, world_state, _cell_to_world)
	loop_pulled = false
	mechanics.add_loop(loop_points)
	completed_loops = mechanics.loops
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
	point.x = grid_x
	point.z = grid_z
	return point

func _is_lasso_anchor_allowed(point: Vector3) -> bool:
	var limit := (GRID_SIZE - 1) / 2
	var cell_x := roundi(point.x / CELL_SIZE)
	var cell_z := roundi(point.z / CELL_SIZE)
	return abs(cell_x) <= limit and abs(cell_z) <= limit

func _loop_points_within_level(points: Array) -> bool:
	for point in points:
		if not _is_lasso_anchor_allowed(point):
			return false
	return true

func _simplify_loop_path(points: Array[Vector3]) -> Array[Vector3]:
	return LoopGeometry.simplify_path(points, CELL_SIZE * 0.12)

func _cells_inside_loop() -> Array[Vector2i]:
	return LoopGeometry.enclosed_crags(loop_points, world_state, _cell_to_world)

func _point_inside_loop(point: Vector3) -> bool:
	return LoopGeometry.point_inside_loop(point, loop_points)

func _pull_loop() -> void:
	if completed_loops.is_empty():
		return
	loop_points = mechanics.latest_loop()
	var start: Array = loop_points.duplicate()
	var player_position := _cell_to_world(player_cell) + Vector3(0.0, LOOP_HEIGHT, 0.0)
	var target := _build_tightened_loop(player_position)
	var trivial := LoopGeometry.is_trivial(start, world_state, _cell_to_world)
	pull_trivial = trivial
	if trivial:
		target = _collapsed_loop(start, player_position)
	if target.size() != start.size():
		loop_pulled = false
		status_label.text = "Pull blocked: the current rope crosses an obstacle"
		return
	if enable_obstacle_clearance and not _loop_segments_clear(target):
		loop_pulled = false
		status_label.text = "Pull blocked: the tightened loop would cross an obstacle"
		return
	if enable_cactus_cutting and _loop_touches_cactus(target):
		_remove_loop()
		status_label.text = "Cactus cut the loop during tightening"
		return
	pull_start = start
	pull_target = target
	pull_progress = 0.0
	pull_velocity = 0.0
	strain_peak_energy = _strain_energy(start, target)
	strain_energy = strain_peak_energy
	loop_pulled = true
	_redraw_loop()
	_update_status()

func _build_tightened_loop(player_position: Vector3) -> Array:
	return mechanics.tightened_latest_loop(player_position, _cell_to_world, OBSTACLE_CLEARANCE, PULL_ITERATIONS, PULL_STEP)

func _pulling_nontrivial_loop() -> bool:
	return not pull_start.is_empty() and not pull_trivial

func _collapsed_loop(start: Array, player_position: Vector3) -> Array:
	var collapsed: Array[Vector3] = []
	for _point in start:
		collapsed.append(player_position)
	return collapsed

func _loop_segments_clear(points: Array) -> bool:
	return LoopGeometry.segments_clear(points, world_state, _cell_to_world, OBSTACLE_CLEARANCE)

func _loop_touches_cactus(points: Array) -> bool:
	return LoopGeometry.touches_cactus(points, world_state, _cell_to_world, OBSTACLE_CLEARANCE)

func _segment_hits_obstacle(start: Vector3, end: Vector3, obstacle: Vector3) -> bool:
	return LoopGeometry.segment_hits_obstacle(start, end, obstacle, OBSTACLE_CLEARANCE)

func _advance_strain_animation(delta: float) -> void:
	if pull_start.is_empty() or pull_target.is_empty():
		return
	var displacement := 1.0 - pull_progress
	var acceleration := displacement * STRAIN_STIFFNESS - pull_velocity * STRAIN_DAMPING
	pull_velocity += acceleration * delta
	pull_progress += pull_velocity * delta
	var candidate := _interpolate_pull(pull_progress, pull_start, pull_target)
	if _loop_segments_clear(candidate):
		loop_points = candidate
	else:
		# Collision is a hard visual constraint; dissipate the invalid portion
		# of the spring instead of allowing the animation to tunnel through it.
		pull_velocity = minf(pull_velocity, 0.0)
		pull_progress = minf(pull_progress, 1.0)
		loop_points = _interpolate_pull(pull_progress, pull_start, pull_target)
	strain_energy = _strain_energy(loop_points, pull_target)
	var tension := clampf(strain_energy / maxf(strain_peak_energy, 0.001), 0.0, 1.0)
	loop_material.albedo_color = Color("#7d183f").lerp(Color("#bd2d5d"), tension)
	loop_material.emission_energy_multiplier = 0.22 + tension * 0.38
	if not completed_loops.is_empty():
		completed_loops[completed_loops.size() - 1] = loop_points.duplicate()
		mechanics.loops[mechanics.loops.size() - 1] = loop_points.duplicate()
	_redraw_loop()
	if absf(1.0 - pull_progress) < STRAIN_SETTLE_SPEED and absf(pull_velocity) < STRAIN_SETTLE_SPEED and strain_energy < STRAIN_SETTLE_ENERGY:
		loop_points = pull_target.duplicate()
		if pull_trivial and not completed_loops.is_empty():
			mechanics.remove_latest_loop()
		elif not completed_loops.is_empty():
			completed_loops[completed_loops.size() - 1] = loop_points.duplicate()
		pull_start.clear()
		pull_target.clear()
		pull_progress = 1.0
		pull_velocity = 0.0
		pull_trivial = false
		strain_energy = 0.0
		_redraw_loop()
		_update_status()

func _interpolate_pull(progress: float, start: Array, target: Array) -> Array[Vector3]:
	var point_count := mini(start.size(), target.size())
	var candidate: Array[Vector3] = []
	for i in range(point_count):
		var start_point: Vector3 = start[i]
		var target_point: Vector3 = target[i]
		candidate.append(start_point.lerp(target_point, clampf(progress, 0.0, 1.0)))
	return candidate

func _strain_energy(current: Array, target: Array) -> float:
	var displacement_squared := 0.0
	var point_count := mini(current.size(), target.size())
	for i in range(point_count):
		displacement_squared += current[i].distance_squared_to(target[i])
	return 0.5 * STRAIN_STIFFNESS * displacement_squared / maxf(float(point_count), 1.0)

func _remove_loop() -> void:
	if completed_loops.is_empty():
		return
	mechanics.remove_latest_loop()
	loop_points.clear()
	loop_caught_cells.clear()
	loop_pulled = false
	pull_start.clear()
	pull_target.clear()
	pull_progress = 0.0
	pull_velocity = 0.0
	pull_trivial = false
	strain_energy = 0.0
	strain_peak_energy = 0.0
	_redraw_loop()
	_update_status()

func _redraw_loop() -> void:
	for child in loop_visual.get_children():
		child.free()
	for path in completed_loops:
		_add_rope_visual(path, true)
	if drawing_loop and draw_points.size() >= 2:
		_add_rope_visual(draw_points, false)

func _add_rope_visual(path: Array, closed: bool) -> void:
	if path.size() < 2:
		return
	var closed_path: Array[Vector3] = _resample_visual_path(path, closed)
	if closed and closed_path[0].distance_to(closed_path[closed_path.size() - 1]) > 0.01:
		closed_path.append(closed_path[0])
	closed_path = _press_visual_rope_to_crags(closed_path, closed)
	closed_path = _visualize_winding(closed_path, closed)
	var rope := MeshInstance3D.new()
	rope.name = "RopeMesh"
	rope.mesh = _build_rope_mesh(closed_path, closed)
	rope.material_override = loop_material
	loop_visual.add_child(rope)

func _resample_visual_path(path: Array, closed: bool) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for index in range(path.size() - 1):
		var start: Vector3 = path[index]
		var end: Vector3 = path[index + 1]
		var segment_length := start.distance_to(end)
		var steps := maxi(1, ceili(segment_length / ROPE_SAMPLE_SPACING))
		for step in range(steps):
			if index > 0 and step == 0:
				continue
			result.append(start.lerp(end, float(step) / float(steps)))
	result.append(path[path.size() - 1])
	if closed and result.size() > 1 and result[0].distance_to(result[result.size() - 1]) < 0.01:
		result[result.size() - 1] = result[0]
	return result

func _press_visual_rope_to_crags(path: Array[Vector3], closed: bool) -> Array[Vector3]:
	if not closed:
		return path
	var result: Array[Vector3] = path.duplicate()
	for index in range(result.size() - 1):
		var point: Vector3 = result[index]
		for cell in occupied:
			if not world_state.is_crag(cell):
				continue
			var obstacle := _cell_to_world(cell)
			var offset := Vector2(point.x - obstacle.x, point.z - obstacle.z)
			var distance := offset.length()
			if distance > 0.001 and distance < ROPE_CONTACT_RADIUS + 0.22:
				var contact := offset.normalized() * ROPE_CONTACT_RADIUS
				point.x = obstacle.x + contact.x
				point.z = obstacle.z + contact.y
		result[index] = point
	result[result.size() - 1] = result[0]
	return result

func _visualize_winding(path: Array[Vector3], closed: bool) -> Array[Vector3]:
	if not LoopGeometry.has_self_intersection(path):
		return path
	var lifted: Array[Vector3] = []
	var last_index := path.size() - 1 if closed else path.size()
	for i in range(path.size()):
		var point: Vector3 = path[i]
		var progress := float(i) / float(maxi(last_index, 1))
		point.y += WINDING_LIFT * sin(TAU * progress)
		lifted.append(point)
	return lifted

func _build_rope_mesh(path: Array[Vector3], closed: bool) -> ArrayMesh:
	var sides := 12
	var rings := path.size() - 1 if closed else path.size()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var energy_ratio := clampf(strain_energy / maxf(strain_peak_energy, 0.001), 0.0, 1.0)
	var radius := LOOP_WIDTH * (1.0 + energy_ratio * 0.35)
	for ring_index in range(rings):
		var point: Vector3 = path[ring_index]
		var previous_index := (ring_index - 1 + rings) % rings if closed else maxi(ring_index - 1, 0)
		var next_index := (ring_index + 1) % rings if closed else mini(ring_index + 1, rings - 1)
		var previous: Vector3 = path[previous_index]
		var next: Vector3 = path[next_index]
		var tangent := Vector2(next.x - previous.x, next.z - previous.z).normalized()
		if tangent.length_squared() < 0.01:
			tangent = Vector2.RIGHT
		var side := Vector3(-tangent.y, 0.0, tangent.x)
		for side_index in range(sides):
			var angle := TAU * float(side_index) / float(sides)
			var radial := side * cos(angle) + Vector3.UP * sin(angle)
			var braid_phase := float(ring_index) * 0.9 + float(side_index) * 1.45
			var braid_radius := radius * (1.0 + 0.055 * sin(braid_phase))
			vertices.append(point + radial * braid_radius)
			normals.append(radial)
			uvs.append(Vector2(float(ring_index) / float(rings), float(side_index) / float(sides)))
	var link_count := rings if closed else rings - 1
	for ring_index in range(link_count):
		var next_ring := (ring_index + 1) % rings
		for side_index in range(sides):
			var next_side := (side_index + 1) % sides
			var a := ring_index * sides + side_index
			var b := next_ring * sides + side_index
			var c := next_ring * sides + next_side
			var d := ring_index * sides + next_side
			indices.append_array([a, b, c, a, c, d])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
