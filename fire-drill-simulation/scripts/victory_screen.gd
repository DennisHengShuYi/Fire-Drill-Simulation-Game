extends Control

@onready var score_list: VBoxContainer = $Panel/ScorecardPanel/ScoreList

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	setup_scorecard()
	
	# Connect buttons programmatically
	$Panel/PlayAgainBtn.pressed.connect(_on_play_again_pressed)
	$Panel/MainMenuBtn.pressed.connect(_on_main_menu_pressed)

func setup_scorecard():
	# Clear checklist placeholders
	for child in score_list.get_children():
		child.queue_free()
		
	# List of steps to check
	var steps = [
		{
			"label": "Felt Bedroom Door before opening",
			"status": GameManager.felt_bedroom_door,
			"critical": true
		},
		{
			"label": "Crouched / Stayed Low in smoke Corridor",
			"status": GameManager.crouched_in_smoke,
			"critical": true
		},
		{
			"label": "Checked Kitchen Door (avoided fire room)",
			"status": GameManager.felt_kitchen_door,
			"critical": false
		},
		{
			"label": "Used Stairs instead of Lift to evacuate",
			"status": GameManager.used_stairs,
			"critical": true
		},
		{
			"label": "Called BOMBA (999) from safe zone",
			"status": GameManager.called_999,
			"critical": true
		}
	]
	
	for step in steps:
		var item_label = Label.new()
		var prefix = "[  PASS  ] " if step["status"] else "[  FAIL  ] "
		var suffix = ""
		
		# If they reached victory, all critical steps must be true, but some optional ones (like feeling the kitchen door) might be skipped, though highly recommended!
		if step["status"]:
			item_label.text = prefix + step["label"]
			item_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2)) # Green
		else:
			item_label.text = prefix + step["label"] + " (Skipped)"
			item_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.1)) # Orange/Warning
			
		item_label.theme_type_variation = "Label"
		item_label.add_theme_font_size_override("font_size", 14)
		score_list.add_child(item_label)

func _on_play_again_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
