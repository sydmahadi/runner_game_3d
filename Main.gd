extends Node3D

# ============================================================
# RUNNER GAME 3D
# Deer Endless Runner
# Godot 4.3
# ============================================================

var player: Node3D
var camera: Camera3D

var player_lane: int = 0
var target_x: float = 0.0

var lane_width: float = 3.0
var forward_speed: float = 10.0

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

var touch_start: Vector2 = Vector2.ZERO
var touch_active: bool = false

const ROAD_LENGTH := 20.0
const ROAD_SEGMENTS := 12


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	_setup_environment()
	_setup_camera()
	_create_world()
	_create_deer()
	_create_ui()


# ============================================================
# ENVIRONMENT
# ============================================================

func _setup_environment() -> void:

	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(
		0.38,
		0.68,
		0.92
	)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR

	environment.ambient_light_color = Color(
		0.8,
		0.9,
		1.0
	)

	environment.ambient_light_energy = 0.8

	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC

	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment

	add_child(world_environment)

	var sun := DirectionalLight3D.new()

	sun.rotation_degrees = Vector3(
		-55.0,
		-25.0,
		0.0
	)

	sun.light_energy = 1.2
	sun.shadow_enabled = true

	add_child(sun)


# ============================================================
# CAMERA
# ============================================================

func _setup_camera() -> void:

	camera = Camera3D.new()

	camera.position = Vector3(
		0.0,
		5.0,
		10.0
	)

	camera.rotation_degrees = Vector3(
		-12.0,
		0.0,
		0.0
	)

	camera.current = true
	camera.fov = 65.0

	add_child(camera)


# ============================================================
# WORLD
# ============================================================

func _create_world() -> void:

	# Grass
	var grass := MeshInstance3D.new()
	var grass_mesh := BoxMesh.new()

	grass_mesh.size = Vector3(
		30.0,
		0.2,
		300.0
	)

	grass.mesh = grass_mesh

	grass.position = Vector3(
		0.0,
		-0.25,
		-120.0
	)

	grass.material_override = _material(
		Color(0.10, 0.38, 0.14)
	)

	add_child(grass)


	# Road
	for i in range(ROAD_SEGMENTS):

		var road := Node3D.new()

		var road_mesh := BoxMesh.new()

		road_mesh.size = Vector3(
			10.0,
			0.25,
			ROAD_LENGTH
		)

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

		var z := -float(i) * ROAD_LENGTH

		_create_lane_line(
			Vector3(-1.5, 0.14, z)
		)

		_create_lane_line(
			Vector3(1.5, 0.14, z)
		)


	# Side barriers
	_create_side_barrier(-5.3)
	_create_side_barrier(5.3)


	# Trees
	for i in range(25):

		var z := -float(i) * 12.0

		_create_tree(-8.0, z)
		_create_tree(8.0, z - 5.0)


# ============================================================
# LANE LINE
# ============================================================

func _create_lane_line(pos: Vector3) -> void:

	var line := MeshInstance3D.new()

	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		0.08,
		0.05,
		7.0
	)

	line.mesh = mesh

	line.position = pos

	line.material_override = _material(
		Color(0.9, 0.9, 0.7)
	)

	add_child(line)


# ============================================================
# SIDE BARRIER
# ============================================================

func _create_side_barrier(x: float) -> void:

	var barrier := MeshInstance3D.new()

	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		0.25,
		0.8,
		300.0
	)

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
# DEER
# ============================================================

