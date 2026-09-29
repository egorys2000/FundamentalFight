extends Node3D

const GRID_SIZE := 11
const CELL_SIZE := 1.6
const PLAYER_HEIGHT := 0.8

var player_cell := Vector2i(0, 0)
var player: Node3D
var camera: Camera3D
var status_label: Label
var occupied := {
	Vector2i(-3, -2): "crag",
	Vector2i(-1, 2): "crag",
	Vector2i(2, -2): "crag",
	Vector2i(3, 2): "crag",
	Vector2i(-4, 2): "crag",
	Vector2i(2, 3): "cactus"
}

var ground_material := _material(Color("#30464d"), 0.0, 0.3)
var grid_material := _material(Color("#82a5a5"), 0.0, 0.45)
var crag_material := _material(Color("#718b8a"), 0.0, 0.8)
var crag_dark_material := _material(Color("#40565b"), 0.0, 0.9)
var cactus_material := _material(Color("#56a878"), 0.0, 0.6)
var cactus_flower_material := _material(Color("#f2b86b"), 0.0, 0.45)
var player_material := _material(Color("#e9b45c"), 0.0, 0.35)

func _ready() -> void:
	_build_environment()
	_build_obstacles()
	_build_player()
	_build_ui()

func _material(color: Color, metallic: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metallic
	material.roughness = roughness
	return material

func _box(size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	return instance

func _cylinder(radius: float, height: float, material: Material, sides := 8) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius * 1.08
	mesh.height = height
	mesh.radial_segments = sides
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material
	return instance

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

	var ground := _box(Vector3(GRID_SIZE * CELL_SIZE, 0.35, GRID_SIZE * CELL_SIZE), ground_material)
	ground.position.y = -0.2
	add_child(ground)

	for i in range(GRID_SIZE + 1):
		var offset := -GRID_SIZE * CELL_SIZE * 0.5 + i * CELL_SIZE
		var vertical := _box(Vector3(0.018, 0.018, GRID_SIZE * CELL_SIZE), grid_material)
		vertical.position = Vector3(offset, 0.0, 0.0)
		add_child(vertical)
		var horizontal := _box(Vector3(GRID_SIZE * CELL_SIZE, 0.018, 0.018), grid_material)
		horizontal.position = Vector3(0.0, 0.005, offset)
		add_child(horizontal)

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
		var root := Node3D.new()
		root.position = _cell_to_world(cell)
		add_child(root)
		if kind == "crag":
			var base := _cylinder(0.5, 0.75, crag_dark_material)
			base.position.y = 0.38
			root.add_child(base)
			var peak := _cylinder(0.34, 0.9, crag_material, 6)
			peak.position.y = 1.0
			peak.rotation_degrees = Vector3(0.0, 18.0, -7.0)
			root.add_child(peak)
		else:
			var trunk := _cylinder(0.18, 1.25, cactus_material, 8)
			trunk.position.y = 0.63
			root.add_child(trunk)
			var arm := _cylinder(0.12, 0.58, cactus_material, 8)
			arm.position = Vector3(0.28, 0.75, 0.0)
			arm.rotation_degrees.z = -90.0
			root.add_child(arm)
			var flower := _cylinder(0.16, 0.08, cactus_flower_material, 8)
			flower.position = Vector3(0.0, 1.28, 0.0)
			root.add_child(flower)

func _build_player() -> void:
	player = Node3D.new()
	player.name = "Player"
	player.position = _cell_to_world(player_cell)
	add_child(player)
	var body := _cylinder(0.32, 0.75, player_material, 8)
	body.position.y = 0.48
	player.add_child(body)
	var visor := _box(Vector3(0.42, 0.15, 0.08), cactus_flower_material)
	visor.position = Vector3(0.0, 0.65, -0.29)
	player.add_child(visor)

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
	help.text = "ARROW KEYS / WASD   Move one cell     R   Reset position"
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
	tween.tween_property(player, "position", _cell_to_world(player_cell), 0.16)
	_update_status()

func _update_status() -> void:
	if status_label:
		status_label.text = "Player cell: (%d, %d)     Crags: 5     Cactus: 1     Stage: 0 / Empty map" % [player_cell.x, player_cell.y]

func _cell_to_world(cell: Vector2i) -> Vector3:
	return Vector3(cell.x * CELL_SIZE, 0.0, cell.y * CELL_SIZE)
