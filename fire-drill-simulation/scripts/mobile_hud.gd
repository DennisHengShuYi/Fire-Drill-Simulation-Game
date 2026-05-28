extends CanvasLayer

var player: CharacterBody3D = null

# UI Nodes created programmatically
var joystick_base: Panel = null
var joystick_knob: Panel = null
var look_area: Control = null
var crouch_btn: Button = null
var interact_btn: Button = null
var pause_btn: Button = null

# Secondary buttons stack
var secondary_container: VBoxContainer = null
var feel_btn: Button = null
var seal_btn: Button = null
var phone_btn: Button = null
var ext_btn: Button = null

# PASS minigame overlay
var pass_container: CenterContainer = null
var pass_btn: Button = null

# Joystick state variables
var joystick_active = false
var joystick_touch_index = -1
var joystick_center = Vector2(65, 65) # center of 130x130 base
var max_joystick_distance = 65.0

# Swipe camera look variables
var look_touch_index = -1

func _ready():
	# Keep processing even when paused so pause button and UI still work
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	setup_joystick()
	setup_look_area()
	setup_crouch_button()
	setup_interact_button()
	setup_pause_button()
	setup_secondary_buttons()
	setup_pass_minigame()
	
	# Connect to resize signals if any, or just rely on anchors
	get_viewport().size_changed.connect(on_viewport_resize)

func setup_joystick():
	# Joystick Base
	joystick_base = Panel.new()
	joystick_base.name = "JoystickBase"
	joystick_base.custom_minimum_size = Vector2(130, 130)
	
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color(0.15, 0.15, 0.15, 0.45)
	base_style.border_width_left = 3
	base_style.border_width_top = 3
	base_style.border_width_right = 3
	base_style.border_width_bottom = 3
	base_style.border_color = Color(0.85, 0.85, 0.85, 0.35)
	base_style.corner_radius_top_left = 65
	base_style.corner_radius_top_right = 65
	base_style.corner_radius_bottom_right = 65
	base_style.corner_radius_bottom_left = 65
	joystick_base.add_theme_stylebox_override("panel", base_style)
	
	# Anchor Bottom-Left: 20px offset
	joystick_base.anchor_left = 0.0
	joystick_base.anchor_top = 1.0
	joystick_base.anchor_right = 0.0
	joystick_base.anchor_bottom = 1.0
	joystick_base.offset_left = 30.0
	joystick_base.offset_top = -160.0
	joystick_base.offset_right = 160.0
	joystick_base.offset_bottom = -30.0
	joystick_base.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(joystick_base)
	
	# Joystick Knob
	joystick_knob = Panel.new()
	joystick_knob.name = "JoystickKnob"
	joystick_knob.custom_minimum_size = Vector2(55, 55)
	
	var knob_style = StyleBoxFlat.new()
	knob_style.bg_color = Color(0.95, 0.95, 0.95, 0.75)
	knob_style.corner_radius_top_left = 27
	knob_style.corner_radius_top_right = 27
	knob_style.corner_radius_bottom_right = 27
	knob_style.corner_radius_bottom_left = 27
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	
	joystick_base.add_child(joystick_knob)
	reset_joystick_knob_pos()
	
	# Connect base input signal
	joystick_base.gui_input.connect(_on_joystick_base_gui_input)

func reset_joystick_knob_pos():
	joystick_knob.position = joystick_center - Vector2(27.5, 27.5)

func setup_look_area():
	# Look Area Covers the right 55% of the screen
	look_area = Control.new()
	look_area.name = "LookArea"
	look_area.anchor_left = 0.45
	look_area.anchor_top = 0.0
	look_area.anchor_right = 1.0
	look_area.anchor_bottom = 1.0
	look_area.offset_left = 0.0
	look_area.offset_top = 0.0
	look_area.offset_right = 0.0
	look_area.offset_bottom = 0.0
	look_area.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(look_area)

