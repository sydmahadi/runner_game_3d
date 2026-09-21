extends Area2D

signal bubble_popped(bubble)

@export var speed: float = 900.0
var velocity: Vector2 = Vector2.ZERO
var color_type: int = 0

# 4-color palette
const COLORS = [
	Color("#FF4D6D"), # Red / Pink
	Color("#00B4D8"), # Blue
	Color("#FFB703"), # Yellow / Gold
	Color("#38B000")  # Green
]

func _ready() -> void:
	add_to_group("bubbles")
	connect("area_entered", Callable(self, "_on_area_entered"))

func set_color(type: int) -> void:
	color_type = type
	modulate = COLORS[color_type % COLORS.size()]

func launch(dir: Vector2) -> void:
	velocity = dir.normalized() * speed

func _process(delta: float) -> void:
	if velocity != Vector2.ZERO:
		position += velocity * delta
		
		# Wall Bouncing (Left & Right)
		if position.x <= 36:
			velocity.x = abs(velocity.x)
			position.x = 36
		elif position.x >= 684:
			velocity.x = -abs(velocity.x)
			position.x = 684
		
		# Top Ceiling Collision
		if position.y <= 36:
			velocity = Vector2.ZERO
			emit_signal("bubble_popped", self)

func _on_area_entered(area: Area2D) -> void:
	if velocity != Vector2.ZERO and area.is_in_group("bubbles") and area != self:
		if area.velocity == Vector2.ZERO: # Collided with a stationary grid bubble
			velocity = Vector2.ZERO
			emit_signal("bubble_popped", self)
