extends Node3D

# ============================================================
# DEER RUNNER 3D
# Godot 4.3
# ============================================================

var deer: Node3D
var camera: Camera3D

var current_lane: int = 0
var target_x: float = 0.0

const LANE_WIDTH := 3.0
const PLAYER_Z := 3.0
const PLAYER_Y := 1.2

var speed: float = 12.0

var score: int = 0
var coin_count: int = 0
var game_over: bool = false

var roads: Array[Node3D] = []
var trees: Array[Node3D] = []
var obstacles: Array[Node3D] = []
var coins: Array[Node3D] = []

var score_label: Label
var coin_label: Label
var game_over_box: Control

var obstacle_timer: float = 0.0
var coin_timer: float = 0.0

var touch_start := Vector2.ZERO
var touching := false

const ROAD_SEGMENT_LENGTH := 20.0
const ROAD_SEGMENTS := 16


func _ready() -> void:
	_setup_world()
	_setup_camera()
	_create_road()
	_create_environment_objects()
	_create_deer()
	_create_ui()


# ============================================================
# WORLD
# ============================================================

func _setup_world() -> void:

	var environment := Environment.new()

	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.38, 0.68, 0.92)

	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(1.0, 1.0, 1.0)
	environment.ambient_light_energy = 1.0

	var world := WorldEnvironment.new()
	world.environment = environment

	add_child(world)

	var sun := DirectionalLight3D.new()

	sun.rotation_degrees = Vector3(-55.0, -30.0, 0.0)
	sun.light_energy = 1.4
	sun.shadow_enabled = true

	add_child(sun)


# ============================================================
# CAMERA
# ============================================================

func _setup_camera() -> void:

	camera = Camera3D.new()

	camera.position = Vector3(0.0, 5.2, 10.5)

	camera.rotation_degrees = Vector3(
		-13.0,
		0.0,
		0.0
	)

	camera.fov = 65.0
	camera.current = true

	add_child(camera)


# ============================================================
# ROAD
# ============================================================

func _create_road() -> void:

	# Grass

	var grass := MeshInstance3D.new()

	var grass_mesh := BoxMesh.new()
	grass_mesh.size = Vector3(
		35.0,
		0.3,
		350.0
	)

	grass.mesh = grass_mesh
	grass.position = Vector3(
		0.0,
		-0.3,
		-160.0
	)

	grass.material_override = _mat(
		Color(0.10, 0.42, 0.14)
	)

	add_child(grass)


	# Road segments

	for i in range(ROAD_SEGMENTS):

		var road := Node3D.new()

		var road_mesh := BoxMesh.new()

		road_mesh.size = Vector3(
			10.0,
			0.25,
			ROAD_SEGMENT_LENGTH
		)

		var road_piece := MeshInstance3D.new()

		road_piece.mesh = road_mesh

		road_piece.material_override = _mat(
			Color(0.08, 0.09, 0.10)
		)

		road.add_child(road_piece)

		road.position = Vector3(
			0.0,
			0.0,
			-i * ROAD_SEGMENT_LENGTH
		)

		add_child(road)

		roads.append(road)


	# Lane lines

	for i in range(ROAD_SEGMENTS):

		var z := -float(i) * ROAD_SEGMENT_LENGTH

		_create_lane_line(
			Vector3(-1.5, 0.16, z)
		)

		_create_lane_line(
			Vector3(1.5, 0.16, z)
		)


	# Road edges

	_create_edge(-5.1)
	_create_edge(5.1)


func _create_lane_line(pos: Vector3) -> void:

	var line := MeshInstance3D.new()

	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		0.08,
		0.05,
		8.0
	)

	line.mesh = mesh
	line.position = pos

	line.material_override = _mat(
		Color(0.9, 0.9, 0.75)
	)

	add_child(line)


func _create_edge(x: float) -> void:

	var edge := MeshInstance3D.new()

	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		0.25,
		0.7,
		320.0
	)

	edge.mesh = mesh

	edge.position = Vector3(
		x,
		0.3,
		-150.0
	)

	edge.material_override = _mat(
		Color(0.55, 0.55, 0.55)
	)

	add_child(edge)


# ============================================================
# TREES
# ============================================================

func _create_environment_objects() -> void:

	for i in range(30):

		var z := -float(i) * 11.0

		_create_tree(-8.0, z)
		_create_tree(8.0, z - 5.0)