func setup_crouch_button():
	crouch_btn = Button.new()
	crouch_btn.name = "BtnCrouch"
	crouch_btn.custom_minimum_size = Vector2(70, 70)
	crouch_btn.text = "▼"
	crouch_btn.add_theme_font_size_override("font_size", 24)
	
	var crouch_style = StyleBoxFlat.new()
	crouch_style.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	crouch_style.border_width_left = 2
	crouch_style.border_width_top = 2
	crouch_style.border_width_right = 2
	crouch_style.border_width_bottom = 2
	crouch_style.border_color = Color(1.0, 1.0, 1.0, 0.4)
	crouch_style.corner_radius_top_left = 35
	crouch_style.corner_radius_top_right = 35
	crouch_style.corner_radius_bottom_right = 35
	crouch_style.corner_radius_bottom_left = 35
	
	crouch_btn.add_theme_stylebox_override("normal", crouch_style)
	crouch_btn.add_theme_stylebox_override("hover", crouch_style)
	crouch_btn.add_theme_stylebox_override("pressed", crouch_style)
	crouch_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Bottom Center
	crouch_btn.anchor_left = 0.5
	crouch_btn.anchor_top = 1.0
	crouch_btn.anchor_right = 0.5
	crouch_btn.anchor_bottom = 1.0
	crouch_btn.offset_left = -35.0
	crouch_btn.offset_top = -90.0
	crouch_btn.offset_right = 35.0
	crouch_btn.offset_bottom = -20.0
	
	crouch_btn.pressed.connect(_on_crouch_pressed)
	add_child(crouch_btn)

func setup_interact_button():
	interact_btn = Button.new()
	interact_btn.name = "BtnInteract"
	interact_btn.custom_minimum_size = Vector2(90, 90)
	interact_btn.text = "INTERACT"
	interact_btn.add_theme_font_size_override("font_size", 12)
	interact_btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	var interact_style = StyleBoxFlat.new()
	interact_style.bg_color = Color(0.12, 0.5, 0.3, 0.7)
	interact_style.border_width_left = 3
	interact_style.border_width_top = 3
	interact_style.border_width_right = 3
	interact_style.border_width_bottom = 3
	interact_style.border_color = Color(0.2, 0.8, 0.5, 0.9)
	interact_style.corner_radius_top_left = 45
	interact_style.corner_radius_top_right = 45
	interact_style.corner_radius_bottom_right = 45
	interact_style.corner_radius_bottom_left = 45
	
	interact_btn.add_theme_stylebox_override("normal", interact_style)
	interact_btn.add_theme_stylebox_override("hover", interact_style)
	interact_btn.add_theme_stylebox_override("pressed", interact_style)
	interact_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Bottom Right
	interact_btn.anchor_left = 1.0
	interact_btn.anchor_top = 1.0
	interact_btn.anchor_right = 1.0
	interact_btn.anchor_bottom = 1.0
	interact_btn.offset_left = -120.0
	interact_btn.offset_top = -120.0
	interact_btn.offset_right = -30.0
	interact_btn.offset_bottom = -30.0
	
	interact_btn.pressed.connect(_on_interact_pressed)
	add_child(interact_btn)

func setup_pause_button():
	pause_btn = Button.new()
	pause_btn.name = "BtnPause"
	pause_btn.custom_minimum_size = Vector2(50, 50)
	pause_btn.text = "≡"
	pause_btn.add_theme_font_size_override("font_size", 22)
	
	var pause_style = StyleBoxFlat.new()
	pause_style.bg_color = Color(0.25, 0.25, 0.25, 0.5)
	pause_style.border_width_left = 2
	pause_style.border_width_top = 2
	pause_style.border_width_right = 2
	pause_style.border_width_bottom = 2
	pause_style.border_color = Color(1.0, 1.0, 1.0, 0.35)
	pause_style.corner_radius_top_left = 25
	pause_style.corner_radius_top_right = 25
	pause_style.corner_radius_bottom_right = 25
	pause_style.corner_radius_bottom_left = 25
	
	pause_btn.add_theme_stylebox_override("normal", pause_style)
	pause_btn.add_theme_stylebox_override("hover", pause_style)
	pause_btn.add_theme_stylebox_override("pressed", pause_style)
	pause_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Top Right
	pause_btn.anchor_left = 1.0
	pause_btn.anchor_top = 0.0
	pause_btn.anchor_right = 1.0
	pause_btn.anchor_bottom = 0.0
	pause_btn.offset_left = -70.0
	pause_btn.offset_top = 20.0
	pause_btn.offset_right = -20.0
	pause_btn.offset_bottom = 70.0
	
	pause_btn.pressed.connect(func():
		if is_instance_valid(player):
			player.toggle_pause()
	)
	add_child(pause_btn)

