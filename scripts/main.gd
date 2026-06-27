extends Node2D

@export var bird_scene: PackedScene
@export var branch_scene: PackedScene

var selected_branch: Node2D = null
var branches: Array = []
var current_level: int = 1

@onready var branch_container = $Branches
@onready var level_complete_ui = $CanvasLayer/LevelComplete
@onready var level_label = $CanvasLayer/UI/LevelLabel

func _ready():
	start_level()

func start_level():
	level_complete_ui.hide()
	level_label.text = "Level " + str(current_level)
	selected_branch = null
	for child in branch_container.get_children():
		child.queue_free()
	branches.clear()

	if current_level == 1:
		setup_level_1()
	else:
		setup_random_level()

func setup_level_1():
	# 6 branches for Android portrait premium look
	for i in range(6):
		var branch = branch_scene.instantiate()
		branch_container.add_child(branch)
		# Optimized vertical spacing for 720x1280
		branch.position = Vector2(360, 350 + i * 160)
		branch.rotation = 0
		branch.scale = Vector2(0.75, 0.75)
		branches.append(branch)

		if i == 0:
			var colors = [0, 1, 0, 1] # Red and Green
			for c in colors:
				var bird = bird_scene.instantiate()
				bird.color = c
				branch.add_bird(bird)
		elif i == 1:
			var colors = [1, 0, 1, 0]
			for c in colors:
				var bird = bird_scene.instantiate()
				bird.color = c
				branch.add_bird(bird)

func setup_random_level():
	var num_colors = min(9, 2 + floor((current_level - 1) / 3))
	var num_branches = num_colors + 2

	var colors = []
	for i in range(num_colors):
		for j in range(4):
			colors.append(i)
	colors.shuffle()

	for i in range(num_branches):
		var branch = branch_scene.instantiate()
		branch_container.add_child(branch)

		if num_branches <= 6:
			var vertical_start = 350
			var vertical_spacing = (1150 - vertical_start) / (num_branches - 1) if num_branches > 1 else 0
			branch.position = Vector2(360, vertical_start + i * vertical_spacing)
			branch.rotation = 0
		else:
			var column = 0 if i < (num_branches + 1) / 2 else 1
			var row = i if column == 0 else i - (num_branches + 1) / 2
			var rows_in_col = (num_branches + 1) / 2 if column == 0 else num_branches - (num_branches + 1) / 2

			var x_pos = 185 if column == 0 else 535
			var vertical_start = 350
			var vertical_end = 1150
			var row_height = (vertical_end - vertical_start) / (max(1, rows_in_col - 1)) if rows_in_col > 1 else 0

			branch.position = Vector2(x_pos, vertical_start + row * row_height)
			branch.rotation = 0
			branch.scale = Vector2(0.65, 0.65)

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
	var hit = get_hit_info(pos)
	if not hit:
		return

	var clicked_branch = hit.branch
	var clicked_bird = hit.bird

	if selected_branch == null:
		# Exact bird selection: must tap a bird, and it must be part of the top color group
		if clicked_bird != null:
			var top_birds = clicked_branch.get_top_birds_of_same_color()
			if clicked_bird in top_birds:
				select_branch(clicked_branch)
	else:
		if selected_branch == clicked_branch:
			deselect_current_branch()
		else:
			var moving_birds = selected_branch.get_top_birds_of_same_color()
			var color = moving_birds[0].color

			if clicked_branch.can_receive_birds(color, moving_birds.size()):
				var removed = selected_branch.remove_birds(moving_birds.size())
				removed.reverse()
				for bird in removed:
					bird.set_selected(false)
					clicked_branch.add_bird(bird)

				selected_branch = null
				check_for_matches()
			else:
				# Switch selection if the clicked branch has a valid top color group tapped
				if not clicked_branch.birds.is_empty():
					var top_birds = clicked_branch.get_top_birds_of_same_color()
					if clicked_bird == null or clicked_bird in top_birds:
						deselect_current_branch()
						select_branch(clicked_branch)
					else:
						deselect_current_branch()
				else:
					deselect_current_branch()

func select_branch(branch: Node2D):
	selected_branch = branch
	var birds_to_select = selected_branch.get_top_birds_of_same_color()
	for bird in birds_to_select:
		bird.set_selected(true)

func deselect_current_branch():
	if selected_branch:
		var birds_to_deselect = selected_branch.get_top_birds_of_same_color()
		for bird in birds_to_deselect:
			bird.set_selected(false)
		selected_branch = null

func get_hit_info(pos: Vector2):
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos
	query.collide_with_areas = true

	var results = space_state.intersect_point(query)
	if results.is_empty():
		return null

	# Prioritize bird hits over branch hits
	var branch_hit = null
	for result in results:
		var collider = result.collider
		var parent = collider.get_parent()

		if parent is Bird:
			# Find which branch this bird belongs to
			for branch in branches:
				if bird_is_in_branch(parent, branch):
					return {"branch": branch, "bird": parent}
		elif parent is Branch:
			branch_hit = {"branch": parent, "bird": null}

	return branch_hit

func bird_is_in_branch(bird: Node2D, branch: Node2D) -> bool:
	return bird in branch.birds

func check_for_matches():
	await get_tree().process_frame # Wait for bird to arrive

	var matches_found = false
	for branch in branches:
		if branch.check_full_set():
			branch.fly_away_all()
			matches_found = true

	if matches_found:
		await get_tree().create_timer(1.0).timeout

	var all_cleared = true
	for branch in branches:
		if not branch.birds.is_empty():
			all_cleared = false
			break

	if all_cleared:
		win_level()

func win_level():
	level_complete_ui.show()

func _on_restart_pressed():
	start_level()

func _on_next_level_pressed():
	current_level += 1
	start_level()
