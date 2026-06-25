extends Node2D

enum BirdColor { RED, BLUE, GREEN, YELLOW, PINK, PURPLE, BLACK, WHITE, BROWN }

@export var color: BirdColor = BirdColor.RED:
	set(value):
		color = value
		update_color_visual()
@export var is_selected: bool = false

@onready var sprite = $Sprite2D

var _selection_tween: Tween

func _ready():
	update_color_visual()

func update_color_visual():
	if not is_inside_tree(): return
	match color:
		BirdColor.RED: modulate = Color(1.0, 0.3, 0.3)
		BirdColor.BLUE: modulate = Color(0.3, 0.5, 1.0)
		BirdColor.GREEN: modulate = Color(0.3, 0.8, 0.3)
		BirdColor.YELLOW: modulate = Color(1.0, 0.9, 0.2)
		BirdColor.PINK: modulate = Color(1.0, 0.5, 0.8)
		BirdColor.PURPLE: modulate = Color(0.6, 0.3, 0.9)
		BirdColor.BLACK: modulate = Color(0.2, 0.2, 0.2)
		BirdColor.WHITE: modulate = Color(1.0, 1.0, 1.0)
		BirdColor.BROWN: modulate = Color(0.5, 0.3, 0.1)

func set_selected(selected: bool):
	is_selected = selected
	var target_y = -20 if is_selected else 0
	var target_scale = Vector2(1.2, 1.2) if is_selected else Vector2(1.0, 1.0)

	if _selection_tween:
		_selection_tween.kill()

	_selection_tween = create_tween()
	_selection_tween.set_parallel(true)
	_selection_tween.tween_property(self, "position:y", target_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_selection_tween.tween_property(self, "scale", target_scale, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

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