func setup_secondary_buttons():
	secondary_container = VBoxContainer.new()
	secondary_container.name = "SecondaryButtons"
	secondary_container.add_theme_constant_override("separation", 10)
	secondary_container.alignment = BoxContainer.ALIGNMENT_END
	
	secondary_container.anchor_left = 1.0
	secondary_container.anchor_top = 1.0
	secondary_container.anchor_right = 1.0
	secondary_container.anchor_bottom = 1.0
	secondary_container.offset_left = -280.0
	secondary_container.offset_top = -360.0
	secondary_container.offset_right = -140.0
	secondary_container.offset_bottom = -30.0
	add_child(secondary_container)
	
	# 1. Feel Door
	feel_btn = create_secondary_button("✋ Feel Door", Color(0.7, 0.45, 0.1, 0.8), Color(0.9, 0.6, 0.2, 0.95))
	feel_btn.pressed.connect(func(): send_action("feel_door"))
	secondary_container.add_child(feel_btn)
	feel_btn.visible = false
	
	# 2. Seal Door
	seal_btn = create_secondary_button("🧼 Seal Door", Color(0.1, 0.4, 0.6, 0.8), Color(0.2, 0.6, 0.85, 0.95))
	seal_btn.pressed.connect(func(): send_action("seal_door"))
	secondary_container.add_child(seal_btn)
	seal_btn.visible = false
	
	# 3. Phone [P]
	phone_btn = create_secondary_button("📞 Phone", Color(0.5, 0.2, 0.5, 0.8), Color(0.7, 0.3, 0.7, 0.95))
	phone_btn.pressed.connect(func():
		if is_instance_valid(player):
			player.open_phone_dialer()
	)
	secondary_container.add_child(phone_btn)
	phone_btn.visible = false
	
	# 4. Use Extinguisher 🧯
	ext_btn = create_secondary_button("🧯 Extinguish", Color(0.8, 0.15, 0.15, 0.8), Color(0.95, 0.3, 0.3, 0.95))
	ext_btn.pressed.connect(func():
		if is_instance_valid(player):
			player.try_use_extinguisher()
	)
	secondary_container.add_child(ext_btn)
	ext_btn.visible = false

func create_secondary_button(label_text: String, bg_col: Color, border_col: Color) -> Button:
	var btn = Button.new()
	btn.text = label_text
	btn.custom_minimum_size = Vector2(130, 48)
	btn.add_theme_font_size_override("font_size", 12)
	
	var style = StyleBoxFlat.new()
	style.bg_color = bg_col
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = border_col
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.corner_radius_bottom_left = 10
	
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn

func setup_pass_minigame():
	pass_container = CenterContainer.new()
	pass_container.name = "PassMinigame"
	pass_container.anchor_left = 0.0
	pass_container.anchor_top = 0.0
	pass_container.anchor_right = 1.0
	pass_container.anchor_bottom = 1.0
	pass_container.offset_left = 0.0
	pass_container.offset_top = 0.0
	pass_container.offset_right = 0.0
	pass_container.offset_bottom = 0.0
	add_child(pass_container)
	pass_container.visible = false
	
	pass_btn = Button.new()
	pass_btn.custom_minimum_size = Vector2(220, 220)
	pass_btn.text = "PULL"
	pass_btn.add_theme_font_size_override("font_size", 24)
	
	var pass_style = StyleBoxFlat.new()
	pass_style.bg_color = Color(0.85, 0.2, 0.1, 0.8)
	pass_style.border_width_left = 5
	pass_style.border_width_top = 5
	pass_style.border_width_right = 5
	pass_style.border_width_bottom = 5
	pass_style.border_color = Color(1.0, 0.45, 0.2, 0.95)
	pass_style.corner_radius_top_left = 110
	pass_style.corner_radius_top_right = 110
	pass_style.corner_radius_bottom_right = 110
	pass_style.corner_radius_bottom_left = 110
	
	pass_btn.add_theme_stylebox_override("normal", pass_style)
	pass_btn.add_theme_stylebox_override("hover", pass_style)
	pass_btn.add_theme_stylebox_override("pressed", pass_style)
	pass_btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	pass_btn.pressed.connect(_on_pass_pressed)
	pass_container.add_child(pass_btn)

func on_viewport_resize():
	# Make sure anchors remain intact and update limits if needed
	pass

