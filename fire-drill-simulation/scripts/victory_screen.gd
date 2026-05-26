extends Control

@onready var score_list: VBoxContainer = $Panel/ScorecardPanel/ScoreList
@onready var subtitle: Label = $Panel/Subtitle

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
		
	# Calculate score
	var score = 0
	if GameManager.felt_bedroom_door: score += 15
	if GameManager.crouched_in_smoke: score += 20
	if GameManager.felt_kitchen_door: score += 15
	if GameManager.used_stairs: score += 20
	if GameManager.called_999: score += 20
	if GameManager.got_wet_towel: score += 10 # Bonus
	
	if GameManager.stood_up_in_smoke: score -= 10
	score = clamp(score, 0, 100)
	
	subtitle.text = "You successfully evacuated the building!\nFinal Score: %d/100" % score
	
	# List of steps to check with BOMBA rationales
	var steps = [
		{
			"label": "Felt Bedroom Door before opening",
			"status": GameManager.felt_bedroom_door,
			"rationale": "Checking the handle temperature prevents opening a door into a room already engulfed in flames."
		},
		{
			"label": "Crouched / Stayed Low in smoke Corridor",
			"status": GameManager.crouched_in_smoke,
			"rationale": "Smoke and toxic gases rise. Crawling keeps you in the cooler, breathable layer of air near the ground."
		},
		{
			"label": "Checked Kitchen Door (avoided fire room)",
			"status": GameManager.felt_kitchen_door,
			"rationale": "Feeling the kitchen door tells you where the fire is so you don't walk into a backdraft explosion."
		},
		{
			"label": "Obtained Wet Towel from Bathroom (Bonus)",
			"status": GameManager.got_wet_towel,
			"rationale": "Covering your mouth/nose with a wet towel filters toxic smoke particles and cools hot air."
		},
		{
			"label": "Used Stairs instead of Lift to evacuate",
			"status": GameManager.used_stairs,
			"rationale": "Lifts can lose power and trap you inside, and lift shafts act like chimneys filling with toxic smoke."
		},
		{
			"label": "Called BOMBA (999) from safe zone",
			"status": GameManager.called_999,
			"rationale": "Calling 999 outside gives rescue dispatchers your exact situation and triggers immediate response."
		}
	]
	
	for step in steps:
		# Main step label
		var item_label = Label.new()
		var prefix = "[  PASS  ] " if step["status"] else "[  FAIL  ] "
		
		if step["status"]:
			item_label.text = prefix + step["label"]
			item_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2)) # Green
		else:
			item_label.text = prefix + step["label"] + " (Skipped)"
			item_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.1)) # Orange/Warning
			
		item_label.theme_type_variation = "Label"
		item_label.add_theme_font_size_override("font_size", 13)
		score_list.add_child(item_label)
		
		# Rationale sub-label (indented and slightly smaller)
		var rational_label = Label.new()
		rational_label.text = "   └─ Why: " + step["rationale"]
		rational_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75)) # Gray
		rational_label.theme_type_variation = "Label"
		rational_label.add_theme_font_size_override("font_size", 10)
		rational_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		score_list.add_child(rational_label)

func _on_play_again_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
