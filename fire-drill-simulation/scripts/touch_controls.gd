extends CanvasLayer

var player: CharacterBody3D = null

@onready var joystick_base = $JoystickBase
@onready var joystick_knob = $JoystickBase/JoystickKnob
@onready var look_area = $LookArea
@onready var sprint_btn = $SprintButton
@onready var extinguisher_btn = $ExtinguisherButton

var joystick_active = false
var joystick_touch_index = -1
var joystick_center = Vector2(60, 60)
var max_joystick_distance = 60.0

var _context_container: VBoxContainer = null
var _last_collider: Object = null

func _ready():
	# Keep processing even when paused so pause button and controls work
	process_mode = Node.PROCESS_MODE_ALWAYS
	extinguisher_btn.visible = false
	
	# Connect HUD button events
	$HUDButtons/BtnInteract.pressed.connect(func(): send_key_tap(KEY_E))
	$HUDButtons/BtnCrouch.pressed.connect(func(): send_key_tap(KEY_C))
	$HUDButtons/BtnFeel.pressed.connect(func(): send_key_tap(KEY_F))
	$HUDButtons/BtnSeal.pressed.connect(func(): send_key_tap(KEY_X))
	$HUDButtons/BtnPhone.pressed.connect(func(): send_key_tap(KEY_P))
	$HUDButtons/BtnPause.pressed.connect(func(): send_key_tap(KEY_ESCAPE))
	
	# Sprint button holds
	sprint_btn.button_down.connect(func(): send_key_hold(KEY_SHIFT, true))
	sprint_btn.button_up.connect(func(): send_key_hold(KEY_SHIFT, false))
	
	# Extinguisher button
	extinguisher_btn.pressed.connect(func(): _on_extinguisher_pressed())
	
	# Setup programmatically created dynamic context container
	_context_container = VBoxContainer.new()
	_context_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_context_container.theme_override_constants/separation = 10
	
	# Anchor to right-middle of the screen, just to the left of the static HUD buttons
	_context_container.anchor_left = 1.0
	_context_container.anchor_right = 1.0
	_context_container.anchor_top = 0.5
	_context_container.anchor_bottom = 0.5
	_context_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_context_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Place it nicely: width 240px, height 300px, 340px from right margin to avoid HUD overlap
	_context_container.offset_left = -340
	_context_container.offset_right = -100
	_context_container.offset_top = -150
	_context_container.offset_bottom = 150
	add_child(_context_container)
	
	# Hide old static keyboard-style layout buttons on mobile
	$HUDButtons/BtnInteract.visible = false
	$HUDButtons/BtnFeel.visible = false
	$HUDButtons/BtnSeal.visible = false
	
	# Place joystick at bottom-left in landscape (horizontal) mode properly
	joystick_base.anchors_preset = Control.PRESET_BOTTOM_LEFT
	joystick_base.offset_left = 60.0
	joystick_base.offset_top = -180.0
	joystick_base.offset_right = 180.0
	joystick_base.offset_bottom = -60.0
	
	# Place crouch and pause buttons beautifully in a mobile list
	$HUDButtons.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	$HUDButtons.offset_left = -100.0
	$HUDButtons.offset_top = -280.0
	$HUDButtons.offset_right = -20.0
	$HUDButtons.offset_bottom = -20.0

func _process(_delta):
	if is_instance_valid(player):
		extinguisher_btn.visible = player.has_extinguisher
		
		# Show phone icon button only when they have picked up the mobile phone
		$HUDButtons/BtnPhone.visible = player.has_mobile_phone and not player.climbing_ladder and not player.has_called_bomba
		
		# Update dynamic interactable context actions
		update_context_buttons()

func update_context_buttons():
	if not is_instance_valid(player) or player.phone_active or player.is_paused or player.in_elevator_sequence or player.climbing_ladder:
		clear_context_buttons()
		_last_collider = null
		return
		
	if player.raycast.is_colliding():
		var col = player.raycast.get_collider()
		if col is Interactable:
			if col != _last_collider:
				_last_collider = col
				rebuild_context_buttons(col)
			# Suppress standard keyboard text prompt label
			if is_instance_valid(player.prompt_label):
				player.prompt_label.text = ""
			return
			
	# If nothing is hovered
	_last_collider = null
	clear_context_buttons()

