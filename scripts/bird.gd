extends Node2D

enum BirdColor { RED, BLUE, GREEN, YELLOW, PINK, ORANGE }

@export var color: BirdColor = BirdColor.RED
@export var is_selected: bool = false

@onready var sprite = $Sprite2D

func _ready():
	update_color_visual()

func update_color_visual():
	if not is_inside_tree(): return
	match color:
		BirdColor.RED: modulate = Color.RED
		BirdColor.BLUE: modulate = Color.BLUE
		BirdColor.GREEN: modulate = Color.GREEN
		BirdColor.YELLOW: modulate = Color.YELLOW
		BirdColor.PINK: modulate = Color.DEEP_PINK
		BirdColor.ORANGE: modulate = Color.ORANGE

func set_selected(selected: bool):
	is_selected = selected
	if is_selected:
		# Simple jump up animation
		scale = Vector2(1.2, 1.2)
		position.y -= 20
	else:
		scale = Vector2(1.0, 1.0)
		position.y += 20 # Reset position

func move_to(target_position: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "position", target_position, 0.3).set_trans(Tween.TRANS_SINE)
	await tween.finished

func fly_away():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 1000, 1.0).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	await tween.finished
	queue_free()
