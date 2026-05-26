extends Node

# Game Over contexts
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

func _ready():
	setup_inputs()

func setup_inputs():
	# Define core controls programmatically to keep it robust and self-contained
	var inputs = {
		"move_forward": [KEY_W, KEY_UP],
		"move_backward": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"crouch": [KEY_C, KEY_CTRL],
		"sprint": [KEY_SHIFT],
		"interact": [KEY_E],
		"feel_door": [KEY_F]
	}
	
	for action in inputs.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		
		# Clear existing events to avoid duplicates
		InputMap.action_erase_events(action)
		
		for key in inputs[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
			
	# Also add mouse click to interact
	var mouse_ev = InputEventMouseButton.new()
	mouse_ev.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("interact", mouse_ev)

func trigger_game_over(reason: String, tip: String):
	game_over_reason = reason
	game_over_tip = tip
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func trigger_victory():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/victory_screen.tscn")
