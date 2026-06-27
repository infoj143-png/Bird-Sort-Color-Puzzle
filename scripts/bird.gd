extends Node2D

enum BirdColor { RED, BLUE, GREEN, YELLOW, PINK, PURPLE, BLACK, WHITE, BROWN }

@export var color: BirdColor = BirdColor.RED:
	set(value):
		color = value
		update_color_visual()
@export var is_selected: bool = false

@onready var visuals = $Visuals
@onready var body = $Visuals/Body

var _selection_tween: Tween
var _idle_tween: Tween
var _blink_timer: float = 0.0

# ✨ BIRD TEXTURES - NEW PNG ASSETS
var bird_textures = {
	BirdColor.RED: preload("res://assets/birds/bird_0_red_macawpng.png"),
	BirdColor.GREEN: preload("res://assets/birds/bird_1_green_parrotpng.png"),
	BirdColor.BLUE: preload("res://assets/birds/bird_2_blue_jaypng.png"),
	BirdColor.YELLOW: preload("res://assets/birds/bird_3_yellow_canarypng.png"),
	BirdColor.PINK: preload("res://assets/birds/bird_4_pink_cockatoopng.png"),
	BirdColor.PURPLE: preload("res://assets/birds/bird_5_purple_birdpng.png"),
	BirdColor.BLACK: preload("res://assets/birds/bird_6_black_crowpng.png"),
	BirdColor.WHITE: preload("res://assets/birds/bird_7_white_dovepng.png"),
	BirdColor.BROWN: preload("res://assets/birds/bird_8_brown_owlpng.png"),
}

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
	
	if color in bird_textures:
		var texture = bird_textures[color]
		if texture:
			body.texture = texture
			body.self_modulate = Color.WHITE

			# Auto-crop padding automatically
			var img = texture.get_image()
			if img:
				var rect = img.get_used_rect()
				if rect.size.x > 0 and rect.size.y > 0:
					body.region_enabled = true
					body.region_rect = rect
					# Position the cropped sprite so its bottom center is at (0,0) local
					body.position = Vector2(-rect.size.x / 2.0, -rect.size.y)

func start_idle_animation():
	if _idle_tween:
		_idle_tween.kill()

	_idle_tween = create_tween().set_loops()
	_idle_tween.set_parallel(true)

	# Gentle breathing
	_idle_tween.tween_property(visuals, "scale:y", 1.03, 1.5).set_trans(Tween.TRANS_SINE)
	_idle_tween.chain().tween_property(visuals, "scale:y", 1.0, 1.5).set_trans(Tween.TRANS_SINE)

	# Gentle sway
	_idle_tween.tween_property(visuals, "rotation_degrees", 1.5, 2.0).set_trans(Tween.TRANS_SINE)
	_idle_tween.chain().tween_property(visuals, "rotation_degrees", -1.5, 2.0).set_trans(Tween.TRANS_SINE)

	_idle_tween.custom_step(randf() * 5.0)

func play_blink():
	# Simplified blink for single sprite: slight scale down and up
	var tween = create_tween()
	tween.tween_property(body, "scale:y", 0.33, 0.1)
	tween.tween_property(body, "scale:y", 0.35, 0.1)

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

	tween.tween_property(self, "position:x", target_position.x, 0.4).set_trans(Tween.TRANS_SINE)

	tween.tween_property(visuals, "rotation_degrees", 10.0 * direction, 0.2).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_property(visuals, "rotation_degrees", 0.0, 0.2).set_trans(Tween.TRANS_QUAD)

	var mid_y = min(start_pos.y, target_position.y) - 200
	var v_tween = create_tween()
	v_tween.tween_property(self, "position:y", mid_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	v_tween.tween_property(self, "position:y", target_position.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Flapping animation using whole bird scale
	var flap_tween = create_tween().set_loops(4)
	flap_tween.tween_property(body, "scale:y", 0.3, 0.05)
	flap_tween.tween_property(body, "scale:y", 0.4, 0.05)

	await v_tween.finished

	flap_tween.kill()
	body.scale.y = 0.35

	var land_tween = create_tween()
	land_tween.tween_property(visuals, "scale", Vector2(1.2, 0.8), 0.1)
	land_tween.tween_property(visuals, "scale", Vector2(0.9, 1.1), 0.1)
	land_tween.tween_property(visuals, "scale", Vector2(1.0, 1.0), 0.1)

	if _idle_tween: _idle_tween.play()

func fly_away():
	if _idle_tween: _idle_tween.kill()
	if _selection_tween: _selection_tween.kill()

	var tween = create_tween()
	tween.set_parallel(true)

	var flap_tween = create_tween().set_loops()
	flap_tween.tween_property(body, "scale:y", 0.3, 0.05)
	flap_tween.tween_property(body, "scale:y", 0.4, 0.05)

	tween.tween_property(self, "position:y", position.y - 1000, 1.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "position:x", position.x + randf_range(-200, 200), 1.5)
	tween.tween_property(self, "rotation_degrees", 360, 1.5)
	tween.tween_property(self, "scale", Vector2(0.5, 0.5), 1.5)
	tween.tween_property(self, "modulate:a", 0.0, 1.5)

	await tween.finished
	queue_free()
