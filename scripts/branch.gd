extends Node2D

const MAX_BIRDS = 4
var birds: Array = []

@onready var slots = $Slots

func _ready():
	pass

func add_bird(bird: Node2D):
	birds.append(bird)
	var target_pos = slots.get_child(birds.size() - 1).position

	if bird.get_parent():
		bird.reparent(self)
	else:
		add_child(bird)

	bird.move_to(target_pos)

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
