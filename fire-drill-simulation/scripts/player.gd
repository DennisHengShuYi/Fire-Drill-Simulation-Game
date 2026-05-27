extends CharacterBody3D

@export var speed: float = 3.5
@export var sprint_speed: float = 5.0
@export var gravity: float = 9.8
@export var mouse_sensitivity: float = 0.002

@export var stand_height: float = 1.8
@export var crouch_height: float = 0.9
@export var crouch_speed: float = 2.0

var max_oxygen: float = 100.0
var current_oxygen: float = 100.0
var in_smoke_zone: bool = false
var in_fire_zone: bool = false
var cough_timer: float = 0.0
var burn_sound_cooldown: float = 0.0

@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var prompt_label: Label = $HUD/PromptLabel
@onready var oxygen_bar: ProgressBar = $HUD/OxygenPanel/OxygenBar
@onready var log_label: Label = $HUD/LogPanel/LogLabel
@onready var smoke_overlay: ColorRect = $HUD/SmokeOverlay
@onready var phone_panel: Panel = $HUD/PhonePanel
@onready var phone_display: Label = $HUD/PhonePanel/Display
@onready var phone_instructions: Label = $HUD/PhonePanel/Instructions

var is_crouching: bool = false
var mouse_captured: bool = true
var log_timer: float = 0.0
var phone_active: bool = false
var dialed_number: String = ""
var call_state: int = 0

@export var teleport_target_pos: Vector3 = Vector3(0, 0, 0)
var is_outside: bool = false
var has_shown_crouch_tip: bool = false
var has_wet_towel: bool = false
var _wet_towel_shown: bool = false

@export var time_limit: float = 90.0
var current_time: float
var is_timer_active: bool = true
var timer_label: Label = null
var timer_last_second: int = -1
var in_elevator_sequence: bool = false
var dilemma_active: bool = false
var dilemma_door: Node = null

# --- Pause ---
var is_paused: bool = false
var pause_panel: Panel = null
var _pause_obj_label: Label = null

# --- Objectives tracker ---
var objectives_panel: Panel = null
var objectives_label: Label = null
var objectives_visible: bool = true
var obj_refresh_timer: float = 0.0

# --- Wet towel HUD ---
var wet_towel_label: Label = null

# --- Vignette ---
var vignette_overlay: ColorRect = null

# --- Stamina ---
var max_stamina: float = 100.0
var current_stamina: float = 100.0
var can_sprint: bool = true
var stamina_bar_panel: Panel = null
var stamina_bar: ProgressBar = null

# --- Contextual tips ---
var shown_tips: Dictionary = {}
var tip_check_timer: float = 0.0

func _ready():
	# BUG 3 companion: keep this node processing even when the tree is paused
	# so ESC and the quit button still work inside the pause panel.
	process_mode = Node.PROCESS_MODE_ALWAYS

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	phone_panel.visible = false
	smoke_overlay.color.a = 0.0

	for btn in $HUD/PhonePanel/GridContainer.get_children():
		if btn is Button:
			if btn.name in ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]:
				var num = btn.name
				btn.pressed.connect(func(): press_number(num))
			elif btn.name == "BtnClear":
				btn.pressed.connect(clear_dialer)
			elif btn.name == "BtnCall":
				btn.pressed.connect(call_dialer)

	current_time = time_limit
	# teleport_target_pos is set via @export in the scene inspector (level.tscn).

	setup_timer_hud()
	setup_vignette()
	setup_wet_towel_hud()
	setup_stamina_hud()
	setup_objectives_panel()
	setup_pause_panel()

	show_log_message("FIRE ALARM RINGING! Find a way out safely!")

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _input(event):
	# ESC toggles pause (works even during phone UI since it was previously
	# only releasing mouse without any feedback).
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not phone_active:
			toggle_pause()
		return

	if is_paused:
		return

	# Tab toggles the objectives panel for players who prefer immersion.
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		if objectives_panel:
			objectives_visible = not objectives_visible
			objectives_panel.visible = objectives_visible
		return

	if phone_active:
		return

	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

func toggle_pause():
	is_paused = not is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		get_tree().paused = true
		if pause_panel:
			_update_pause_objectives()
			pause_panel.visible = true
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		get_tree().paused = false
		if pause_panel:
			pause_panel.visible = false

