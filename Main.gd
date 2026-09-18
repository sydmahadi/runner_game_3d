extends Node3D

# ============================================================
# RUNNER GAME 3D
# Simple Subway-Surfers Style Prototype
# Godot 4.3
# ============================================================

var player: Node3D
var camera: Camera3D

var player_lane: int = 0
var target_x: float = 0.0

var forward_speed: float = 10.0
var lane_width: float = 3.0

var score: int = 0
var coins: int = 0
var game_over: bool = false

var road_segments: Array[Node3D] = []
var obstacles: Array[Node3D] = []
var coins_nodes: Array[Node3D] = []
var trees: Array[Node3D] = []

var score_label: Label
var coin_label: Label
var game_over_panel: Control

var spawn_timer: float = 0.0
var coin_spawn_timer: float = 0.0
var scenery_timer: float = 0.0

const ROAD_LENGTH := 20.0
const ROAD_SEGMENTS := 12


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	_setup_environment()
	_setup_camera()
	_create_world()
	_create_player()
	_create_ui()


# ============================================================
# ENVIRONMENT
# ============================================================

func _setup_environment() -> void:
	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.38, 0.68, 0.92)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.85, 1.0)
	environment.ambient_light_energy = 0.8

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -25.0, 0.0)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	add_child(sun)


# ============================================================
# CAMERA
# ============================================================

func _setup_camera() -> void:
	camera = Camera3D.new()

	camera.position = Vector3(0.0, 5.0, 10.0)
	camera.rotation_degrees = Vector3(-12.0, 0.0, 0.0)

	camera.current = true
	camera.fov = 65.0

	add_child(camera)


# ============================================================
# WORLD
# ============================================================

func _create_world() -> void:

	# Grass base
	var grass := MeshInstance3D.new()
	var grass_mesh := BoxMesh.new()

	grass_mesh.size = Vector3(30.0, 0.2, 300.0)
	grass.mesh = grass_mesh
	grass.position = Vector3(0.0, -0.25, -120.0)

	grass.material_override = _material(
		Color(0.10, 0.38, 0.14)
	)

	add_child(grass)


	# Road segments
	for i in range(ROAD_SEGMENTS):

		var road := Node3D.new()

		var road_mesh := BoxMesh.new()
		road_mesh.size = Vector3(10.0, 0.25, ROAD_LENGTH)

		var road_part := MeshInstance3D.new()
		road_part.mesh = road_mesh

		road_part.material_override = _material(
			Color(0.08, 0.09, 0.10)
		)

		road.add_child(road_part)

		road.position = Vector3(
			0.0,
			0.0,
			-i * ROAD_LENGTH
		)

		add_child(road)
		road_segments.append(road)


	# Lane markings
	for i in range(ROAD_SEGMENTS):

		var z := -i * ROAD_LENGTH

		_create_lane_line(
			Vector3(-1.5, 0.14, z),
			Vector3(-1.5, 0.05, 7.0)
		)

		_create_lane_line(
			Vector3(1.5, 0.14, z),
			Vector3(1.5, 0.05, 7.0)
		)


	# Road side barriers
	_create_side_barrier(-5.3)
	_create_side_barrier(5.3)


	# Initial scenery
	for i in range(25):

		var z := -float(i) * 12.0

		_create_tree(-8.0, z)
		_create_tree(8.0, z - 5.0)


# ============================================================
# LANE LINE
# ============================================================

func _create_lane_line(
	pos: Vector3,
	size: Vector3
) -> void:

	var line := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = size
	line.mesh = mesh

	line.position = pos

	line.material_override = _material(
		Color(0.85, 0.85, 0.70)
	)

	add_child(line)


# ============================================================
# ROAD BARRIER
# ============================================================

func _create_side_barrier(x: float) -> void:

	var barrier := MeshInstance3D.new()

	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.25, 0.8, 300.0)

	barrier.mesh = mesh

	barrier.position = Vector3(
		x,
		0.35,
		-120.0
	)

	barrier.material_override = _material(
		Color(0.65, 0.65, 0.65)
	)

	add_child(barrier)


# ============================================================
# PLAYER
# ============================================================

func _create_player() -> void:

	player = Node3D.new()
	player.name = "Player"

	player.position = Vector3(
		0.0,
		1.2,
		2.0
	)

	add_child(player)


	# Body
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()

	body_mesh.size = Vector3(
		1.1,
		1.5,
		0.7
	)

	body.mesh = body_mesh
	body.position = Vector3(0, 0.0, 0)

	body.material_override = _material(
		Color(0.08, 0.30, 0.75)
	)

	player.add_child(body)


	# Head
	var head := MeshInstance3D.new()
	var head_mesh := SphereMesh.new()

	head_mesh.radius = 0.42
	head_mesh.height = 0.84

	head.mesh = head_mesh
	head.position = Vector3(
		0,
		1.0,
		0
	)

	head.material_override = _material(
		Color(0.75, 0.48, 0.30)
	)

	player.add_child(head)


	# Hair
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()

	hair_mesh.radius = 0.43
	hair_mesh.height = 0.35

	hair.mesh = hair_mesh
	hair.position = Vector3(
		0,
		1.25,
		0
	)

	hair.material_override = _material(
		Color(0.05, 0.03, 0.02)
	)

	player.add_child(hair)


	# Legs
	_create_player_part(
		Vector3(-0.3, -1.0, 0),
		Vector3(0.35, 0.8, 0.45),
		Color(0.05, 0.05, 0.08)
	)

	_create_player_part(
		Vector3(0.3, -1.0, 0),
		Vector3(0.35, 0.8, 0.45),
		Color(0.05, 0.05, 0.08)
	)