func _create_deer() -> void:

	player = Node3D.new()

	player.name = "Deer"

	player.position = Vector3(
		0.0,
		1.15,
		2.0
	)

	add_child(player)


	# -------------------------
	# BODY
	# -------------------------

	var body := MeshInstance3D.new()

	var body_mesh := CapsuleMesh.new()

	body_mesh.radius = 0.55
	body_mesh.height = 1.8

	body.mesh = body_mesh

	body.rotation_degrees = Vector3(
		0,
		0,
		90
	)

	body.position = Vector3(
		0,
		0.15,
		0
	)

	body.material_override = _material(
		Color(0.48, 0.25, 0.10)
	)

	player.add_child(body)


	# -------------------------
	# NECK
	# -------------------------

	var neck := MeshInstance3D.new()

	var neck_mesh := CylinderMesh.new()

	neck_mesh.top_radius = 0.28
	neck_mesh.bottom_radius = 0.38
	neck_mesh.height = 1.3

	neck.mesh = neck_mesh

	neck.rotation_degrees = Vector3(
		-25,
		0,
		0
	)

	neck.position = Vector3(
		0,
		0.85,
		-0.55
	)

	neck.material_override = _material(
		Color(0.50, 0.27, 0.11)
	)

	player.add_child(neck)


	# -------------------------
	# HEAD
	# -------------------------

	var head := MeshInstance3D.new()

	var head_mesh := SphereMesh.new()

	head_mesh.radius = 0.42
	head_mesh.height = 0.75

	head.mesh = head_mesh

	head.position = Vector3(
		0,
		1.35,
		-0.95
	)

	head.material_override = _material(
		Color(0.52, 0.28, 0.12)
	)

	player.add_child(head)


	# -------------------------
	# SNOUT
	# -------------------------

	var snout := MeshInstance3D.new()

	var snout_mesh := SphereMesh.new()

	snout_mesh.radius = 0.25
	snout_mesh.height = 0.45

	snout.mesh = snout_mesh

	snout.position = Vector3(
		0,
		1.28,
		-1.28
	)

	snout.material_override = _material(
		Color(0.35, 0.16, 0.07)
	)

	player.add_child(snout)


	# -------------------------
	# EARS
	# -------------------------

	_create_deer_ear(
		Vector3(-0.28, 1.7, -0.85),
		-20
	)

	_create_deer_ear(
		Vector3(0.28, 1.7, -0.85),
		20
	)


	# -------------------------
	# ANTLERS
	# -------------------------

	_create_antler(
		Vector3(-0.22, 1.72, -0.92)
	)

	_create_antler(
		Vector3(0.22, 1.72, -0.92)
	)


	# -------------------------
	# LEGS
	# -------------------------

	_create_deer_leg(
		Vector3(-0.38, -0.75, -0.35)
	)

	_create_deer_leg(
		Vector3(0.38, -0.75, -0.35)
	)

	_create_deer_leg(
		Vector3(-0.38, -0.75, 0.35)
	)

	_create_deer_leg(
		Vector3(0.38, -0.75, 0.35)
	)


	# -------------------------
	# TAIL
	# -------------------------

	var tail := MeshInstance3D.new()

	var tail_mesh := SphereMesh.new()

	tail_mesh.radius = 0.22
	tail_mesh.height = 0.35

	tail.mesh = tail_mesh

	tail.position = Vector3(
		0,
		0.55,
		0.9
	)

	tail.material_override = _material(
		Color(0.75, 0.65, 0.45)
	)

	player.add_child(tail)


# ============================================================
# DEER EAR
# ============================================================

func _create_deer_ear(
	pos: Vector3,
	angle: float
) -> void:

	var ear := MeshInstance3D.new()

	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		0.18,
		0.55,
		0.08
	)

	ear.mesh = mesh

	ear.position = pos

	ear.rotation_degrees = Vector3(
		0,
		0,
		angle
	)

	ear.material_override = _material(
		Color(0.45, 0.20, 0.08)
	)

	player.add_child(ear)


# ============================================================
# ANTLER
# ============================================================

func _create_antler(pos: Vector3) -> void:

	var antler := Node3D.new()

	antler.position = pos

	player.add_child(antler)

	var main := MeshInstance3D.new()

	var main_mesh := CylinderMesh.new()

	main_mesh.top_radius = 0.04
	main_mesh.bottom_radius = 0.06
	main_mesh.height = 0.65

	main.mesh = main_mesh

	main.position = Vector3(
		0,
		0.28,
		0
	)

	main.rotation_degrees = Vector3(
		-15,
		0,
		0
	)

	main.material_override = _material(
		Color(0.65, 0.48, 0.25)
	)

	antler.add_child(main)


# ============================================================
# DEER LEG
# ============================================================