# ---------------------------------------------------------------------------
# Physics process
# ---------------------------------------------------------------------------

func _physics_process(delta):
	if not is_inside_tree():
		return
	if dilemma_active:
		velocity = Vector3.ZERO
		move_and_slide()
		if dilemma_door:
			prompt_label.text = "HELP NEIGHBOR? [1] Wait & Rescue (costs 15s) | [2] Advise to use Balcony Exit"
		if Input.is_action_just_pressed("dilemma_1"):
			dilemma_active = false
			if dilemma_door and dilemma_door.has_method("resolve_dilemma"):
				dilemma_door.resolve_dilemma(self, 1)
		elif Input.is_action_just_pressed("dilemma_2"):
			dilemma_active = false
			if dilemma_door and dilemma_door.has_method("resolve_dilemma"):
				dilemma_door.resolve_dilemma(self, 2)
		return

	if phone_active or in_elevator_sequence:
		velocity = Vector3.ZERO
		move_and_slide()
		if in_elevator_sequence:
			camera.position.x = randf_range(-0.015, 0.015)
			camera.position.y = lerp(camera.position.y, stand_height - 0.2 + randf_range(-0.015, 0.015), 5.0 * delta)
		return

	if is_paused:
		return

	# Timer countdown
	if is_timer_active:
		current_time -= delta
		if current_time <= 0.0:
			current_time = 0.0
			is_timer_active = false
			GameManager.trigger_game_over(
				"You ran out of time! The fire spread and trapped you in the building.",
				"BOMBA TIP: Fire spreads incredibly fast — often in less than 2-3 minutes. Never delay your evacuation to collect belongings. Every second counts!"
			)

		if timer_label:
			var minutes = int(current_time) / 60
			var seconds = int(current_time) % 60
			timer_label.text = "%02d:%02d" % [minutes, seconds]

			var cur_sec = int(current_time)
			if current_time < 30.0:
				var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
				timer_label.add_theme_color_override("font_color", Color(1.0, 0.2 + pulse * 0.4, 0.2 + pulse * 0.4))

				# Experience 5: tick beep every second below 15 s
				if current_time < 15.0 and cur_sec != timer_last_second:
					timer_last_second = cur_sec
					play_tick_beep()

				# Experience 5: flash the label below 10 s
				if current_time < 10.0:
					timer_label.modulate.a = 1.0 if (int(Time.get_ticks_msec() / 500) % 2 == 0) else 0.0
				else:
					timer_label.modulate.a = 1.0
			else:
				timer_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
				timer_label.modulate.a = 1.0

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Crouch (Toggle Style: one press to toggle)
	if Input.is_action_just_pressed("crouch"):
		is_crouching = not is_crouching
	
	# Sprinting cancels crouch automatically if moving
	if is_crouching and Input.is_action_pressed("sprint") and can_sprint and velocity.length() > 0.1:
		is_crouching = false

	var target_height = crouch_height if is_crouching else stand_height
	if is_crouching and in_smoke_zone:
		GameManager.crouched_in_smoke = true


	var current_capsule: CapsuleShape3D = collision_shape.shape
	current_capsule.height = lerp(current_capsule.height, target_height, crouch_speed * delta)
	camera.position.y = lerp(camera.position.y, target_height - 0.2, crouch_speed * delta)
	camera.position.x = lerp(camera.position.x, 0.0, 8.0 * delta)

	# Movement input
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"): input_dir.y -= 1
	if Input.is_action_pressed("move_backward"): input_dir.y += 1
	if Input.is_action_pressed("move_left"): input_dir.x -= 1
	if Input.is_action_pressed("move_right"): input_dir.x += 1

	var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Experience 3: Stamina system — sprinting indefinitely trivialises time
	# pressure and smoke avoidance. Teaching controlled movement is part of
	# fire safety (panic-running causes falls and wasted oxygen).
	var current_speed = speed
	if is_crouching:
		current_speed = speed * 0.5
	elif Input.is_action_pressed("sprint") and can_sprint:
		current_speed = sprint_speed
		current_stamina -= 20.0 * delta
		if current_stamina <= 0.0:
			current_stamina = 0.0
			can_sprint = false
			show_log_message("Out of breath! Keep moving steadily.")
	else:
		current_stamina = move_toward(current_stamina, max_stamina, 10.0 * delta)
		if not can_sprint and current_stamina >= 30.0:
			can_sprint = true

	update_stamina_hud()

	if dir:
		velocity.x = dir.x * current_speed
		velocity.z = dir.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	check_interaction()
	process_smoke_inhalation(delta)

	# Experience 4: Contextual BOMBA tips (throttled to 0.5 s)
	tip_check_timer -= delta
	if tip_check_timer <= 0.0:
		tip_check_timer = 0.5
		_check_contextual_tips()

	# Objective tracker refresh every 2 s to avoid per-frame overhead
	obj_refresh_timer -= delta
	if obj_refresh_timer <= 0.0:
		obj_refresh_timer = 2.0
		_update_objectives()

	# Log fade
	if log_timer > 0.0:
		log_timer -= delta
		if log_timer <= 0.0:
			log_label.text = ""

