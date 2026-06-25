extends Node2D

@export var bird_scene: PackedScene
@export var branch_scene: PackedScene

var selected_branch: Node2D = null
var branches: Array = []

@onready var branch_container = $Branches
@onready var level_complete_ui = $CanvasLayer/LevelComplete

func _ready():
	start_level()

func start_level():
	level_complete_ui.hide()
	for child in branch_container.get_children():
		child.queue_free()
	branches.clear()

	# Simple level generation for demo
	# 3 branches with birds, 2 empty
	var colors = [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2]
	colors.shuffle()

	for i in range(5):
		var branch = branch_scene.instantiate()
		branch_container.add_child(branch)
		branch.position = Vector2(360, 250 + i * 180)
		branches.append(branch)

		if i < 3:
			for j in range(4):
				var bird = bird_scene.instantiate()
				bird.color = colors.pop_back()
				branch.add_bird(bird)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		handle_tap(event.position)

func handle_tap(pos: Vector2):
	var clicked_branch = get_branch_at_pos(pos)
	if not clicked_branch:
		return

	if selected_branch == null:
		# Selecting
		if not clicked_branch.birds.is_empty():
			selected_branch = clicked_branch
			var birds_to_select = selected_branch.get_top_birds_of_same_color()
			for bird in birds_to_select:
				bird.set_selected(true)
	else:
		# Moving
		if selected_branch == clicked_branch:
			# Deselect
			var birds_to_deselect = selected_branch.get_top_birds_of_same_color()
			for bird in birds_to_deselect:
				bird.set_selected(false)
			selected_branch = null
		else:
			var moving_birds = selected_branch.get_top_birds_of_same_color()
			var color = moving_birds[0].color

			if clicked_branch.can_receive_birds(color, moving_birds.size()):
				# Perform move
				var removed = selected_branch.remove_birds(moving_birds.size())
				for bird in removed:
					bird.set_selected(false)
					clicked_branch.add_bird(bird)

				selected_branch = null
				check_for_matches()
			else:
				# Invalid move, just deselect
				for bird in moving_birds:
					bird.set_selected(false)
				selected_branch = null

func get_branch_at_pos(pos: Vector2) -> Node2D:
	# Branch is 400x20. We check for a rectangular area around branch.position
	for branch in branches:
		var rect = Rect2(branch.position.x - 200, branch.position.y - 100, 400, 150)
		if rect.has_point(pos):
			return branch
	return null

func check_for_matches():
	var all_cleared = true

	for branch in branches:
		if branch.check_full_set():
			branch.fly_away_all()
		elif not branch.birds.is_empty():
			all_cleared = false

	if all_cleared:
		win_level()

func win_level():
	level_complete_ui.show()

func _on_restart_pressed():
	start_level()

func _on_next_level_pressed():
	start_level()
