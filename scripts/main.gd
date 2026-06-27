extends Node2D

@export var bird_scene: PackedScene
@export var branch_scene: PackedScene

var selected_branch: Node2D = null
var branches: Array = []
var current_level: int = 1

@onready var branch_container = $Branches
@onready var level_complete_ui = $CanvasLayer/LevelComplete

func _ready():
	start_level()

func start_level():
	level_complete_ui.hide()
	selected_branch = null
	for child in branch_container.get_children():
		child.queue_free()
	branches.clear()

	if current_level == 1:
		setup_level_1()
	else:
		setup_random_level()

func setup_level_1():
	# 4 branches
	for i in range(4):
		var branch = branch_scene.instantiate()
		branch_container.add_child(branch)
		# Centered on 720 width, spread vertically
		branch.position = Vector2(360, 400 + i * 200)
		branches.append(branch)

		if i == 0:
			# [RED, BLUE, RED, BLUE]
			var colors = [0, 1, 0, 1]
			for c in colors:
				var bird = bird_scene.instantiate()
				bird.color = c
				branch.add_bird(bird)
		elif i == 1:
			# [BLUE, RED, BLUE, RED]
			var colors = [1, 0, 1, 0]
			for c in colors:
				var bird = bird_scene.instantiate()
				bird.color = c
				branch.add_bird(bird)

func setup_random_level():
	# Number of colors increases every 3 levels, max 9
	var num_colors = min(9, 2 + floor((current_level - 1) / 3))
	# Number of branches: num_colors + 2 empty branches
	var num_branches = num_colors + 2

	var colors = []
	for i in range(num_colors):
		for j in range(4):
			colors.append(i)
	colors.shuffle()

	for i in range(num_branches):
		var branch = branch_scene.instantiate()
		branch_container.add_child(branch)

		# Distribute branches in two columns if many
		if num_branches <= 6:
			branch.position = Vector2(360, 250 + i * 160)
		else:
			var column = 0 if i < (num_branches + 1) / 2 else 1
			var row = i if column == 0 else i - (num_branches + 1) / 2
			var num_rows = (num_branches + 1) / 2
			branch.position = Vector2(180 + column * 360, 250 + row * (1000 / num_rows))
			branch.scale = Vector2(0.7, 0.7) # Scale down for two columns

		branches.append(branch)

		if i < num_colors:
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
				removed.reverse() # Maintain order when adding to new branch
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
	for branch in branches:
		# Adjust detection rect based on branch visual size and scaling
		# The branch sprite is scaled to 0.4 in Branch.tscn
		var width = 600 * branch.scale.x
		var height = 120 * branch.scale.y
		var rect = Rect2(branch.position.x - width/2, branch.position.y - height/2 - 40, width, height)
		if rect.has_point(pos):
			return branch
	return null

func check_for_matches():
	var all_cleared = true

	for branch in branches:
		if branch.check_full_set():
			branch.fly_away_all()

		# Yield slightly to allow fly away animation to start before checking if all cleared
		# In a real game we might wait for animations to finish

	# Wait a frame to let birds be removed from branch.birds if they flew away
	await get_tree().process_frame

	for branch in branches:
		if not branch.birds.is_empty():
			all_cleared = false

	if all_cleared:
		win_level()

func win_level():
	level_complete_ui.show()

func _on_restart_pressed():
	start_level()

func _on_next_level_pressed():
	current_level += 1
	start_level()