# ============================================================
# PLAYER PART
# ============================================================

func _create_player_part(
	pos: Vector3,
	size: Vector3,
	color: Color
) -> void:

	var part := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = size
	part.mesh = mesh

	part.position = pos

	part.material_override = _material(color)

	player.add_child(part)


# ============================================================
# TREE
# ============================================================

func _create_tree(x: float, z: float) -> void:

	var tree := Node3D.new()

	tree.position = Vector3(
		x,
		0,
		z
	)

	add_child(tree)

	# Trunk
	var trunk := MeshInstance3D.new()
	var trunk_mesh := CylinderMesh.new()

	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.32
	trunk_mesh.height = 2.5

	trunk.mesh = trunk_mesh

	trunk.position = Vector3(
		0,
		1.25,
		0
	)

	trunk.material_override = _material(
		Color(0.30, 0.16, 0.07)
	)

	tree.add_child(trunk)


	# Leaves
	var leaves := MeshInstance3D.new()
	var leaves_mesh := SphereMesh.new()

	leaves_mesh.radius = 1.3
	leaves_mesh.height = 2.6

	leaves.mesh = leaves_mesh

	leaves.position = Vector3(
		0,
		3.0,
		0
	)

	leaves.material_override = _material(
		Color(0.05, 0.35, 0.10)
	)

	tree.add_child(leaves)

	trees.append(tree)


# ============================================================
# OBSTACLE
# ============================================================

func _spawn_obstacle() -> void:

	var obstacle := Node3D.new()

	var lane := randi_range(-1, 1)

	obstacle.position = Vector3(
		lane * lane_width,
		0.9,
		-110.0
	)

	add_child(obstacle)

	# Main block
	var block := MeshInstance3D.new()
	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		1.8,
		1.8,
		1.4
	)

	block.mesh = mesh

	block.material_override = _material(
		Color(0.80, 0.10, 0.08)
	)

	obstacle.add_child(block)


	# Warning stripe
	var stripe := MeshInstance3D.new()
	var stripe_mesh := BoxMesh.new()

	stripe_mesh.size = Vector3(
		1.9,
		0.25,
		1.5
	)

	stripe.mesh = stripe_mesh

	stripe.position = Vector3(
		0,
		0.3,
		-0.72
	)

	stripe.material_override = _material(
		Color(1.0, 0.75, 0.05)
	)

	obstacle.add_child(stripe)

	obstacles.append(obstacle)


# ============================================================
# COIN
# ============================================================

func _spawn_coin() -> void:

	var coin := Node3D.new()

	var lane := randi_range(-1, 1)

	coin.position = Vector3(
		lane * lane_width,
		1.4,
		-110.0
	)

	add_child(coin)

	var mesh_instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()

	mesh.top_radius = 0.45
	mesh.bottom_radius = 0.45
	mesh.height = 0.12

	mesh_instance.mesh = mesh

	mesh_instance.rotation_degrees = Vector3(
		90,
		0,
		0
	)

	mesh_instance.material_override = _material(
		Color(1.0, 0.72, 0.05)
	)

	coin.add_child(mesh_instance)

	coins_nodes.append(coin)


# ============================================================
# UI
# ============================================================

