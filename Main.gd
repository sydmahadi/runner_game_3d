extends Node2D

const WIDTH := 720.0
const HEIGHT := 1280.0

const BUBBLE_RADIUS := 30.0
const ROW_HEIGHT := 52.0
const COL_WIDTH := 60.0

const BOARD_TOP := 150.0
const BOARD_LEFT := 30.0
const BOARD_RIGHT := 690.0

const COLORS := [
	Color("#E53935"),
	Color("#1E88E5"),
	Color("#43A047"),
	Color("#FDD835"),
	Color("#8E24AA"),
	Color("#FB8C00")
]

var board: Array = []

var shooter_position := Vector2(360, 1080)
var shooter_angle := -PI / 2

var current_color := 0
var next_color := 0

var score := 0
var level := 1

var moving_bubble = null
var game_over := false

var background_texture: Texture2D

var score_label: Label
var level_label: Label
var next_label: Label
var game_over_panel: ColorRect
var game_over_label: Label


func _ready():
	randomize()

	load_background()

	create_ui()

	create_board()

	current_color = randi() % COLORS.size()
	next_color = randi() % COLORS.size()

	queue_redraw()


func load_background():
	if ResourceLoader.exists("res://background.jpg"):
		background_texture = load("res://background.jpg")


func create_ui():

	score_label = Label.new()

	score_label.position = Vector2(30, 30)
	score_label.size = Vector2(300, 60)

	score_label.text = "Score: 0"

	score_label.add_theme_font_size_override(
		"font_size",
		32
	)

	add_child(score_label)


	level_label = Label.new()

	level_label.position = Vector2(500, 30)
	level_label.size = Vector2(180, 60)

	level_label.text = "Level: 1"

	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	level_label.add_theme_font_size_override(
		"font_size",
		28
	)

	add_child(level_label)


	next_label = Label.new()

	next_label.position = Vector2(560, 1080)
	next_label.size = Vector2(120, 50)

	next_label.text = "NEXT"

	next_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	next_label.add_theme_font_size_override(
		"font_size",
		20
	)

	add_child(next_label)


func create_board():

	board.clear()

	for row in range(7):

		var row_data: Array = []

		for col in range(11):

			var color_index = randi() % COLORS.size()

			row_data.append(color_index)

		board.append(row_data)


func _draw():

	# Background
	if background_texture:
		draw_texture_rect(
			background_texture,
			Rect2(0, 0, WIDTH, HEIGHT),
			false
		)
	else:
		draw_rect(
			Rect2(0, 0, WIDTH, HEIGHT),
			Color("#101827")
		)

	# Dark transparent game board
	draw_rect(
		Rect2(
			BOARD_LEFT,
			BOARD_TOP,
			BOARD_RIGHT - BOARD_LEFT,
			700
		),
		Color(0, 0, 0, 0.55)
	)

	# Bubbles
	for row in range(board.size()):

		for col in range(board[row].size()):

			var color_index = board[row][col]

			if color_index < 0:
				continue

			var pos = get_bubble_position(row, col)

			draw_bubble(
				pos,
				COLORS[color_index]
			)

	# Shooter
	draw_circle(
		shooter_position,
		48,
		Color(0.05, 0.05, 0.05, 0.9)
	)

	draw_circle(
		shooter_position,
		35,
		COLORS[current_color]
	)

	# Aim line
	var direction = Vector2(
		cos(shooter_angle),
		sin(shooter_angle)
	)

	var end_position = shooter_position + direction * 250

	draw_dashed_line(
		shooter_position,
		end_position,
		Color(1, 1, 1, 0.65),
		4,
		10
	)

	# Next bubble
	draw_circle(
		Vector2(620, 1130),
		28,
		COLORS[next_color]
	)


func draw_bubble(pos: Vector2, color: Color):

	draw_circle(
		pos + Vector2(3, 5),
		BUBBLE_RADIUS,
		Color(0, 0, 0, 0.45)
	)

	draw_circle(
		pos,
		BUBBLE_RADIUS,
		color
	)

	draw_circle(
		pos - Vector2(9, 9),
		8,
		Color(1, 1, 1, 0.45)
	)


func get_bubble_position(row: int, col: int) -> Vector2:

	var x = BOARD_LEFT + 30 + col * COL_WIDTH

	if row % 2 == 1:
		x += COL_WIDTH / 2

	var y = BOARD_TOP + 35 + row * ROW_HEIGHT

	return Vector2(x, y)


func _process(delta):

	if moving_bubble != null:

		moving_bubble["position"] += \
			moving_bubble["velocity"] * delta

		var pos: Vector2 = moving_bubble["position"]

		if pos.x < BUBBLE_RADIUS:
			pos.x = BUBBLE_RADIUS
			moving_bubble["velocity"].x *= -1

		if pos.x > WIDTH - BUBBLE_RADIUS:
			pos.x = WIDTH - BUBBLE_RADIUS
			moving_bubble["velocity"].x *= -1

		moving_bubble["position"] = pos

		if pos.y <= BOARD_TOP + BUBBLE_RADIUS:

			place_moving_bubble()

		else:

			check_collision()

		queue_redraw()