func _create_tree(x: float, z: float) -> void:

	var tree := Node3D.new()

	tree.position = Vector3(
		x,
		0.0,
		z
	)

	add_child(tree)


	# trunk

	var trunk := MeshInstance3D.new()

	var trunk_mesh := CylinderMesh.new()

	trunk_mesh.top_radius = 0.22
	trunk_mesh.bottom_radius = 0.32
	trunk_mesh.height = 2.8

	trunk.mesh = trunk_mesh

	trunk.position.y = 1.4

	trunk.material_override = _mat(
		Color(0.30, 0.16, 0.07)
	)

	tree.add_child(trunk)


	# leaves

	var leaves := MeshInstance3D.new()

	var leaves_mesh := SphereMesh.new()

	leaves_mesh.radius = 1.4
	leaves_mesh.height = 2.8

	leaves.mesh = leaves_mesh

	leaves.position.y = 3.2

	leaves.material_override = _mat(
		Color(0.04, 0.32, 0.08)
	)

	tree.add_child(leaves)

	trees.append(tree)


# ============================================================
# DEER
# ============================================================

func _create_deer() -> void:

	deer = Node3D.new()

	deer.name = "Deer"

	deer.position = Vector3(
		0.0,
		PLAYER_Y,
		PLAYER_Z
	)

	add_child(deer)


	# BODY

	var body := MeshInstance3D.new()

	var body_mesh := CapsuleMesh.new()

	body_mesh.radius = 0.58
	body_mesh.height = 1.9

	body.mesh = body_mesh

	body.rotation_degrees = Vector3(
		0.0,
		0.0,
		90.0
	)

	body.position = Vector3(
		0.0,
		0.0,
		0.0
	)

	body.material_override = _mat(
		Color(0.50, 0.27, 0.11)
	)

	deer.add_child(body)


	# CHEST

	var chest := MeshInstance3D.new()

	var chest_mesh := SphereMesh.new()

	chest_mesh.radius = 0.55
	chest_mesh.height = 1.1

	chest.mesh = chest_mesh

	chest.position = Vector3(
		0.0,
		0.05,
		-0.55
	)

	chest.scale = Vector3(
		1.0,
		1.25,
		1.0
	)

	chest.material_override = _mat(
		Color(0.52, 0.29, 0.12)
	)

	deer.add_child(chest)


	# NECK

	var neck := MeshInstance3D.new()

	var neck_mesh := CylinderMesh.new()

	neck_mesh.top_radius = 0.25
	neck_mesh.bottom_radius = 0.38
	neck_mesh.height = 1.35

	neck.mesh = neck_mesh

	neck.position = Vector3(
		0.0,
		0.82,
		-0.62
	)

	neck.rotation_degrees = Vector3(
		-18.0,
		0.0,
		0.0
	)

	neck.material_override = _mat(
		Color(0.50, 0.27, 0.11)
	)

	deer.add_child(neck)


	# HEAD

	var head := MeshInstance3D.new()

	var head_mesh := SphereMesh.new()

	head_mesh.radius = 0.43
	head_mesh.height = 0.78

	head.mesh = head_mesh

	head.position = Vector3(
		0.0,
		1.42,
		-1.02
	)

	head.material_override = _mat(
		Color(0.54, 0.30, 0.13)
	)

	deer.add_child(head)


	# MUZZLE

	var muzzle := MeshInstance3D.new()

	var muzzle_mesh := SphereMesh.new()

	muzzle_mesh.radius = 0.25
	muzzle_mesh.height = 0.40

	muzzle.mesh = muzzle_mesh

	muzzle.position = Vector3(
		0.0,
		1.30,
		-1.36
	)

	muzzle.material_override = _mat(
		Color(0.30, 0.14, 0.06)
	)

	deer.add_child(muzzle)


	# EARS

	_create_ear(
		Vector3(-0.30, 1.70, -0.95),
		-25.0
	)

	_create_ear(
		Vector3(0.30, 1.70, -0.95),
		25.0
	)


	# ANTLERS

	_create_antler(
		Vector3(-0.22, 1.78, -0.95)
	)

	_create_antler(
		Vector3(0.22, 1.78, -0.95)
	)


	# LEGS

	_create_leg(
		Vector3(-0.38, -0.70, -0.38)
	)

	_create_leg(
		Vector3(0.38, -0.70, -0.38)
	)

	_create_leg(
		Vector3(-0.38, -0.70, 0.38)
	)

	_create_leg(
		Vector3(0.38, -0.70, 0.38)
	)


	# TAIL

	var tail := MeshInstance3D.new()

	var tail_mesh := SphereMesh.new()

	tail_mesh.radius = 0.24
	tail_mesh.height = 0.38

	tail.mesh = tail_mesh

	tail.position = Vector3(
		0.0,
		0.55,
		0.95
	)

	tail.material_override = _mat(
		Color(0.80, 0.70, 0.52)
	)

	deer.add_child(tail)