# ---------------------------------------------------------------------------
# Interaction
# ---------------------------------------------------------------------------

func check_interaction():
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider is Interactable:
			prompt_label.text = collider.get_interact_prompt()
			if Input.is_action_just_pressed("interact"):
				collider.interact(self)
			elif Input.is_action_just_pressed("feel_door"):
				var feel_msg = collider.feel(self)
				show_log_message(feel_msg)
			elif Input.is_action_just_pressed("knock_door") and collider.has_method("knock"):
				collider.knock(self)
			return
	prompt_label.text = ""

# ---------------------------------------------------------------------------
# Smoke / Oxygen
# ---------------------------------------------------------------------------

func process_smoke_inhalation(delta):
	# Fire zone damage & visual/audio feedback
	if burn_sound_cooldown > 0.0:
		burn_sound_cooldown -= delta

	if in_fire_zone:
		current_oxygen -= 45.0 * delta
		
		# High-frequency screen shake
		camera.position.x += randf_range(-0.08, 0.08)
		camera.position.y += randf_range(-0.08, 0.08)
		
		if burn_sound_cooldown <= 0.0:
			burn_sound_cooldown = 0.8
			show_log_message("*BURN* Stepping too close to the fire!")
			play_burn_sound()
			
		# Check death by fire
		if current_oxygen <= 0.0:
			current_oxygen = 0.0
			is_timer_active = false
			GameManager.trigger_game_over(
				"You got too close to the fire and suffered severe burns!",
				"BOMBA TIP: House fires can exceed 600°C (1100°F) in minutes, producing extreme thermal radiation that causes instant severe burns. Never approach the fire source to collect belongings. Keep a safe distance and evacuate immediately!"
			)
			return

	elif in_smoke_zone:
		if not has_shown_crouch_tip:
			has_shown_crouch_tip = true
			show_log_message("Stay low! Crouch (C or Ctrl) to reduce smoke inhalation.")

		var multiplier = 0.5 if has_wet_towel else 1.0

		if not is_crouching:
			current_oxygen -= 15.0 * delta * multiplier
			GameManager.stood_up_in_smoke = true
			cough_timer += delta
			if cough_timer >= 1.5:
				cough_timer = 0.0
				show_log_message("*COUGH* Heavy smoke! Stay Low (Crouch)!")
				play_cough_sound()
				camera.position.x += randf_range(-0.05, 0.05)
				camera.position.y += randf_range(-0.05, 0.05)
		else:
			current_oxygen -= 1.0 * delta * multiplier
	else:
		current_oxygen = move_toward(current_oxygen, max_oxygen, 5.0 * delta)

	current_oxygen = clamp(current_oxygen, 0.0, max_oxygen)
	oxygen_bar.value = current_oxygen

	# Experience 1: show wet towel label when first obtained
	if has_wet_towel and not _wet_towel_shown:
		_wet_towel_shown = true
		if wet_towel_label:
			wet_towel_label.visible = true

	var hud_label = $HUD/OxygenPanel/Label
	if has_wet_towel:
		hud_label.text = "Oxygen (Wet Towel Active)"
		hud_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	else:
		hud_label.text = "Oxygen / Air Supply"
		hud_label.remove_theme_color_override("font_color")

	if current_oxygen < 25.0:
		var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
		oxygen_bar.modulate = Color(1.0, 0.2 + pulse * 0.4, 0.2 + pulse * 0.4)
	else:
		oxygen_bar.modulate = Color(1.0, 1.0, 1.0)

	# Experience 2: dark-red vignette pulses when oxygen is critically low or full red when burning
	if vignette_overlay:
		var v_alpha = 0.0
		if in_fire_zone:
			# Intense, rapid orange/red flicker when burning
			var pulse = (sin(Time.get_ticks_msec() * 0.02) + 1.0) * 0.5
			v_alpha = 0.5 + pulse * 0.3
			vignette_overlay.color = Color(1.0, 0.1, 0.0, 1.0)
		else:
			vignette_overlay.color = Color(0.5, 0.0, 0.0, 1.0)
			if current_oxygen < 25.0:
				var pulse = (sin(Time.get_ticks_msec() * 0.008) + 1.0) * 0.5
				v_alpha = 0.2 + pulse * 0.2
		vignette_overlay.modulate.a = lerp(vignette_overlay.modulate.a, v_alpha, 3.0 * delta)

	# Smoke overlay
	var target_alpha = 0.0
	if in_fire_zone:
		# Heat blur/smoke blend
		target_alpha = 0.5
	elif in_smoke_zone:
		if not is_crouching:
			target_alpha = 0.7 + (1.0 - (current_oxygen / max_oxygen)) * 0.3
		else:
			target_alpha = 0.3
	else:
		target_alpha = (1.0 - (current_oxygen / max_oxygen)) * 0.5

	smoke_overlay.color.a = lerp(smoke_overlay.color.a, target_alpha, 3.0 * delta)

	# BUG 3 companion: disable timer so it can't also fire a game_over in the
	# same frame after the oxygen death calls trigger_game_over().
	if current_oxygen <= 0.0:
		is_timer_active = false
		GameManager.trigger_game_over(
			"You inhaled too much toxic smoke and suffocated!",
			"BOMBA TIP: Smoke rises and contains deadly hot gases. Always STAY LOW (crouch or crawl) during a fire. This allows you to breathe the cooler, cleaner layer of air near the ground!"
		)