func _input(event):

	if game_over:
		return

	if event is InputEventScreenTouch:

		if event.pressed:

			aim_at(event.position)

			if moving_bubble == null:
				shoot()

	if event is InputEventScreenDrag:

		aim_at(event.position)

	if event is InputEventMouseButton:

		if event.pressed:

			aim_at(event.position)

			if moving_bubble == null:
				shoot()


func aim_at(pos: Vector2):

	var direction = pos - shooter_position

	if direction.y >= -30:
		return

	shooter_angle = direction.angle()

	shooter_angle = clamp(
		shooter_angle,
		-PI + 0.25,
		-0.25
	)

	queue_redraw()


func shoot():

	if moving_bubble != null:
		return

	var direction = Vector2(
		cos(shooter_angle),
		sin(shooter_angle)
	)

	moving_bubble = {
		"position": shooter_position,
		"velocity": direction * 850.0,
		"color": current_color
	}

	current_color = next_color

	next_color = randi() % COLORS.size()

	queue_redraw()


func check_collision():

	if moving_bubble == null:
		return

	var pos: Vector2 = moving_bubble["position"]

	for row in range(board.size()):

		for col in range(board[row].size()):

			if board[row][col] < 0:
				continue

			var bubble_pos = get_bubble_position(row, col)

			if pos.distance_to(bubble_pos) < BUBBLE_RADIUS * 1.9:

				place_moving_bubble()

				return


func place_moving_bubble():

	if moving_bubble == null:
		return

	var pos: Vector2 = moving_bubble["position"]

	var best_row := 0
	var best_col := 0

	var best_distance := INF

	for row in range(board.size()):

		for col in range(board[row].size()):

			var bubble_pos = get_bubble_position(row, col)

			var distance = pos.distance_to(bubble_pos)

			if distance < best_distance:

				best_distance = distance

				best_row = row
				best_col = col

	if best_row >= board.size():
		best_row = board.size() - 1

	if best_col >= board[best_row].size():
		best_col = board[best_row].size() - 1

	board[best_row][best_col] = moving_bubble["color"]

	moving_bubble = null

	check_matches(
		best_row,
		best_col
	)

	update_score()

	check_game_over()

	queue_redraw()


func check_matches(start_row: int, start_col: int):

	var target_color = board[start_row][start_col]

	var visited := {}

	var queue: Array = []

	queue.append(
		Vector2i(start_row, start_col)
	)

	var matches: Array = []

	while queue.size() > 0:

		var cell: Vector2i = queue.pop_front()

		var key = str(cell.x) + ":" + str(cell.y)

		if visited.has(key):
			continue

		visited[key] = true

		if cell.x < 0:
			continue

		if cell.x >= board.size():
			continue

		if cell.y < 0:
			continue

		if cell.y >= board[cell.x].size():
			continue

		if board[cell.x][cell.y] != target_color:
			continue

		matches.append(cell)

		var neighbors = [
			Vector2i(cell.x + 1, cell.y),
			Vector2i(cell.x - 1, cell.y),
			Vector2i(cell.x, cell.y + 1),
			Vector2i(cell.x, cell.y - 1)
		]

		for n in neighbors:
			queue.append(n)

	if matches.size() >= 3:

		for cell in matches:

			board[cell.x][cell.y] = -1

		score += matches.size() * 10

		level = 1 + int(score / 200)


func update_score():

	score_label.text = "Score: " + str(score)

	level_label.text = "Level: " + str(level)


func check_game_over():

	for col in range(board[0].size()):

		if board[board.size() - 1][col] >= 0:

			show_game_over()

			return


func show_game_over():

	game_over = true

	game_over_panel = ColorRect.new()

	game_over_panel.color = Color(0, 0, 0, 0.8)

	game_over_panel.position = Vector2(70, 400)
	game_over_panel.size = Vector2(580, 400)

	add_child(game_over_panel)

	game_over_label = Label.new()

	game_over_label.text = \
		"GAME OVER\n\nScore: " + str(score)

	game_over_label.position = Vector2(100, 460)
	game_over_label.size = Vector2(520, 150)

	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	game_over_label.add_theme_font_size_override(
		"font_size",
		40
	)

	add_child(game_over_label)

	var restart = Button.new()

	restart.text = "RESTART"

	restart.position = Vector2(200, 650)
	restart.size = Vector2(320, 90)

	restart.add_theme_font_size_override(
		"font_size",
		30
	)

	restart.pressed.connect(restart_game)

	add_child(restart)


func restart_game():

	get_tree().reload_current_scene()