func _create_deer_leg(pos: Vector3) -> void:

	var leg := MeshInstance3D.new()

	var mesh := CylinderMesh.new()

	mesh.top_radius = 0.13
	mesh.bottom_radius = 0.09
	mesh.height = 1.0

	leg.mesh = mesh

	leg.position = pos

	leg.material_override = _material(
		Color(0.38, 0.18, 0.07)
	)

	player.add_child(leg)


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
		1.5,
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


	# -------------------------
	# SCORE
	# -------------------------

	score_label = Label.new()

	score_label.text = "SCORE  0"

	score_label.position = Vector2(
		20,
		20
	)

	score_label.add_theme_font_size_override(
		"font_size",
		28
	)

	canvas.add_child(score_label)


	# -------------------------
	# COINS
	# -------------------------

	coin_label = Label.new()

	coin_label.text = "COINS  0"

	coin_label.position = Vector2(
		20,
		60
	)

	coin_label.add_theme_font_size_override(
		"font_size",
		24
	)

	canvas.add_child(coin_label)


	# -------------------------
	# GAME OVER
	# -------------------------

	game_over_panel = Control.new()

	game_over_panel.visible = false

	game_over_panel.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	canvas.add_child(game_over_panel)


	var background := ColorRect.new()

	background.color = Color(
		0.02,
		0.02,
		0.02,
		0.82
	)

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	game_over_panel.add_child(background)


	var title := Label.new()

	title.name = "GameOverTitle"

	title.text = "GAME OVER"

	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title.position = Vector2(
		0,
		430
	)

	title.size = Vector2(
		360,
		60
	)

	title.add_theme_font_size_override(
		"font_size",
		34
	)

	game_over_panel.add_child(title)


	# -------------------------
	# RESTART BUTTON
	# -------------------------

	var restart_button := Button.new()

	restart_button.name = "RestartButton"

	restart_button.text = "RESTART"

	restart_button.position = Vector2(
		105,
		510
	)

	restart_button.size = Vector2(
		150,
		65
	)

	restart_button.add_theme_font_size_override(
		"font_size",
		24
	)

	restart_button.pressed.connect(_restart_game)

	game_over_panel.add_child(restart_button)


# ============================================================
# TOUCH / SWIPE
# ============================================================

func _unhandled_input(event: InputEvent) -> void:

	if game_over:
		return


	if event is InputEventScreenTouch:

		if event.pressed:

			touch_start = event.position

			touch_active = true

		else:

			if touch_active:

				var swipe_distance := event.position.x - touch_start.x

				if abs(swipe_distance) > 60:

					if swipe_distance < 0:

						_move_left()

					else:

						_move_right()

			touch_active = false


	# Keyboard testing
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
# PROCESS
# ============================================================

func _process(delta: float) -> void:

	if game_over:
		return


	# Deer movement
	if player:

		player.position.x = lerp(
			player.position.x,
			target_x,
			10.0 * delta
		)

		# Small running movement
		player.position.y = 1.15 + sin(
			Time.get_ticks_msec() * 0.012
		) * 0.06


	# Road
	for road in road_segments:

		road.position.z += forward_speed * delta

		if road.position.z > 15.0:

			road.position.z -= (
				ROAD_LENGTH * ROAD_SEGMENTS
			)


	# Trees
	for tree in trees:

		tree.position.z += forward_speed * delta

		if tree.position.z > 15.0:

			tree.position.z -= 300.0


	# Obstacles
	for obstacle in obstacles:

		if is_instance_valid(obstacle):

			obstacle.position.z += forward_speed * delta

			if obstacle.position.z > 15.0:

				obstacle.queue_free()


	# Coins
	for coin in coins_nodes:

		if is_instance_valid(coin):

			coin.position.z += forward_speed * delta

			coin.rotation.y += 5.0 * delta

			if coin.position.z > 15.0:

				coin.queue_free()


	# Spawn obstacle
	spawn_timer += delta

	if spawn_timer > 1.8:

		spawn_timer = 0.0

		_spawn_obstacle()


	# Spawn coin
	coin_spawn_timer += delta

	if coin_spawn_timer > 1.0:

		coin_spawn_timer = 0.0

		_spawn_coin()


	# Score
	score += int(delta * 10.0)

	score_label.text = "SCORE  " + str(score)

	coin_label.text = "COINS  " + str(coins)


	_check_collisions()


# ============================================================
# COLLISION
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

func _restart_game() -> void:

	get_tree().reload_current_scene()


# ============================================================
# MATERIAL
# ============================================================

func _material(color: Color) -> StandardMaterial3D:

	var material := StandardMaterial3D.new()

	material.albedo_color = color

	material.roughness = 0.75

	return material
