extends Node

var game_over_reason: String = ""
var game_over_tip: String = ""

# Scorecard variables
var felt_bedroom_door: bool = false
var felt_kitchen_door: bool = false
var opened_kitchen_door: bool = false
var stood_up_in_smoke: bool = false
var used_lift: bool = false
var used_stairs: bool = false
var called_999: bool = false
var crouched_in_smoke: bool = false
var got_wet_towel: bool = false
var reported_to_warden: bool = false
var fire_spread_count: int = 0
var neighbor_quest_attempted: bool = false
var saved_neighbor: bool = false
var neighbor_left_behind: bool = false
var alarm_triggered: bool = false
var corrected_npc: bool = false
var ignored_npc: bool = false
var sealed_door: bool = false

# Escape time (seconds elapsed when 999 is called)
var escape_time: float = 0.0

# BUG 3 FIX: guard against trigger_game_over / trigger_victory firing twice
# in the same frame (e.g. oxygen hits 0 AND timer expires simultaneously).
var _game_over_triggered: bool = false

func reset_state():
	game_over_reason = ""
	game_over_tip = ""
	felt_bedroom_door = false
	felt_kitchen_door = false
	opened_kitchen_door = false
	stood_up_in_smoke = false
	used_lift = false
	used_stairs = false
	called_999 = false
	crouched_in_smoke = false
	got_wet_towel = false
	reported_to_warden = false
	fire_spread_count = 0
	neighbor_quest_attempted = false
	saved_neighbor = false
	neighbor_left_behind = false
	alarm_triggered = false
	corrected_npc = false
	ignored_npc = false
	sealed_door = false
	escape_time = 0.0
	_game_over_triggered = false

func _ready():
	setup_inputs()

func setup_inputs():
	var inputs = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"crouch": [KEY_C, KEY_CTRL],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_E],
		"feel_door": [KEY_F],
		"knock_door": [KEY_K],
		"dilemma_1": [KEY_1],
		"dilemma_2": [KEY_2]
	}

	for action in inputs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		# action_erase_events clears duplicates on every load — safe to call repeatedly
		InputMap.action_erase_events(action)
		for key in inputs[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)

	var mouse_ev = InputEventMouseButton.new()
	mouse_ev.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("interact", mouse_ev)

func trigger_game_over(reason: String, tip: String):
	if _game_over_triggered:
		return
	_game_over_triggered = true
	game_over_reason = reason
	game_over_tip = tip
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func trigger_victory():
	if _game_over_triggered:
		return
	_game_over_triggered = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/victory_screen.tscn")

func save_best_score(score: int, time: float):
	var existing = load_best_score()
	var best_score = max(score, existing.get("score", 0))
	var prev_time = existing.get("time", INF)
	var best_time = time if prev_time == INF else min(time, prev_time)
	var config = ConfigFile.new()
	config.set_value("best", "score", best_score)
	config.set_value("best", "time", best_time)
	config.save("user://save.cfg")

func load_best_score() -> Dictionary:
	var config = ConfigFile.new()
	if config.load("user://save.cfg") != OK:
		return {}
	return {
		"score": config.get_value("best", "score", 0),
		"time": config.get_value("best", "time", INF)
	}