func _create_ui() -> void:

	var canvas := CanvasLayer.new()
	add_child(canvas)


	# Score
	score_label = Label.new()

	score_label.text = "SCORE  0"
	score_label.position = Vector2(20, 20)

	score_label.add_theme_font_size_override(
		"font_size",
		28
	)

	canvas.add_child(score_label)


	# Coin count
	coin_label = Label.new()

	coin_label.text = "🟡 0"
	coin_label.position = Vector2(20, 60)

	coin_label.add_theme_font_size_override(
		"font_size",
		24
	)

	canvas.add_child(coin_label)


	# Left button
	var left_button := Button.new()

	left_button.text = "◀"
	left_button.position = Vector2(
		25,
		560
	)

	left_button.size = Vector2(
		100,
		80
	)

	left_button.add_theme_font_size_override(
		"font_size",
		35
	)

	left_button.pressed.connect(_move_left)

	canvas.add_child(left_button)


	# Right button
	var right_button := Button.new()

	right_button.text = "▶"
	right_button.position = Vector2(
		235,
		560
	)

	right_button.size = Vector2(
		100,
		80
	)

	right_button.add_theme_font_size_override(
		"font_size",
		35
	)

	right_button.pressed.connect(_move_right)

	canvas.add_child(right_button)


	# Game over panel
	game_over_panel = Control.new()

	game_over_panel.visible = false

	game_over_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	canvas.add_child(game_over_panel)

	var panel := ColorRect.new()

	panel.color = Color(
		0.02,
		0.02,
		0.02,
		0.85
	)

	panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	game_over_panel.add_child(panel)


	var game_over_text := Label.new()

	game_over_text.text = "GAME OVER\n\nTap to Restart"

	game_over_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	game_over_text.set_anchors_and_offsets_preset(
		Control.PRESET_CENTER
	)

	game_over_text.position = Vector2(
		-120,
		-100
	)

	game_over_text.size = Vector2(
		240,
		200
	)

	game_over_text.add_theme_font_size_override(
		"font_size",
		30
	)

	game_over_panel.add_child(game_over_text)

	game_over_panel.gui_input.connect(_game_over_input)


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(event: InputEvent) -> void:

	if game_over:
		return

	if event is InputEventScreenTouch:

		if event.pressed:

			var screen_width := get_viewport().get_visible_rect().size.x

			if event.position.x < screen_width / 2.0:
				_move_left()
			else:
				_move_right()


	if event is InputEventKey:

		if event.pressed:

			if event.keycode == KEY_LEFT:
				_move_left()

			elif event.keycode == KEY_RIGHT:
				_move_right()


# ============================================================
# MOVE LEFT
# ============================================================

func _move_left() -> void:

	if game_over:
		return

	player_lane -= 1

	player_lane = clamp(
		player_lane,
		-1,
		1
	)

	target_x = player_lane * lane_width


# ============================================================
# MOVE RIGHT
# ============================================================

func _move_right() -> void:

	if game_over:
		return

	player_lane += 1

	player_lane = clamp(
		player_lane,
		-1,
		1
	)

	target_x = player_lane * lane_width


# ============================================================
# GAME LOOP
# ============================================================

func _process(delta: float) -> void:

	if game_over:
		return


	# Player lane movement
	if player:

		player.position.x = lerp(
			player.position.x,
			target_x,
			10.0 * delta
		)

		# Running animation
		player.position.y = 1.2 + sin(
			Time.get_ticks_msec() * 0.012
		) * 0.08


	# Move road
	for road in road_segments:

		road.position.z += forward_speed * delta

		if road.position.z > 15.0:

			road.position.z -= (
				ROAD_LENGTH * ROAD_SEGMENTS
			)


	# Move trees
	for tree in trees:

		tree.position.z += forward_speed * delta

		if tree.position.z > 15.0:

			tree.position.z -= 300.0


	# Move obstacles
	for obstacle in obstacles:

		if is_instance_valid(obstacle):

			obstacle.position.z += forward_speed * delta

			if obstacle.position.z > 15.0:

				obstacle.queue_free()


	# Move coins
	for coin in coins_nodes:

		if is_instance_valid(coin):

			coin.position.z += forward_speed * delta

			coin.rotation.y += 5.0 * delta

			if coin.position.z > 15.0:

				coin.queue_free()


	# Spawn obstacles
	spawn_timer += delta

	if spawn_timer > 1.8:

		spawn_timer = 0.0

		_spawn_obstacle()


	# Spawn coins
	coin_spawn_timer += delta

	if coin_spawn_timer > 1.0:

		coin_spawn_timer = 0.0

		_spawn_coin()


	# Score
	score += int(delta * 10.0)

	score_label.text = "SCORE  " + str(score)
	coin_label.text = "🟡 " + str(coins)


	_check_collisions()


# ============================================================
# COLLISION CHECK
# ============================================================

func _check_collisions() -> void:

	if player == null:
		return


	for obstacle in obstacles:

		if not is_instance_valid(obstacle):
			continue

		var distance := player.global_position.distance_to(
			obstacle.global_position
		)

		if distance < 1.5:

			_game_over()


	for coin in coins_nodes:

		if not is_instance_valid(coin):
			continue

		var distance := player.global_position.distance_to(
			coin.global_position
		)

		if distance < 1.3:

			coins += 1

			coin.queue_free()


# ============================================================
# GAME OVER
# ============================================================

func _game_over() -> void:

	game_over = true

	game_over_panel.visible = true


# ============================================================
# RESTART
# ============================================================

func _game_over_input(event: InputEvent) -> void:

	if event is InputEventScreenTouch:

		if event.pressed:

			get_tree().reload_current_scene()


# ============================================================
# MATERIAL
# ============================================================

func _material(color: Color) -> StandardMaterial3D:

	var material := StandardMaterial3D.new()

	material.albedo_color = color

	material.roughness = 0.75

	return material
