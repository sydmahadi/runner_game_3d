extends Node2D

var title_label: Label
var message_label: Label
var start_button: Button


func _ready():
	create_background()
	create_title()
	create_message()
	create_start_button()


func create_background():
	var background = ColorRect.new()

	background.color = Color("#06130F")

	background.set_anchors_preset(Control.PRESET_FULL_RECT)

	background.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(background)


func create_title():
	title_label = Label.new()

	title_label.text = "DEER RUNNER 3D"

	title_label.position = Vector2(0, 250)
	title_label.size = Vector2(720, 80)

	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	title_label.add_theme_font_size_override(
		"font_size",
		48
	)

	title_label.add_theme_color_override(
		"font_color",
		Color("#E4C987")
	)

	add_child(title_label)


func create_message():
	message_label = Label.new()

	message_label.text = "GAME SCREEN WORKING"

	message_label.position = Vector2(0, 350)
	message_label.size = Vector2(720, 60)

	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	message_label.add_theme_font_size_override(
		"font_size",
		28
	)

	message_label.add_theme_color_override(
		"font_color",
		Color.WHITE
	)

	add_child(message_label)


func create_start_button():
	start_button = Button.new()

	start_button.text = "START GAME"

	start_button.position = Vector2(160, 500)
	start_button.size = Vector2(400, 100)

	start_button.add_theme_font_size_override(
		"font_size",
		30
	)

	start_button.pressed.connect(start_game)

	add_child(start_button)


func start_game():
	message_label.text = "GAME STARTED!"

	start_button.text = "RESTART"

	print("Game started")
