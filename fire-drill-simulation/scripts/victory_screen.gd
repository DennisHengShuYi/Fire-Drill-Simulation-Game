extends Control

@onready var score_list: VBoxContainer = $Panel/ScorecardPanel/ScrollContainer/ScoreList
@onready var subtitle: Label = $Panel/Subtitle

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	setup_scorecard()
	$Panel/PlayAgainBtn.pressed.connect(_on_play_again_pressed)
	$Panel/MainMenuBtn.pressed.connect(_on_main_menu_pressed)

func setup_scorecard():
	for child in score_list.get_children():
		child.queue_free()

	# Base score
	var score = 0
	if GameManager.felt_bedroom_door: score += 15
	if GameManager.crouched_in_smoke: score += 20
	if GameManager.felt_kitchen_door: score += 15
	if GameManager.used_stairs:       score += 20
	if GameManager.called_999:        score += 20
	if GameManager.got_wet_towel:     score += 10
	if GameManager.stood_up_in_smoke: score -= 10
	if GameManager.saved_neighbor or GameManager.neighbor_left_behind: score += 10

	# Serious Game Gap 1: time bonus rewards quick, correct evacuation
	var escape_secs = GameManager.escape_time
	var time_bonus = 0
	if escape_secs > 0 and escape_secs < 30.0:
		time_bonus = 15
	elif escape_secs < 60.0:
		time_bonus = 5
	score += time_bonus
	score = clamp(score, 0, 100)

	var escape_str = "%d s" % int(escape_secs) if escape_secs > 0 else "—"
	subtitle.text = "You successfully evacuated the building!\nScore: %d/100   |   Escaped in: %s" % [score, escape_str]

	# Save and compare with personal best (Serious Game Gap 4)
	var best = GameManager.load_best_score()
	var prev_best_score = best.get("score", 0) as int
	var prev_best_time  = best.get("time", INF)  as float
	var is_new_best = (score > prev_best_score) or (escape_secs > 0.0 and escape_secs < prev_best_time)
	GameManager.save_best_score(score, escape_secs)

	# Experience 6: NEW BEST banner
	if is_new_best:
		var nb = Label.new()
		nb.text = "★  NEW BEST!  ★"
		nb.add_theme_font_size_override("font_size", 22)
		nb.add_theme_color_override("font_color", Color(1.0, 0.92, 0.0))
		nb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		score_list.add_child(nb)

	if prev_best_score > 0:
		var pb_lbl = Label.new()
		var pb_time_str = "%d s" % int(prev_best_time) if prev_best_time != INF else "—"
		pb_lbl.text = "Previous best: %d/100   |   Best time: %s" % [prev_best_score, pb_time_str]
		pb_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.9))
		pb_lbl.add_theme_font_size_override("font_size", 11)
		score_list.add_child(pb_lbl)

	# Spacer
	var sp = Label.new()
	sp.text = ""
	score_list.add_child(sp)

	var steps = [
		{
			"label": "Felt Bedroom Door before opening",
			"status": GameManager.felt_bedroom_door,
			"rationale": "Checking the handle temperature prevents opening a door into a room already engulfed in flames."
		},
		{
			"label": "Crouched / Stayed Low in smoke corridor",
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
			"rationale": "Covering your mouth/nose with a wet towel filters toxic smoke particles and cools inhaled air."
		},
		{
			"label": "Used Stairs instead of Lift to evacuate",
			"status": GameManager.used_stairs,
			"rationale": "Lifts can lose power and trap you inside; lift shafts act like chimneys drawing toxic smoke upward."
		},
		{
			"label": "Called BOMBA (999) from safe zone",
			"status": GameManager.called_999,
			"rationale": "Calling 999 outside gives dispatchers your exact situation and triggers an immediate response."
		},
		{
			"label": "Reported to Building Warden (Good Practice)",
			"status": GameManager.reported_to_warden,
			"rationale": "Reporting to the warden confirms your unit is empty, preventing rescue teams from re-entering."
		}
	]

	if GameManager.neighbor_quest_attempted:
		var n_label = "Saved trapped neighbor (delayed evacuation)" if GameManager.saved_neighbor else "Advised neighbor to use balcony exit (correct protocol)"
		var n_rationale = "Heroic attempts can be dangerous in real fires due to toxic smoke. BOMBA recommends alerting neighbors (knocking loudly) but not delaying your evacuation or re-entering. Always report trapped neighbors to 999 or wardens."
		steps.append({
			"label": n_label,
			"status": true,
			"rationale": n_rationale
		})

	for step in steps:
		var item = Label.new()
		var prefix = "[  PASS  ] " if step["status"] else "[  FAIL  ] "
		if step["status"]:
			item.text = prefix + step["label"]
			item.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		else:
			item.text = prefix + step["label"] + " (Skipped)"
			item.add_theme_color_override("font_color", Color(0.9, 0.4, 0.1))
		item.add_theme_font_size_override("font_size", 13)
		score_list.add_child(item)

		var rat = Label.new()
		rat.text = "   └─ Why: " + step["rationale"]
		rat.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
		rat.add_theme_font_size_override("font_size", 10)
		rat.autowrap_mode = TextServer.AUTOWRAP_WORD
		score_list.add_child(rat)

func _on_play_again_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