func rebuild_context_buttons(interactable: Interactable):
	clear_context_buttons()
	
	var options = []
	
	if interactable.is_door and interactable.is_stairs:
		options.append({"text": "🚪 Open Fire Exit" if not interactable.door_opened else "🚪 Close Fire Exit", "key": KEY_E})
	elif interactable.is_door:
		options.append({"text": "🚪 Open Door" if not interactable.door_opened else "🚪 Close Door", "key": KEY_E})
		if interactable.can_feel and not interactable.door_opened:
			options.append({"text": "✋ Feel Temp", "key": KEY_F})
		if not interactable.door_opened and interactable.name.to_lower().contains("bedroom") and not interactable.is_sealed:
			if player.has_wet_towel:
				options.append({"text": "🧼 Seal Door Gap", "key": KEY_X})
			else:
				options.append({"text": "🔒 Seal (Requires Wet Towel)", "key": -1})
	elif interactable.is_lift:
		options.append({"text": "🛗 Press Lift Button", "key": KEY_E})
	elif interactable.is_stairs:
		options.append({"text": "🏃 Use Stairs Exit", "key": KEY_E})
	elif interactable.is_phone:
		options.append({"text": "📞 Call BOMBA (999)", "key": KEY_E})
	elif interactable.is_sink:
		if not player.has_wet_towel:
			options.append({"text": "💧 Get Wet Towel", "key": KEY_E})
		else:
			options.append({"text": "🧼 Wet Towel Carried", "key": -1})
	elif interactable.is_locked_door:
		options.append({"text": "🚪 Try Door Handle", "key": KEY_E})
		if interactable.has_trapped_npc:
			if interactable.trapped_npc_quest_state == "none":
				options.append({"text": "✊ Knock on Door", "key": KEY_K})
			elif interactable.trapped_npc_quest_state == "discovered":
				options.append({"text": "🗣️ Talk / Respond", "key": KEY_K})
	elif interactable.is_extinguisher:
		if interactable.extinguisher_used:
			options.append({"text": "🧯 Empty Extinguisher", "key": -1})
		else:
			options.append({"text": "🧯 Pick up Extinguisher", "key": KEY_E})
	elif interactable.is_npc:
		options.append({"text": "🗣️ Talk to Warden", "key": KEY_E})
	elif interactable.is_alarm_pull:
		if GameManager.alarm_triggered:
			options.append({"text": "🚨 Alarm Activated", "key": -1})
		else:
			options.append({"text": "🚨 Pull Fire Alarm", "key": KEY_E})
	elif interactable.is_suitcase_npc:
		if not interactable.resolved:
			options.append({"text": "🗣️ Speak to Resident", "key": KEY_E})
	elif interactable.is_phone_item:
		options.append({"text": "📱 Pick up Mobile Phone", "key": KEY_E})
	elif interactable.is_safety_ladder:
		options.append({"text": "🪜 Climb Safety Ladder", "key": KEY_E})
	else:
		var text = interactable.prompt_message
		if text.begins_with("[E] "):
			text = text.substr(4)
		elif text.begins_with("[E]"):
			text = text.substr(3)
		options.append({"text": text, "key": KEY_E})
		
	for opt in options:
		var btn = Button.new()
		btn.text = opt["text"]
		btn.custom_minimum_size = Vector2(240, 54)
		
		var style = StyleBoxFlat.new()
		if opt["key"] == -1:
			style.bg_color = Color(0.2, 0.2, 0.2, 0.4)
			style.border_color = Color(0.4, 0.4, 0.4, 0.3)
			btn.disabled = true
		else:
			style.bg_color = Color(0.12, 0.5, 0.3, 0.7)
			style.border_color = Color(0.2, 0.8, 0.5, 0.9)
			
		style.border_width_left = 2
		style.border_width_top = 2
		style.border_width_right = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12
		style.corner_radius_bottom_left = 12
		
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_font_size_override("font_size", 14)
		
		var keycode = opt["key"]
		if keycode != -1:
			btn.pressed.connect(func():
				send_key_tap(keycode)
				await get_tree().create_timer(0.15).timeout
				if is_instance_valid(interactable):
					rebuild_context_buttons(interactable)
			)
			
		_context_container.add_child(btn)

func clear_context_buttons():
	if is_instance_valid(_context_container):
		for child in _context_container.get_children():
			child.queue_free()

func send_key_tap(keycode: int):
	var press = InputEventKey.new()
	press.pressed = true
	press.keycode = keycode
	Input.parse_input_event(press)
	
	var release = InputEventKey.new()
	release.pressed = false
	release.keycode = keycode
	Input.parse_input_event(release)

func send_key_hold(keycode: int, pressed: bool):
	var ev = InputEventKey.new()
	ev.pressed = pressed
	ev.keycode = keycode
	Input.parse_input_event(ev)

func _on_extinguisher_pressed():
	if is_instance_valid(player):
		if player.in_extinguisher_minigame:
			var steps = [KEY_P, KEY_A, KEY_S, KEY_S]
			if player.minigame_step >= 0 and player.minigame_step < steps.size():
				send_key_tap(steps[player.minigame_step])
		else:
			var click_press = InputEventMouseButton.new()
			click_press.pressed = true
			click_press.button_index = MOUSE_BUTTON_LEFT
			Input.parse_input_event(click_press)
			
			var click_release = InputEventMouseButton.new()
			click_release.pressed = false
			click_release.button_index = MOUSE_BUTTON_LEFT
			Input.parse_input_event(click_release)

func _on_joystick_base_gui_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if not joystick_active:
				joystick_active = true
				joystick_touch_index = event.index
				update_joystick_knob(event.position)
		else:
			if event.index == joystick_touch_index:
				reset_joystick()
				
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index:
			update_joystick_knob(event.position)

func update_joystick_knob(touch_pos: Vector2):
	var offset = touch_pos - joystick_center
	if offset.length() > max_joystick_distance:
		offset = offset.normalized() * max_joystick_distance
		
	joystick_knob.position = (joystick_center - Vector2(25, 25)) + offset
	
	var strength_x = offset.x / max_joystick_distance
	var strength_y = offset.y / max_joystick_distance
	
	if strength_x > 0.1:
		Input.action_press("move_right", strength_x)
		Input.action_release("move_left")
	elif strength_x < -0.1:
		Input.action_press("move_left", -strength_x)
		Input.action_release("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")
		
	if strength_y > 0.1:
		Input.action_press("move_backward", strength_y)
		Input.action_release("move_forward")
	elif strength_y < -0.1:
		Input.action_press("move_forward", -strength_y)
		Input.action_release("move_backward")
	else:
		Input.action_release("move_forward")
		Input.action_release("move_backward")

func reset_joystick():
	joystick_active = false
	joystick_touch_index = -1
	joystick_knob.position = joystick_center - Vector2(25, 25)
	
	Input.action_release("move_forward")
	Input.action_release("move_backward")
	Input.action_release("move_left")
	Input.action_release("move_right")

func _on_look_area_gui_input(event):
	if event is InputEventScreenDrag:
		if is_instance_valid(player) and not player.phone_active and not player.is_paused:
			player.apply_touch_look(event.relative)
