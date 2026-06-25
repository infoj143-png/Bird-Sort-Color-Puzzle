extends Node2D

enum BirdColor { RED, BLUE, GREEN, YELLOW, PINK, PURPLE, BLACK, WHITE, BROWN }

@export var color: BirdColor = BirdColor.RED:
	set(value):
		color = value
		update_color_visual()
@export var is_selected: bool = false

@onready var visuals = $Visuals
@onready var body = $Visuals/Body
@onready var wing = $Visuals/Wing
@onready var eye = $Visuals/Eye
@onready var tail = $Visuals/Tail
@onready var feet = $Visuals/Feet
@onready var shadow = $Shadow

var _selection_tween: Tween
var _idle_tween: Tween
var _blink_timer: float = 0.0

func _ready():
	update_color_visual()
	start_idle_animation()
	_blink_timer = randf_range(2.0, 5.0)

func _process(delta):
	_blink_timer -= delta
	if _blink_timer <= 0:
		play_blink()
		_blink_timer = randf_range(2.0, 5.0)

func update_color_visual():
	if not is_inside_tree(): return
	var modulate_color = Color.WHITE
	match color:
		BirdColor.RED: modulate_color = Color("#ff5e5e")
		BirdColor.BLUE: modulate_color = Color("#5e97ff")
		BirdColor.GREEN: modulate_color = Color("#5eff8a")
		BirdColor.YELLOW: modulate_color = Color("#ffea5e")
		BirdColor.PINK: modulate_color = Color("#ff96e2")
		BirdColor.PURPLE: modulate_color = Color("#b096ff")
		BirdColor.BLACK: modulate_color = Color("#4a4a4a")
		BirdColor.WHITE: modulate_color = Color("#f0f0f0")
		BirdColor.BROWN: modulate_color = Color("#a67c52")

	body.self_modulate = modulate_color
	wing.self_modulate = modulate_color
	tail.self_modulate = modulate_color

func start_idle_animation():
	if _idle_tween:
		_idle_tween.kill()

	_idle_tween = create_tween().set_loops()
	_idle_tween.set_parallel(true)

	# Breathing scale
	_idle_tween.tween_property(visuals, "scale:y", 1.05, 1.5).set_trans(Tween.TRANS_SINE)
	_idle_tween.chain().tween_property(visuals, "scale:y", 1.0, 1.5).set_trans(Tween.TRANS_SINE)

	# Subtle rotation
	_idle_tween.tween_property(visuals, "rotation_degrees", 2.0, 2.0).set_trans(Tween.TRANS_SINE)
	_idle_tween.chain().tween_property(visuals, "rotation_degrees", -2.0, 2.0).set_trans(Tween.TRANS_SINE)

	_idle_tween.custom_step(randf() * 5.0)

func play_blink():
	var tween = create_tween()
	tween.tween_property(eye, "scale:y", 0.05, 0.1)
	tween.tween_property(eye, "scale:y", 0.7, 0.1)

func set_selected(selected: bool):
	is_selected = selected
	if _selection_tween:
		_selection_tween.kill()

	_selection_tween = create_tween()

	if is_selected:
		var target_y = -30
		_selection_tween.tween_property(self, "position:y", target_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_selection_tween.finished.connect(func():
			if is_selected:
				_selection_tween = create_tween().set_loops()
				_selection_tween.tween_property(visuals, "position:y", -10, 0.4).set_trans(Tween.TRANS_SINE)
				_selection_tween.tween_property(visuals, "position:y", 0, 0.4).set_trans(Tween.TRANS_SINE)
		)
	else:
		_selection_tween.tween_property(self, "position:y", 0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		visuals.position.y = 0

func move_to(target_position: Vector2):
	if _idle_tween: _idle_tween.pause()

	var start_pos = position
	var direction = 1 if target_position.x > start_pos.x else -1
	var tween = create_tween()
	tween.set_parallel(true)

	# Horizontal movement
	tween.tween_property(self, "position:x", target_position.x, 0.4).set_trans(Tween.TRANS_SINE)

	# Rotation toward target
	tween.tween_property(visuals, "rotation_degrees", 15.0 * direction, 0.2).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_property(visuals, "rotation_degrees", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)

	# Vertical movement with arc
	var mid_y = min(start_pos.y, target_position.y) - 200
	var v_tween = create_tween()
	v_tween.tween_property(self, "position:y", mid_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	v_tween.tween_property(self, "position:y", target_position.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Wing flapping
	var flap_tween = create_tween().set_loops(4)
	flap_tween.tween_property(wing, "rotation_degrees", -45, 0.05)
	flap_tween.tween_property(wing, "rotation_degrees", 45, 0.05)

	await v_tween.finished

	flap_tween.kill()
	wing.rotation_degrees = 0

	# Juicy squash and stretch on landing
	var land_tween = create_tween()
	land_tween.tween_property(visuals, "scale", Vector2(1.3, 0.7), 0.1)
	land_tween.tween_property(visuals, "scale", Vector2(0.9, 1.1), 0.1)
	land_tween.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.1)

	if _idle_tween: _idle_tween.play()

func fly_away():
	if _idle_tween: _idle_tween.kill()
	if _selection_tween: _selection_tween.kill()

	shadow.hide()

	var tween = create_tween()
	tween.set_parallel(true)

	# Fast flapping
	var flap_tween = create_tween().set_loops()
	flap_tween.tween_property(wing, "rotation_degrees", -45, 0.05)
	flap_tween.tween_property(wing, "rotation_degrees", 45, 0.05)

	# Fly up and away
	tween.tween_property(self, "position:y", position.y - 1000, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", position.x + randf_range(-200, 200), 1.5)
	tween.tween_property(self, "rotation_degrees", 360, 1.5)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 1.5)
	tween.tween_property(self, "modulate:a", 0.0, 1.5)

	await tween.finished
	queue_free()