func _create_ear(pos: Vector3, angle: float) -> void:

	var ear := MeshInstance3D.new()

	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		0.18,
		0.55,
		0.10
	)

	ear.mesh = mesh

	ear.position = pos

	ear.rotation_degrees = Vector3(
		0.0,
		0.0,
		angle
	)

	ear.material_override = _mat(
		Color(0.43, 0.19, 0.07)
	)

	deer.add_child(ear)


func _create_antler(pos: Vector3) -> void:

	var antler := Node3D.new()

	antler.position = pos

	deer.add_child(antler)


	var main := MeshInstance3D.new()

	var mesh := CylinderMesh.new()

	mesh.top_radius = 0.035
	mesh.bottom_radius = 0.065
	mesh.height = 0.75

	main.mesh = mesh

	main.position.y = 0.35

	main.rotation_degrees = Vector3(
		-12.0,
		0.0,
		0.0
	)

	main.material_override = _mat(
		Color(0.62, 0.45, 0.22)
	)

	antler.add_child(main)


	# antler branches

	var branch := MeshInstance3D.new()

	var branch_mesh := CylinderMesh.new()

	branch_mesh.top_radius = 0.025
	branch_mesh.bottom_radius = 0.045
	branch_mesh.height = 0.35

	branch.mesh = branch_mesh

	branch.position = Vector3(
		0.0,
		0.48,
		0.0
	)

	branch.rotation_degrees = Vector3(
		0.0,
		0.0,
		-45.0
	)

	branch.material_override = _mat(
		Color(0.62, 0.45, 0.22)
	)

	antler.add_child(branch)


func _create_leg(pos: Vector3) -> void:

	var leg := MeshInstance3D.new()

	var mesh := CylinderMesh.new()

	mesh.top_radius = 0.13
	mesh.bottom_radius = 0.09
	mesh.height = 1.05

	leg.mesh = mesh

	leg.position = pos

	leg.material_override = _mat(
		Color(0.37, 0.17, 0.06)
	)

	deer.add_child(leg)


# ============================================================
# OBSTACLE
# ============================================================

func _spawn_obstacle() -> void:

	var obstacle := Node3D.new()

	var lane := randi_range(-1, 1)

	obstacle.position = Vector3(
		lane * LANE_WIDTH,
		0.9,
		-120.0
	)

	add_child(obstacle)


	var block := MeshInstance3D.new()

	var mesh := BoxMesh.new()

	mesh.size = Vector3(
		1.8,
		1.8,
		1.5
	)

	block.mesh = mesh

	block.material_override = _mat(
		Color(0.80, 0.08, 0.06)
	)

	obstacle.add_child(block)


	# yellow stripe

	var stripe := MeshInstance3D.new()

	var stripe_mesh := BoxMesh.new()

	stripe_mesh.size = Vector3(
		1.9,
		0.22,
		1.55
	)

	stripe.mesh = stripe_mesh

	stripe.position.y = 0.25

	stripe.material_override = _mat(
		Color(1.0, 0.72, 0.05)
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
		lane * LANE_WIDTH,
		1.5,
		-120.0
	)

	add_child(coin)


	var coin_mesh := MeshInstance3D.new()

	var mesh := CylinderMesh.new()

	mesh.top_radius = 0.45
	mesh.bottom_radius = 0.45
	mesh.height = 0.14

	coin_mesh.mesh = mesh

	coin_mesh.rotation_degrees = Vector3(
		90.0,
		0.0,
		0.0
	)

	coin_mesh.material_override = _mat(
		Color(1.0, 0.72, 0.05)
	)

	coin.add_child(coin_mesh)

	coins.append(coin)


# ============================================================
# UI
# ============================================================

func _create_ui() -> void:

	var canvas := CanvasLayer.new()

	add_child(canvas)


	score_label = Label.new()

	score_label.text = "SCORE  0"

	score_label.position = Vector2(
		20.0,
		20.0
	)

	score_label.add_theme_font_size_override(
		"font_size",
		28
	)

	canvas.add_child(score_label)


	coin_label = Label.new()

	coin_label.text = "COINS  0"

	coin_label.position = Vector2(
		20.0,
		60.0
	)

	coin_label.add_theme_font_size_override(
		"font_size",
		24
	)

	canvas.add_child(coin_label)


	# GAME OVER

	game_over_box = Control.new()

	game_over_box.visible = false

	game_over_box.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	canvas.add_child(game_over_box)


	var dark := ColorRect.new()

	dark.color = Color(
		0.0,
		0.0,
		0.0,
		0.80
	)

	dark.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	game_over_box.add_child(dark)


	var title := Label.new()

	title.text = "GAME OVER"

	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	title.position = Vector2(
		0.0,
		400.0
	)

	title.size = Vector2(
		360.0,
		70.0
	)

	title.add_theme_font_size_override(
		"font_size",
		36
	)

	game_over_box.add_child(title)


	var restart := Button.new()

	restart.text = "RESTART"

	restart.position = Vector2(
		95.0,
		500.0
	)

	restart.size = Vector2(
		170.0,
		65.0
	)

	restart.add_theme_font_size_override(
		"font_size",
		24
	)

	restart.pressed.connect(
		_restart_game
	)

	game_over_box.add_child(restart)