# ---------------------------------------------------------------------------
# Contextual tips  (Experience 4)
# ---------------------------------------------------------------------------

func _check_contextual_tips():
	var pos = global_position
	# Kitchen zone — roughly positive X, negative Z, level 8 height
	if pos.x > 2.0 and pos.z < -1.0 and pos.y > -2.0:
		_maybe_show_tip("kitchen_area",
			"BOMBA TIP: Always check door temperature with the back of your hand before opening!")
	# Elevator lobby — positive X and Z, level 8
	if pos.x > 3.0 and pos.z > 3.0 and pos.y > -2.0:
		_maybe_show_tip("elevator_lobby",
			"BOMBA TIP: Do NOT use the lift during a fire! The shaft fills with smoke and power can cut at any moment.")
	# Stairwell — far negative X, level 8
	if pos.x < -7.0 and pos.y > -2.0:
		_maybe_show_tip("stairwell",
			"BOMBA TIP: Stay close to the wall. Move steadily — do not run on stairs.")
	# Ground floor and below
	if pos.y < -5.0:
		_maybe_show_tip("ground_floor",
			"BOMBA TIP: Move at least 20 metres from the building before stopping.")

func _maybe_show_tip(key: String, message: String):
	if shown_tips.has(key):
		return
	shown_tips[key] = true
	show_log_message(message)

# ---------------------------------------------------------------------------
# Messaging
# ---------------------------------------------------------------------------

func show_log_message(msg: String):
	log_label.text = msg
	log_timer = 4.0

# BUG 8 FIX: single entry point for transitioning the player to outside.
# GroundExitDoor's interact() calls this; it sets is_outside, clears smoke,
# and teleports — no scattered is_outside assignments elsewhere.
func teleport_to_outside():
	is_outside = true
	in_smoke_zone = false
	global_position = teleport_target_pos
	rotation = Vector3.ZERO
	show_log_message("You are outside! Head to the assembly point and call 999!")

