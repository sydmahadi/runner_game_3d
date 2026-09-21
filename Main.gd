extends Node2D

func _ready():
	var background = ColorRect.new()
	background.color = Color("#10291f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var title = Label.new()
	title.text = "DEER RUNNER 3D"
	title.position = Vector2(35, 220)
	title.size = Vector2(650, 100)
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", Color("#e4c987"))
	add_child(title)

	var message = Label.new()
	message.text = "GAME SCREEN WORKING"
	message.position = Vector2(55, 340)
	message.size = Vector2(600, 80)
	message.add_theme_font_size_override("font_size", 28)
	message.add_theme_color_override("font_color", Color.WHITE)
	add_child(message)

	var button = Button.new()
	button.text = "START GAME"
	button.position = Vector2(180, 500)
	button.size = Vector2(360, 90)
	button.add_theme_font_size_override("font_size", 28)
	button.pressed.connect(_start_game)
	add_child(button)

func _start_game():
	get_tree().reload_current_scene()