# ============================================================
# TOUCH / KEYBOARD
# ============================================================

func _unhandled_input(event: InputEvent) -> void:

	if game_over:
		return


	if event is InputEventScreenTouch:

		if event.pressed:

			touch_start = event.position

			touching = true

		else:

			if touching:

				var distance := (
					event.position.x -
					touch_start.x
				)

				if abs(distance) > 50.0:

					if distance < 0.0:
						_move_left()
					else:
						_move_right()

			touching = false


	if event is InputEventKey:

		if event.pressed:

			if event.keycode == KEY_LEFT:
				_move_left()

			elif event.keycode == KEY_RIGHT:
				_move_right()


func _move_left() -> void:

	if game_over:
		return

	current_lane -= 1

	current_lane = clamp(
		current_lane,
		-1,
		1
	)

	target_x = current_lane * LANE_WIDTH


func _move_right() -> void:

	if game_over:
		return

	current_lane += 1

	current_lane = clamp(
		current_lane,
		-1,
		1
	)

	target_x = current_lane * LANE_WIDTH


# ============================================================
# GAME LOOP
# ============================================================

func _process(delta: float) -> void:

	if game_over:
		return


	# Deer movement

	if deer:

		deer.position.x = lerp(
			deer.position.x,
			target_x,
			10.0 * delta
		)

		deer.position.y = (
			PLAYER_Y +
			sin(Time.get_ticks_msec() * 0.012) * 0.05
		)


	# Road movement

	for road in roads:

		if not is_instance_valid(road):
			continue

		road.position.z += speed * delta

		if road.position.z > 20.0:

			road.position.z -= (
				ROAD_SEGMENT_LENGTH *
				ROAD_SEGMENTS
			)


	# Trees

	for tree in trees:

		if not is_instance_valid(tree):
			continue

		tree.position.z += speed * delta

		if tree.position.z > 20.0:

			tree.position.z -= 330.0


	# Obstacles

	for obstacle in obstacles:

		if not is_instance_valid(obstacle):
			continue

		obstacle.position.z += speed * delta

		if obstacle.position.z > 20.0:

			obstacle.queue_free()


	# Coins

	for coin in coins:

		if not is_instance_valid(coin):
			continue

		coin.position.z += speed * delta

		coin.rotation.y += 5.0 * delta

		if coin.position.z > 20.0:

			coin.queue_free()


	# Spawn obstacle

	obstacle_timer += delta

	if obstacle_timer >= 1.7:

		obstacle_timer = 0.0

		_spawn_obstacle()


	# Spawn coins

	coin_timer += delta

	if coin_timer >= 0.8:

		coin_timer = 0.0

		_spawn_coin()


	# Score

	score += int(delta * 10.0)

	score_label.text = (
		"SCORE  " +
		str(score)
	)

	coin_label.text = (
		"COINS  " +
		str(coin_count)
	)


	_check_collisions()


# ============================================================
# COLLISION
# ============================================================

func _check_collisions() -> void:

	if deer == null:
		return


	for obstacle in obstacles:

		if not is_instance_valid(obstacle):
			continue

		var distance := (
			deer.global_position.distance_to(
				obstacle.global_position
			)
		)

		if distance < 1.55:

			_game_over()

			return


	for coin in coins:

		if not is_instance_valid(coin):
			continue

		var distance := (
			deer.global_position.distance_to(
				coin.global_position
			)
		)

		if distance < 1.30:

			coin_count += 1

			coin.queue_free()


# ============================================================
# GAME OVER
# ============================================================

func _game_over() -> void:

	game_over = true

	game_over_box.visible = true


func _restart_game() -> void:

	get_tree().reload_current_scene()


# ============================================================
# MATERIAL
# ============================================================

func _mat(color: Color) -> StandardMaterial3D:

	var material := StandardMaterial3D.new()

	material.albedo_color = color

	material.roughness = 0.75

	return material