# ---------------------------------------------------------------------------
# Phone dialer
# ---------------------------------------------------------------------------

func open_phone_dialer():
	phone_active = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	phone_panel.visible = true
	dialed_number = ""
	call_state = 0
	phone_display.text = "---"
	phone_instructions.text = "Type the Emergency Number (BOMBA)"

func press_number(num: String):
	if call_state == 0:
		if dialed_number.length() < 5:
			dialed_number += num
			phone_display.text = dialed_number
	elif call_state == 1:
		# Service selection state: 1 for BOMBA, 2 for Polis, 3 for Ambulans
		play_tick_beep()
		if num == "1":
			call_state = 2
			phone_display.text = "BOMBA"
			phone_instructions.text = "Connecting to BOMBA... Please hold..."
			await get_tree().create_timer(1.5).timeout
			if not phone_active: return
			phone_instructions.text = "BOMBA: 'Bomba here. State location and emergency!'\n[Press 1 to Report Condominium Fire, 2 to Ask for Advice]"
		else:
			phone_display.text = "ERR"
			phone_instructions.text = "Operator: 'Invalid selection. [Press 1 for BOMBA, 2 for Polis, 3 for Ambulans]'"
	elif call_state == 2:
		# Emergency selection state: 1 to report fire, 2 to ask for advice
		play_tick_beep()
		if num == "1":
			call_state = 3
			phone_display.text = "REPORTING"
			phone_instructions.text = "You: 'There is a massive fire at Unit 8A of the Condominium! The kitchen is on fire and smoke is filling the hallway!'"
			GameManager.escape_time = time_limit - current_time
			await get_tree().create_timer(3.0).timeout
			if not phone_active: return
			phone_instructions.text = "BOMBA: 'Understood! Fire engine is dispatched to Unit 8A. Evacuate to a safe area immediately!'\n[Please wait for dispatcher to end call...]"
			await get_tree().create_timer(3.0).timeout
			if not phone_active: return
			phone_active = false
			phone_panel.visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			GameManager.trigger_victory()
		elif num == "2":
			phone_display.text = "ERR"
			phone_instructions.text = "BOMBA: 'This line is for life-threatening fires only! State your fire emergency now! [Press 1 to Report Condominium Fire]'"

func clear_dialer():
	if call_state == 0:
		dialed_number = ""
		phone_display.text = "---"

func call_dialer():
	if call_state != 0:
		return
	if dialed_number == "999":
		call_state = 1
		phone_display.text = "999"
		phone_instructions.text = "Dialing emergency services..."
		play_tick_beep()
		await get_tree().create_timer(1.5).timeout
		if not phone_active: return
		phone_instructions.text = "Operator: '999 Emergency. Which service? [Press 1 for BOMBA, 2 for Polis, 3 for Ambulans]'"
	else:
		phone_instructions.text = "Wrong Number! Try again (Malaysia Emergency: 999)."
		dialed_number = ""
		phone_display.text = "ERR"


# ---------------------------------------------------------------------------
# Audio helpers
# ---------------------------------------------------------------------------

func play_cough_sound():
	var aud = AudioStreamPlayer.new()
	aud.script = load("res://scripts/synth_audio.gd")
	aud.synth_type = "cough"
	add_child(aud)

func play_burn_sound():
	var aud = AudioStreamPlayer.new()
	aud.script = load("res://scripts/synth_audio.gd")
	aud.synth_type = "burn"
	add_child(aud)

func play_tick_beep():
	var aud = AudioStreamPlayer.new()
	aud.script = load("res://scripts/synth_audio.gd")
	aud.synth_type = "click"
	add_child(aud)

# ---------------------------------------------------------------------------
# HUD setup helpers
# ---------------------------------------------------------------------------

