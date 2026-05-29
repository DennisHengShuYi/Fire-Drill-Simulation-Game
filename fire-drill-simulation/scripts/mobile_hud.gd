extends CanvasLayer

var player: CharacterBody3D = null

# StyleBox pre-instantiations to prevent UI redraw lag
var style_crouch_normal: StyleBoxFlat = null
var style_crouch_active: StyleBoxFlat = null
var style_interact_normal: StyleBoxFlat = null
var style_interact_disabled: StyleBoxFlat = null
var style_interact_extinguisher: StyleBoxFlat = null

# State tracking to only update StyleBox overrides on transition
var _last_crouch_state: bool = false
var _last_interact_state: String = ""

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
var joystick_center = Vector2(90, 90) # center of 180x180 base
var max_joystick_distance = 90.0
var joystick_touch_start = Vector2.ZERO

# Swipe camera look variables
var look_touch_index = -1

# Crosshair node
var crosshair: Control = null

func _ready():
	# Keep processing even when paused so pause button and UI still work
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	initialize_styleboxes()
	setup_joystick()
	setup_look_area()
	setup_crouch_button()
	setup_interact_button()
	setup_pause_button()
	setup_secondary_buttons()
	setup_pass_minigame()
	setup_crosshair()
	
	# Connect to resize signals if any, or just rely on anchors
	get_viewport().size_changed.connect(on_viewport_resize)

func initialize_styleboxes():
	# Crouch normal style
	style_crouch_normal = StyleBoxFlat.new()
	style_crouch_normal.bg_color = Color(0.2, 0.2, 0.2, 0.5)
	style_crouch_normal.border_width_left = 2
	style_crouch_normal.border_width_top = 2
	style_crouch_normal.border_width_right = 2
	style_crouch_normal.border_width_bottom = 2
	style_crouch_normal.border_color = Color(1.0, 1.0, 1.0, 0.4)
	style_crouch_normal.corner_radius_top_left = 35
	style_crouch_normal.corner_radius_top_right = 35
	style_crouch_normal.corner_radius_bottom_right = 35
	style_crouch_normal.corner_radius_bottom_left = 35
	
	# Crouch active style
	style_crouch_active = StyleBoxFlat.new()
	style_crouch_active.bg_color = Color(0.9, 0.45, 0.1, 0.8)
	style_crouch_active.border_width_left = 2
	style_crouch_active.border_width_top = 2
	style_crouch_active.border_width_right = 2
	style_crouch_active.border_width_bottom = 2
	style_crouch_active.border_color = Color(1.0, 0.65, 0.2, 0.95)
	style_crouch_active.corner_radius_top_left = 35
	style_crouch_active.corner_radius_top_right = 35
	style_crouch_active.corner_radius_bottom_right = 35
	style_crouch_active.corner_radius_bottom_left = 35
	
	# Interact normal style
	style_interact_normal = StyleBoxFlat.new()
	style_interact_normal.bg_color = Color(0.12, 0.5, 0.3, 0.7)
	style_interact_normal.border_width_left = 3
	style_interact_normal.border_width_top = 3
	style_interact_normal.border_width_right = 3
	style_interact_normal.border_width_bottom = 3
	style_interact_normal.border_color = Color(0.2, 0.8, 0.5, 0.9)
	style_interact_normal.corner_radius_top_left = 45
	style_interact_normal.corner_radius_top_right = 45
	style_interact_normal.corner_radius_bottom_right = 45
	style_interact_normal.corner_radius_bottom_left = 45
	
	# Interact disabled style
	style_interact_disabled = StyleBoxFlat.new()
	style_interact_disabled.bg_color = Color(0.1, 0.1, 0.1, 0.4)
	style_interact_disabled.border_width_left = 3
	style_interact_disabled.border_width_top = 3
	style_interact_disabled.border_width_right = 3
	style_interact_disabled.border_width_bottom = 3
	style_interact_disabled.border_color = Color(0.3, 0.3, 0.3, 0.4)
	style_interact_disabled.corner_radius_top_left = 45
	style_interact_disabled.corner_radius_top_right = 45
	style_interact_disabled.corner_radius_bottom_right = 45
	style_interact_disabled.corner_radius_bottom_left = 45
	
	# Interact extinguisher style
	style_interact_extinguisher = StyleBoxFlat.new()
	style_interact_extinguisher.bg_color = Color(0.8, 0.15, 0.15, 0.75)
	style_interact_extinguisher.border_width_left = 3
	style_interact_extinguisher.border_width_top = 3
	style_interact_extinguisher.border_width_right = 3
	style_interact_extinguisher.border_width_bottom = 3
	style_interact_extinguisher.border_color = Color(0.95, 0.3, 0.3, 0.95)
	style_interact_extinguisher.corner_radius_top_left = 45
	style_interact_extinguisher.corner_radius_top_right = 45
	style_interact_extinguisher.corner_radius_bottom_right = 45
	style_interact_extinguisher.corner_radius_bottom_left = 45

