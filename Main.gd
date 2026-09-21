extends Node2D

@export var bubble_scene: PackedScene = preload("res://Bubble.tscn")
@onready var launcher_position = $LauncherPosition
@onready var score_label = $UI/ScoreLabel
@onready var background_sprite = $Background

var current_bubble: Area2D = null
var score: int = 0
var grid_rows: int = 5
var grid_cols: int = 10
var bubble_radius: float = 32.0

func _ready() -> void:
	randomize()
	setup_background()
	spawn_initial_grid()
	prepare_next_bubble()

func setup_background() -> void:
	if background_sprite and background_sprite.texture:
		var tex_size = background_sprite.texture.get_size()
		background_sprite.scale = Vector2(720.0 / tex_size.x, 1280.0 / tex_size.y)
		background_sprite.position = Vector2(360, 640)

func spawn_initial_grid() -> void:
	for row in range(grid_rows):
		for col in range(grid_cols):
			var b = bubble_scene.instantiate()
			var x_offset = (row % 2) * bubble_radius
			var x_pos = 68 + col * (bubble_radius * 2) + x_offset
			var y_pos = 68 + row * (bubble_radius * 1.8)
			
			b.position = Vector2(x_pos, y_pos)
			b.set_color(randi() % 4)
			b.velocity = Vector2.ZERO
			add_child(b)

func prepare_next_bubble() -> void:
	current_bubble = bubble_scene.instantiate()
	current_bubble.position = launcher_position.position
	current_bubble.set_color(randi() % 4)
	current_bubble.connect("bubble_popped", Callable(self, "_on_bubble_landed"))
	add_child(current_bubble)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if current_bubble and current_bubble.velocity == Vector2.ZERO:
			var touch_pos = event.position
			if touch_pos.y < launcher_position.position.y - 30: # Aim upward
				var dir = (touch_pos - launcher_position.position).normalized()
				current_bubble.launch(dir)

func _on_bubble_landed(shot_bubble: Area2D) -> void:
	# Snap to nearest grid row & column
	shot_bubble.position.x = round((shot_bubble.position.x - 36.0) / 64.0) * 64.0 + 36.0
	shot_bubble.position.y = round((shot_bubble.position.y - 36.0) / 57.6) * 57.6 + 36.0
	
	check_matches(shot_bubble)
	prepare_next_bubble()

func check_matches(start_bubble: Area2D) -> void:
	var target_color = start_bubble.color_type
	var matched: Array = []
	var queue: Array = [start_bubble]
	
	while queue.size() > 0:
		var current = queue.pop_front()
		if not matched.has(current):
			matched.append(current)
			
			for b in get_tree().get_nodes_in_group("bubbles"):
				if not matched.has(b) and b.velocity == Vector2.ZERO:
					if b.color_type == target_color:
						if current.position.distance_to(b.position) <= 75.0:
							queue.append(b)
							
	if matched.size() >= 3:
		for b in matched:
			b.queue_free()
		score += matched.size() * 10
		score_label.text = "Score: " + str(score)