func _process(_delta):
	if not is_instance_valid(player):
		return
		
	# 1. Update Crouch Button visual state
	var crouch_style = crouch_btn.get_theme_stylebox("normal") as StyleBoxFlat
	if crouch_style:
		if player.is_crouching:
			crouch_style.bg_color = Color(0.9, 0.45, 0.1, 0.8)
			crouch_style.border_color = Color(1.0, 0.65, 0.2, 0.95)
		else:
			crouch_style.bg_color = Color(0.2, 0.2, 0.2, 0.5)
			crouch_style.border_color = Color(1.0, 1.0, 1.0, 0.4)
			
	# 2. Update Interact Button label
	var raw_prompt = player.prompt_label.text
	var cleaned = clean_prompt(raw_prompt)
	interact_btn.text = cleaned
	
	# Interact Button is disabled/greyed out if no interactable is hovered (unless holding extinguisher)
	var interact_style = interact_btn.get_theme_stylebox("normal") as StyleBoxFlat
	if cleaned == "[E]":
		if player.has_extinguisher:
			interact_btn.text = "🧯 USE EXTINGUISHER"
			interact_btn.disabled = false
			if interact_style:
				interact_style.bg_color = Color(0.8, 0.15, 0.15, 0.75)
				interact_style.border_color = Color(0.95, 0.3, 0.3, 0.95)
		else:
			interact_btn.text = "INTERACT"
			interact_btn.disabled = true
			if interact_style:
				interact_style.bg_color = Color(0.1, 0.1, 0.1, 0.4)
				interact_style.border_color = Color(0.3, 0.3, 0.3, 0.4)
	else:
		interact_btn.disabled = false
		if interact_style:
			interact_style.bg_color = Color(0.12, 0.5, 0.3, 0.7)
			interact_style.border_color = Color(0.2, 0.8, 0.5, 0.9)
			
	# 3. Update Secondary Contextual Buttons Visibility
	update_secondary_button_states()
	
	# 4. PASS Minigame State
	if player.in_extinguisher_minigame:
		pass_container.visible = true
		crouch_btn.visible = false
		interact_btn.visible = false
		joystick_base.visible = false
		
		# Pulse the pass button size/color slightly to catch eye
		var time = Time.get_ticks_msec() * 0.005
		var pulse = 1.0 + sin(time) * 0.05
		pass_btn.scale = Vector2(pulse, pulse)
		pass_btn.pivot_offset = pass_btn.size / 2.0
		
		var step = player.minigame_step
		if step == 0:
			pass_btn.text = "PULL 📌"
		elif step == 1:
			pass_btn.text = "AIM 🎯"
		elif step == 2:
			pass_btn.text = "SQUEEZE 🤜"
		elif step == 3:
			pass_btn.text = "SWEEP ↔️"
	else:
		pass_container.visible = false
		crouch_btn.visible = true
		interact_btn.visible = true
		joystick_base.visible = true

func clean_prompt(text: String) -> String:
	if text == "":
		return "[E]"
	var clean = text
	clean = clean.replace("[E] ", "").replace("[E]", "")
	clean = clean.replace("[F] ", "").replace("[F]", "")
	clean = clean.replace("[X] ", "").replace("[X]", "")
	clean = clean.replace("[K] ", "").replace("[K]", "")
	clean = clean.replace(" (Malaysia Emergency: 999)", "")
	# Strip additional keys
	clean = clean.replace("[Left-Click] or [E] ", "")
	
	# Split by comma if it list key options e.g. "Try Door (Locked), Knock on Door"
	if "," in clean:
		clean = clean.split(",")[0]
		
	return clean.strip_edges().to_upper()

func update_secondary_button_states():
	var feel_visible = false
	var seal_visible = false
	var phone_visible = false
	var ext_visible = false
	
	if not player.phone_active and not player.is_paused and not player.in_elevator_sequence and not player.climbing_ladder:
		# Check if looking at an interactable door
		if player.raycast.is_colliding():
			var col = player.raycast.get_collider()
			if col is Interactable:
				if col.is_door and col.can_feel and not col.door_opened:
					feel_visible = true
				if not col.door_opened and col.name.to_lower().contains("bedroom") and not col.is_sealed and player.has_wet_towel:
					seal_visible = true
					
		# Check phone visibility
		if player.has_mobile_phone and not player.has_called_bomba:
			phone_visible = true
			
		# Check extinguisher use visibility (when fire is nearby)
		if player.has_extinguisher and not player.in_extinguisher_minigame:
			var nearest_fire = player.get_nearest_fire()
			if nearest_fire and player.global_position.distance_to(nearest_fire.global_position) <= 4.5:
				ext_visible = true
				
	# Animate transition on secondary buttons
	animate_button_vis(feel_btn, feel_visible)
	animate_button_vis(seal_btn, seal_visible)
	animate_button_vis(phone_btn, phone_visible)
	animate_button_vis(ext_btn, ext_visible)

