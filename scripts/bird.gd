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
		BirdColor.RED: modulate = Color(1.0, 0.35, 0.35)
		BirdColor.BLUE: modulate = Color(0.35, 0.6, 1.0)
		BirdColor.GREEN: modulate = Color(0.4, 0.85, 0.4)
		BirdColor.YELLOW: modulate = Color(1.0, 0.9, 0.3)
		BirdColor.PINK: modulate = Color(1.0, 0.4, 0.75)
		BirdColor.ORANGE: modulate = Color(1.0, 0.7, 0.2)

func set_selected(selected: bool):
	is_selected = selected
	var target_y = -20 if is_selected else 0
	var target_scale = Vector2(1.2, 1.2) if is_selected else Vector2(1.0, 1.0)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", target_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