func setup_timer_hud():
	var timer_panel = Panel.new()
	timer_panel.name = "TimerPanel"
	var hud_style = $HUD/OxygenPanel.get_theme_stylebox("panel")
	if hud_style:
		timer_panel.add_theme_stylebox_override("panel", hud_style)
	timer_panel.size = Vector2(180, 70)
	timer_panel.position = Vector2(20, 20)
	$HUD.add_child(timer_panel)

	var timer_title = Label.new()
	timer_title.text = "Time Remaining"
	timer_title.add_theme_font_size_override("font_size", 12)
	timer_title.position = Vector2(15, 10)
	timer_panel.add_child(timer_title)

	timer_label = Label.new()
	timer_label.text = "01:30"
	timer_label.add_theme_font_size_override("font_size", 22)
	timer_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	timer_label.position = Vector2(15, 28)
	timer_panel.add_child(timer_label)

func setup_vignette():
	vignette_overlay = ColorRect.new()
	vignette_overlay.name = "VignetteOverlay"
	vignette_overlay.color = Color(0.5, 0.0, 0.0, 1.0)
	vignette_overlay.modulate.a = 0.0
	vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	$HUD.add_child(vignette_overlay)
	# Render behind all other HUD elements
	$HUD.move_child(vignette_overlay, 0)

func setup_wet_towel_hud():
	wet_towel_label = Label.new()
	wet_towel_label.name = "WetTowelLabel"
	wet_towel_label.text = "Wet Towel Active — Smoke -50%"
	wet_towel_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.5))
	wet_towel_label.add_theme_font_size_override("font_size", 12)
	wet_towel_label.visible = false
	# OxygenPanel occupies top-right: 260 px wide, 90 px tall.
	# Anchor this label to the same corner so it stays below it at any resolution.
	wet_towel_label.anchor_left   = 1.0
	wet_towel_label.anchor_right  = 1.0
	wet_towel_label.anchor_top    = 0.0
	wet_towel_label.anchor_bottom = 0.0
	wet_towel_label.offset_left   = -260.0
	wet_towel_label.offset_top    = 94.0
	wet_towel_label.offset_right  = 0.0
	wet_towel_label.offset_bottom = 114.0
	$HUD.add_child(wet_towel_label)

func setup_stamina_hud():
	stamina_bar_panel = Panel.new()
	stamina_bar_panel.name = "StaminaPanel"
	var hud_style = $HUD/OxygenPanel.get_theme_stylebox("panel")
	if hud_style:
		stamina_bar_panel.add_theme_stylebox_override("panel", hud_style)
	# Anchor to top-right, below the wet-towel label
	stamina_bar_panel.anchor_left   = 1.0
	stamina_bar_panel.anchor_right  = 1.0
	stamina_bar_panel.anchor_top    = 0.0
	stamina_bar_panel.anchor_bottom = 0.0
	stamina_bar_panel.offset_left   = -260.0
	stamina_bar_panel.offset_top    = 118.0
	stamina_bar_panel.offset_right  = 0.0
	stamina_bar_panel.offset_bottom = 158.0
	stamina_bar_panel.visible = false
	$HUD.add_child(stamina_bar_panel)

	var stam_lbl = Label.new()
	stam_lbl.text = "Stamina"
	stam_lbl.add_theme_font_size_override("font_size", 11)
	stam_lbl.position = Vector2(8, 4)
	stamina_bar_panel.add_child(stam_lbl)

	stamina_bar = ProgressBar.new()
	stamina_bar.min_value = 0.0
	stamina_bar.max_value = 100.0
	stamina_bar.value = 100.0
	stamina_bar.size = Vector2(240.0, 14.0)
	stamina_bar.position = Vector2(10, 22)
	stamina_bar_panel.add_child(stamina_bar)

func update_stamina_hud():
	if not stamina_bar_panel:
		return
	stamina_bar_panel.visible = current_stamina < 100.0
	if stamina_bar:
		stamina_bar.value = current_stamina

func setup_objectives_panel():
	objectives_panel = Panel.new()
	objectives_panel.name = "ObjectivesPanel"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.55)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	objectives_panel.add_theme_stylebox_override("panel", style)
	# Anchor to bottom-left corner
	objectives_panel.anchor_left = 0.0
	objectives_panel.anchor_top = 1.0
	objectives_panel.anchor_right = 0.0
	objectives_panel.anchor_bottom = 1.0
	objectives_panel.offset_left = 10
	objectives_panel.offset_top = -200
	objectives_panel.offset_right = 290
	objectives_panel.offset_bottom = -10
	$HUD.add_child(objectives_panel)

	var title_lbl = Label.new()
	title_lbl.text = "OBJECTIVES  [Tab] hide"
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title_lbl.position = Vector2(8, 6)
	objectives_panel.add_child(title_lbl)

	objectives_label = Label.new()
	objectives_label.name = "ObjectivesText"
	objectives_label.add_theme_font_size_override("font_size", 12)
	objectives_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	objectives_label.position = Vector2(8, 24)
	objectives_label.size = Vector2(270, 168)
	objectives_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	objectives_panel.add_child(objectives_label)

	_update_objectives()