func animate_button_vis(btn: Button, target_vis: bool):
	if btn.visible == target_vis:
		return
	if target_vis:
		btn.visible = true
		btn.modulate.a = 0.0
		btn.scale = Vector2(0.85, 0.85)
		btn.pivot_offset = btn.size / 2.0
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "modulate:a", 1.0, 0.15)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "modulate:a", 0.0, 0.12)
		tween.tween_property(btn, "scale", Vector2(0.85, 0.85), 0.12)
		tween.chain().tween_callback(func(): btn.visible = false)

func _input(event):
	if not is_instance_valid(player) or player.is_paused:
		return
		
	# Global input index checks to handle movement dragging and camera rotation dragging
	if event is InputEventScreenTouch:
		if event.pressed:
			# Look swipe area starts if touch is in right 55% of the viewport and not on other buttons
			if event.position.x > get_viewport().size.x * 0.45:
				if look_touch_index == -1 and event.index != joystick_touch_index:
					look_touch_index = event.index
		else:
			if event.index == joystick_touch_index:
				reset_joystick()
			elif event.index == look_touch_index:
				look_touch_index = -1
				
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index:
			# Localize coordinates for knob calculation
			var local_pos = joystick_base.make_input_local(event).position
			update_joystick_knob(local_pos)
		elif event.index == look_touch_index:
			# Rotate camera
			if not player.phone_active and not player.dilemma_active and not player.in_elevator_sequence:
				player.apply_touch_look(event.relative)

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

func update_joystick_knob(pos: Vector2):
	var offset = pos - joystick_center
	var distance = offset.length()
	
	if distance > max_joystick_distance:
		offset = offset.normalized() * max_joystick_distance
		
	joystick_knob.position = (joystick_center - Vector2(27.5, 27.5)) + offset
	
	var norm_dir = offset / max_joystick_distance
	var strength_x = norm_dir.x
	var strength_y = norm_dir.y
	
	# Simulate movement axis values
	if strength_x > 0.15:
		_parse_action("move_right", true, strength_x)
		_parse_action("move_left", false, 0.0)
	elif strength_x < -0.15:
		_parse_action("move_left", true, -strength_x)
		_parse_action("move_right", false, 0.0)
	else:
		_parse_action("move_left", false, 0.0)
		_parse_action("move_right", false, 0.0)
		
	if strength_y > 0.15:
		_parse_action("move_backward", true, strength_y)
		_parse_action("move_forward", false, 0.0)
	elif strength_y < -0.15:
		_parse_action("move_forward", true, -strength_y)
		_parse_action("move_backward", false, 0.0)
	else:
		_parse_action("move_forward", false, 0.0)
		_parse_action("move_backward", false, 0.0)
		
	# Sprint check - Outer 30% of analog range triggers sprint
	if (distance / max_joystick_distance) >= 0.7:
		_parse_action("sprint", true, 1.0)
	else:
		_parse_action("sprint", false, 0.0)

func reset_joystick():
	joystick_active = false
	joystick_touch_index = -1
	reset_joystick_knob_pos()
	
	_parse_action("move_forward", false, 0.0)
	_parse_action("move_backward", false, 0.0)
	_parse_action("move_left", false, 0.0)
	_parse_action("move_right", false, 0.0)
	_parse_action("sprint", false, 0.0)

func _parse_action(action_name: String, pressed: bool, strength: float):
	var ev = InputEventAction.new()
	ev.action = action_name
	ev.pressed = pressed
	ev.strength = strength
	Input.parse_input_event(ev)

func send_action(action_name: String):
	_parse_action(action_name, true, 1.0)
	await get_tree().create_timer(0.08).timeout
	_parse_action(action_name, false, 0.0)

func _on_crouch_pressed():
	send_action("crouch")

func _on_interact_pressed():
	if is_instance_valid(player) and player.has_extinguisher and not player.in_extinguisher_minigame:
		# Directly call use extinguisher if carrying it
		player.try_use_extinguisher()
	else:
		send_action("interact")

func _on_pass_pressed():
	if not is_instance_valid(player) or not player.in_extinguisher_minigame:
		return
		
	var expected_keys = [KEY_P, KEY_A, KEY_S, KEY_S]
	var step = player.minigame_step
	if step >= 0 and step < expected_keys.size():
		player.process_minigame_key(expected_keys[step])
