extends Node2D

const MAX_BIRDS = 4
var birds: Array = []

@onready var slots = $Slots
@onready var sprite = $Sprite2D

func _ready():
	update_branch_visual()

func update_branch_visual():
	if not sprite.texture: return

	sprite.rotation = 0

	var img = sprite.texture.get_image()
	if img:
		var rect = img.get_used_rect()
		if rect.size.x > 0 and rect.size.y > 0:
			sprite.region_enabled = true
			sprite.region_rect = rect

			var target_width = 520.0
			var s = target_width / rect.size.x
			sprite.scale = Vector2(s, s)

			# Optimal slot spacing for exactly 4 birds
			var total_width = target_width * 0.7
			var spacing = total_width / (MAX_BIRDS - 1)
			for i in range(slots.get_child_count()):
				var slot = slots.get_child(i)
				var x_pos = -(total_width / 2.0) + i * spacing
				# Sit perfectly on top of the wooden branch visual
				slot.position = Vector2(x_pos, -15)

func add_bird(bird: Node2D):
	birds.append(bird)
	var target_slot = slots.get_child(birds.size() - 1)

	if bird.get_parent():
		bird.reparent(target_slot)
	else:
		target_slot.add_child(bird)

	bird.move_to(Vector2.ZERO)

func remove_birds(count: int) -> Array:
	var removed = []
	for i in range(count):
		removed.append(birds.pop_back())
	return removed

func get_top_bird() -> Node2D:
	if birds.is_empty():
		return null
	return birds[-1]

func get_top_birds_of_same_color() -> Array:
	if birds.is_empty():
		return []

	var same_color_birds = []
	var top_color = birds[-1].color

	for i in range(birds.size() - 1, -1, -1):
		if birds[i].color == top_color:
			same_color_birds.append(birds[i])
		else:
			break
	return same_color_birds

func can_receive_birds(incoming_color: int, count: int) -> bool:
	if birds.size() + count > MAX_BIRDS:
		return false

	if birds.is_empty():
		return true

	return birds[-1].color == incoming_color

func check_full_set() -> bool:
	if birds.size() == MAX_BIRDS:
		var color = birds[0].color
		for bird in birds:
			if bird.color != color:
				return false
		return true
	return false

func fly_away_all():
	var birds_to_fly = birds.duplicate()
	birds.clear()
	for bird in birds_to_fly:
		bird.fly_away()