func _update_objectives():
	if not objectives_label:
		return
	var c = "✓"
	var e = "☐"
	var lines = [
		"%s Feel bedroom door before opening" % (c if GameManager.felt_bedroom_door else e),
		"%s Stay low in smoke (crouch)" % (c if GameManager.crouched_in_smoke else e),
		"%s Check kitchen door (hot!)" % (c if GameManager.felt_kitchen_door else e),
		"%s Get wet towel — optional" % (c if GameManager.got_wet_towel else e),
		"%s Use stairs, not the lift" % (c if GameManager.used_stairs else e),
		"%s Call BOMBA 999 outside" % (c if GameManager.called_999 else e),
	]
	objectives_label.text = "\n".join(lines)

func setup_pause_panel():
	pause_panel = Panel.new()
	pause_panel.name = "PausePanel"
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.88)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	pause_panel.add_theme_stylebox_override("panel", style)
	pause_panel.anchor_left = 0.5
	pause_panel.anchor_top = 0.5
	pause_panel.anchor_right = 0.5
	pause_panel.anchor_bottom = 0.5
	pause_panel.offset_left = -220
	pause_panel.offset_top = -210
	pause_panel.offset_right = 220
	pause_panel.offset_bottom = 210
	pause_panel.visible = false
	$HUD.add_child(pause_panel)

	var title = Label.new()
	title.text = "PAUSED — Press ESC to resume"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	title.position = Vector2(20, 16)
	pause_panel.add_child(title)

	var ctrl_lbl = Label.new()
	ctrl_lbl.text = "Controls:\n  WASD — Move        Shift — Sprint\n  C / Ctrl — Crouch  E — Interact\n  F — Feel door      Tab — Toggle objectives\n  ESC — Pause / Resume"
	ctrl_lbl.add_theme_font_size_override("font_size", 13)
	ctrl_lbl.position = Vector2(20, 56)
	pause_panel.add_child(ctrl_lbl)

	var obj_hdr = Label.new()
	obj_hdr.text = "Current Objectives:"
	obj_hdr.add_theme_font_size_override("font_size", 13)
	obj_hdr.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	obj_hdr.position = Vector2(20, 192)
	pause_panel.add_child(obj_hdr)

	_pause_obj_label = Label.new()
	_pause_obj_label.name = "PauseObjLabel"
	_pause_obj_label.add_theme_font_size_override("font_size", 13)
	_pause_obj_label.position = Vector2(20, 214)
	_pause_obj_label.size = Vector2(400, 130)
	pause_panel.add_child(_pause_obj_label)

	var quit_btn = Button.new()
	quit_btn.text = "Quit to Main Menu"
	quit_btn.size = Vector2(180, 36)
	quit_btn.position = Vector2(130, 378)
	quit_btn.pressed.connect(func():
		get_tree().paused = false
		GameManager.reset_state()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	pause_panel.add_child(quit_btn)

func _update_pause_objectives():
	if not _pause_obj_label:
		return
	var c = "✓"
	var e = "☐"
	var lines = [
		"%s Feel bedroom door before opening" % (c if GameManager.felt_bedroom_door else e),
		"%s Stay low in smoke (crouch)" % (c if GameManager.crouched_in_smoke else e),
		"%s Check kitchen door (hot!)" % (c if GameManager.felt_kitchen_door else e),
		"%s Get wet towel — optional" % (c if GameManager.got_wet_towel else e),
		"%s Use stairs, not the lift" % (c if GameManager.used_stairs else e),
		"%s Call BOMBA 999 outside" % (c if GameManager.called_999 else e),
	]
	_pause_obj_label.text = "\n".join(lines)