func setup_joystick():
	# Joystick Base — 180x180, anchored bottom-left clear of objectives panel
	joystick_base = Panel.new()
	joystick_base.name = "JoystickBase"
	joystick_base.custom_minimum_size = Vector2(180, 180)
	
	var base_style = StyleBoxFlat.new()
	base_style.bg_color = Color(0.15, 0.15, 0.15, 0.5)
	base_style.border_width_left = 3
	base_style.border_width_top = 3
	base_style.border_width_right = 3
	base_style.border_width_bottom = 3
	base_style.border_color = Color(0.85, 0.85, 0.85, 0.45)
	base_style.corner_radius_top_left = 90
	base_style.corner_radius_top_right = 90
	base_style.corner_radius_bottom_right = 90
	base_style.corner_radius_bottom_left = 90
	joystick_base.add_theme_stylebox_override("panel", base_style)
	
	# Anchor Bottom-Left: push up higher so it doesn't overlap the objectives panel
	joystick_base.anchor_left = 0.0
	joystick_base.anchor_top = 1.0
	joystick_base.anchor_right = 0.0
	joystick_base.anchor_bottom = 1.0
	joystick_base.offset_left = 20.0
	joystick_base.offset_top = -270.0
	joystick_base.offset_right = 200.0
	joystick_base.offset_bottom = -90.0
	joystick_base.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(joystick_base)
	
	# Joystick Knob — larger knob for bigger base
	joystick_knob = Panel.new()
	joystick_knob.name = "JoystickKnob"
	joystick_knob.custom_minimum_size = Vector2(70, 70)
	
	var knob_style = StyleBoxFlat.new()
	knob_style.bg_color = Color(0.95, 0.95, 0.95, 0.8)
	knob_style.corner_radius_top_left = 35
	knob_style.corner_radius_top_right = 35
	knob_style.corner_radius_bottom_right = 35
	knob_style.corner_radius_bottom_left = 35
	joystick_knob.add_theme_stylebox_override("panel", knob_style)
	
	joystick_base.add_child(joystick_knob)
	reset_joystick_knob_pos()
	
	# Connect base input signal
	joystick_base.gui_input.connect(_on_joystick_base_gui_input)

func reset_joystick_knob_pos():
	joystick_knob.position = joystick_center - Vector2(35, 35)

func setup_look_area():
	# Look Area covers the FULL screen — joystick takes priority via index tracking
	look_area = Control.new()
	look_area.name = "LookArea"
	look_area.anchor_left = 0.0
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
	
	crouch_btn.add_theme_stylebox_override("normal", style_crouch_normal)
	crouch_btn.add_theme_stylebox_override("hover", style_crouch_normal)
	crouch_btn.add_theme_stylebox_override("pressed", style_crouch_normal)
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
	_last_crouch_state = false

func setup_interact_button():
	interact_btn = Button.new()
	interact_btn.name = "BtnInteract"
	interact_btn.custom_minimum_size = Vector2(90, 90)
	interact_btn.text = "INTERACT"
	interact_btn.add_theme_font_size_override("font_size", 12)
	interact_btn.autowrap_mode = TextServer.AUTOWRAP_WORD
	
	interact_btn.add_theme_stylebox_override("normal", style_interact_normal)
	interact_btn.add_theme_stylebox_override("hover", style_interact_normal)
	interact_btn.add_theme_stylebox_override("pressed", style_interact_normal)
	interact_btn.add_theme_stylebox_override("disabled", style_interact_normal)
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
	_last_interact_state = "normal"

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

func setup_crosshair():
	# Dot crosshair at the center of the screen
	crosshair = Control.new()
	crosshair.name = "Crosshair"
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -12.0
	crosshair.offset_top = -12.0
	crosshair.offset_right = 12.0
	crosshair.offset_bottom = 12.0
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Draw a simple dot using a ColorRect centered in the control
	var dot = ColorRect.new()
	dot.color = Color(1.0, 1.0, 1.0, 0.85)
	dot.size = Vector2(6, 6)
	dot.position = Vector2(9, 9) # center of 24x24 control
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Horizontal bar
	var h_bar = ColorRect.new()
	h_bar.color = Color(1.0, 1.0, 1.0, 0.6)
	h_bar.size = Vector2(16, 2)
	h_bar.position = Vector2(4, 11)
	h_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Vertical bar
	var v_bar = ColorRect.new()
	v_bar.color = Color(1.0, 1.0, 1.0, 0.6)
	v_bar.size = Vector2(2, 16)
	v_bar.position = Vector2(11, 4)
	v_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	crosshair.add_child(h_bar)
	crosshair.add_child(v_bar)
	crosshair.add_child(dot)
	add_child(crosshair)

