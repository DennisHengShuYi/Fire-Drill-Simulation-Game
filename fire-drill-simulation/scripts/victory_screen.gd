extends Control

@onready var score_list: VBoxContainer = $Panel/ScorecardPanel/ScrollContainer/ScoreList
@onready var subtitle: Label = $Panel/Subtitle

var current_question: int = 0
var correct_answers: int = 0
var quiz_panel: Panel = null

var quiz_questions = [
	{
		"question": "1. What does the P.A.S.S. acronym stand for when using a fire extinguisher?",
		"options": [
			"Pull, Aim, Squeeze, Sweep",
			"Push, Aim, Shake, Spray",
			"Pull, Arm, Squeeze, Spray"
		],
		"correct": 0
	},
	{
		"question": "2. Why should you crouch/crawl in a smoke-filled room?",
		"options": [
			"To hide from the fire",
			"Smoke and toxic gases rise, leaving cleaner air near the ground",
			"To move faster under the smoke"
		],
		"correct": 1
	},
	{
		"question": "3. What is the correct method to prevent smoke seepage into a bedroom when trapped?",
		"options": [
			"Seal the door gaps with a wet towel and keep the door closed",
			"Open the bedroom windows and door fully to let smoke out",
			"Pour water on the door continuously without closing it"
		],
		"correct": 0
	}
]

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_quiz()
	$Panel/PlayAgainBtn.pressed.connect(_on_play_again_pressed)
	$Panel/MainMenuBtn.pressed.connect(_on_main_menu_pressed)

func start_quiz():
	# Hide all main UI elements
	$Panel/ScorecardPanel.visible = false
	$Panel/BadgePanel.visible = false
	$Panel/PlayAgainBtn.visible = false
	$Panel/MainMenuBtn.visible = false
	
	subtitle.text = "Answer these fire safety questions correctly to earn bonus points!"
	
	quiz_panel = Panel.new()
	quiz_panel.name = "QuizPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.14, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.45, 0.3, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_right = 8
	style.corner_radius_bottom_left = 8
	quiz_panel.add_theme_stylebox_override("panel", style)
	
	# Positioning inside $Panel
	quiz_panel.size = Vector2(560, 310)
	quiz_panel.position = Vector2(20, 130)
	$Panel.add_child(quiz_panel)
	
	show_next_quiz_question()

func show_next_quiz_question():
	if current_question >= quiz_questions.size():
		finish_quiz()
		return
		
	var q_data = quiz_questions[current_question]
	
	# Clear old children
	for child in quiz_panel.get_children():
		child.queue_free()
		
	# Header
	var hdr = Label.new()
	hdr.text = "FIRE SAFETY QUIZ  (%d/%d)" % [current_question + 1, quiz_questions.size()]
	hdr.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	hdr.add_theme_font_size_override("font_size", 16)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.size = Vector2(520, 30)
	hdr.position = Vector2(20, 15)
	quiz_panel.add_child(hdr)
	
	# Question
	var q_lbl = Label.new()
	q_lbl.text = q_data["question"]
	q_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	q_lbl.add_theme_font_size_override("font_size", 14)
	q_lbl.size = Vector2(520, 60)
	q_lbl.position = Vector2(20, 45)
	q_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	quiz_panel.add_child(q_lbl)
	
	# Options
	var y_pos = 120
	for i in range(q_data["options"].size()):
		var opt_text = q_data["options"][i]
		var btn = Button.new()
		btn.text = opt_text
		btn.size = Vector2(520, 40)
		btn.position = Vector2(20, y_pos)
		y_pos += 50
		
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = Color(0.1, 0.3, 0.2, 0.8)
		btn_style.border_width_left = 1
		btn_style.border_width_top = 1
		btn_style.border_width_right = 1
		btn_style.border_width_bottom = 1
		btn_style.border_color = Color(0.2, 0.5, 0.35, 0.8)
		btn_style.corner_radius_top_left = 6
		btn_style.corner_radius_top_right = 6
		btn_style.corner_radius_bottom_right = 6
		btn_style.corner_radius_bottom_left = 6
		btn.add_theme_stylebox_override("normal", btn_style)
		
		# Hook click event safely using bind(i)
		btn.pressed.connect(_on_quiz_answer_selected.bind(i))
		quiz_panel.add_child(btn)

func _on_quiz_answer_selected(idx: int):
	var q_data = quiz_questions[current_question]
	if idx == q_data["correct"]:
		correct_answers += 1
		play_click_sound()
	else:
		play_wrong_sound()
	current_question += 1
	show_next_quiz_question()

func finish_quiz():
	if is_instance_valid(quiz_panel):
		quiz_panel.queue_free()
		quiz_panel = null
		
	# Show original UI
	$Panel/ScorecardPanel.visible = true
	$Panel/BadgePanel.visible = true
	$Panel/PlayAgainBtn.visible = true
	$Panel/MainMenuBtn.visible = true
	
	setup_scorecard()

func play_click_sound():
	var aud = AudioStreamPlayer.new()
	aud.script = load("res://scripts/synth_audio.gd")
	aud.synth_type = "click"
	add_child(aud)

func play_wrong_sound():
	var aud = AudioStreamPlayer.new()
	aud.script = load("res://scripts/synth_audio.gd")
	aud.synth_type = "wrong"
	add_child(aud)

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
	
	# Suggestion 2, 3, 4 Score modifiers
	if GameManager.corrected_npc: score += 10
	if GameManager.ignored_npc:   score -= 10
	if GameManager.alarm_triggered: score += 10
	if GameManager.sealed_door:     score += 10
	score += correct_answers * 5 # +5 per correct MCQ answer

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
			"label": "Pulled Fire Alarm Call Point in corridor",
			"status": GameManager.alarm_triggered,
			"rationale": "Activating the fire alarm manual call point alerts other building residents and initiates stairwell evacuations."
		},
		{
			"label": "Sealed Bedroom Door with Wet Towel",
			"status": GameManager.sealed_door,
			"rationale": "Sealing closed doors with wet towels blocks smoke seepage and buys critical time if you are trapped."
		},
		{
			"label": "Corrected Panicking Neighbor (Suitcase)",
			"status": GameManager.corrected_npc,
			"rationale": "Heavy luggage blocks evacuation routes and causes crowd congestion on stairwells. Calming residents down saves lives."
		},
		{
			"label": "Fire Safety Quiz Score: %d/%d Correct" % [correct_answers, quiz_questions.size()],
			"status": correct_answers == quiz_questions.size(),
			"rationale": "Completing the quiz reinforces vital fire safety protocols, helping you respond automatically during emergencies."
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