func on_viewport_resize():
	# Make sure anchors remain intact and update limits if needed
	pass

var _hud_tick: float = 0.0

func _process(delta):
	if not is_instance_valid(player):
		return
	# Throttle HUD updates to 20Hz — sufficient for UI feedback, saves ~66% of _process overhead
	_hud_tick += delta
	if _hud_tick < 0.05:
		return
	_hud_tick = 0.0
	
	# 1. Update Crouch Button visual state on transition
	var current_crouch = player.is_crouching
	if current_crouch != _last_crouch_state:
		_last_crouch_state = current_crouch
		var style = style_crouch_active if current_crouch else style_crouch_normal
		crouch_btn.add_theme_stylebox_override("normal", style)
		crouch_btn.add_theme_stylebox_override("hover", style)
		crouch_btn.add_theme_stylebox_override("pressed", style)
			
	# 2. Update Interact Button label & state
	var raw_prompt = player.prompt_label.text
	var cleaned = clean_prompt(raw_prompt)
	
	var target_text: String = ""
	var target_disabled: bool = false
	var target_style_state: String = ""
	
	if cleaned == "[E]":
		if player.has_extinguisher:
			target_text = "🧯 USE EXTINGUISHER"
			target_disabled = false
			target_style_state = "extinguisher"
		else:
			target_text = "INTERACT"
			target_disabled = true
			target_style_state = "disabled"
	else:
		target_text = cleaned
		target_disabled = false
		target_style_state = "normal"
		
	if interact_btn.text != target_text:
		interact_btn.text = target_text
		
	if interact_btn.disabled != target_disabled:
		interact_btn.disabled = target_disabled
		
	if _last_interact_state != target_style_state:
		_last_interact_state = target_style_state
		var style: StyleBoxFlat = null
		match target_style_state:
			"extinguisher":
				style = style_interact_extinguisher
			"disabled":
				style = style_interact_disabled
			"normal":
				style = style_interact_normal
		if style:
			interact_btn.add_theme_stylebox_override("normal", style)
			interact_btn.add_theme_stylebox_override("hover", style)
			interact_btn.add_theme_stylebox_override("pressed", style)
			interact_btn.add_theme_stylebox_override("disabled", style)
			
	# 3. Update Secondary Contextual Buttons Visibility
	update_secondary_button_states()
	
	# 4. Phone active OR dilemma active — hide joystick/look so panel buttons are tappable
	if player.phone_active or player.dilemma_active:
		joystick_base.visible = false
		look_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
		crouch_btn.visible = false
		interact_btn.visible = false
		if crosshair:
			crosshair.visible = false
		return
	else:
		if crosshair:
			crosshair.visible = true
		look_area.mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 5. PASS Minigame State
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
		
	# Ignore all touch drag inputs during modal overlays (phone, dilemma dialogue, or PASS minigame)
	if player.phone_active or player.dilemma_active or player.in_extinguisher_minigame:
		return
		
	# Handle all touch events globally for both joystick and camera look
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if touch is on/near the fixed joystick base icon (with a slight tolerance buffer)
			var joy_screen_center = joystick_base.get_global_rect().get_center()
			if event.position.distance_to(joy_screen_center) <= max_joystick_distance * 1.2:
				if joystick_touch_index == -1:
					joystick_active = true
					joystick_touch_index = event.index
					joystick_touch_start = joy_screen_center
					var offset = event.position - joystick_touch_start
					update_joystick_knob(joystick_center + offset)
			# Any touch not on/near the joystick base acts as the camera look drag (full screen drag zone)
			elif look_touch_index == -1 and event.index != joystick_touch_index:
				look_touch_index = event.index
		else:
			if event.index == joystick_touch_index:
				reset_joystick()
			elif event.index == look_touch_index:
				look_touch_index = -1
				
	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_index:
			# Map drag position relative to initial touch start position (joystick base center)
			var offset = event.position - joystick_touch_start
			update_joystick_knob(joystick_center + offset)
		elif event.index == look_touch_index:
			if not player.phone_active and not player.dilemma_active and not player.in_elevator_sequence:
				player.apply_touch_look(event.relative)

func _on_joystick_base_gui_input(event):
	# Input is handled globally in _input() for wide touch detection
	pass

func update_joystick_knob(pos: Vector2):
	var offset = pos - joystick_center
	var distance = offset.length()
	
	if distance > max_joystick_distance:
		offset = offset.normalized() * max_joystick_distance
		
	joystick_knob.position = (joystick_center - Vector2(35, 35)) + offset
	
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
		
	# Sprint check - Outer 10% of analog range triggers sprint (push joystick to the very edge)
	if (distance / max_joystick_distance) >= 0.9:
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
	if pressed:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)

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
