extends CharacterBody3D

@export var speed: float = 3.5
@export var sprint_speed: float = 5.0
@export var gravity: float = 9.8
@export var mouse_sensitivity: float = 0.002

# Crouching settings
@export var stand_height: float = 1.8
@export var crouch_height: float = 0.9
@export var crouch_speed: float = 2.0

# Smoke/Oxygen settings
var max_oxygen: float = 100.0
var current_oxygen: float = 100.0
var in_smoke_zone: bool = false
var cough_timer: float = 0.0

# Node references
@onready var camera: Camera3D = $Camera3D
@onready var raycast: RayCast3D = $Camera3D/RayCast3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

# UI node references (defined in player.tscn)
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

# Teleport target (outside assembly point)
var teleport_target_pos: Vector3 = Vector3(0, 0, 0)
var is_outside: bool = false
var has_shown_crouch_tip: bool = false
var has_wet_towel: bool = false

# Timer settings
@export var time_limit: float = 90.0
var current_time: float
var is_timer_active: bool = true
var timer_label: Label = null
var in_elevator_sequence: bool = false

func _ready():
	# Capture mouse
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Hide phone initially
	phone_panel.visible = false
	smoke_overlay.color.a = 0.0
	
	# Setup phone button signals programmatically
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
	setup_timer_hud()
	show_log_message("FIRE ALARM RINGING! Find a way out safely!")

func _input(event):
	if phone_active:
		# If phone is active, mouse is visible, so don't rotate camera
		return
		
	if event is InputEventMouseMotion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		# Clamp pitch
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80.0), deg_to_rad(80.0))

func _physics_process(delta):
	# Handle phone state and elevator sequence
	if phone_active or in_elevator_sequence:
		velocity = Vector3.ZERO
		move_and_slide()
		if in_elevator_sequence:
			# Shake the camera during elevator rumble
			camera.position.x = randf_range(-0.015, 0.015)
			camera.position.y = lerp(camera.position.y, stand_height - 0.2 + randf_range(-0.015, 0.015), 5.0 * delta)
		return
		
	# Update countdown timer
	if is_timer_active:
		current_time -= delta
		if current_time <= 0.0:
			current_time = 0.0
			is_timer_active = false
			GameManager.trigger_game_over(
				"You ran out of time! The fire spread and trapped you in the building.",
				"BOMBA TIP: Fire spreads incredibly fast—often in less than 2-3 minutes. Never delay your evacuation to collect personal belongings. Every second counts!"
			)
		
		if timer_label:
			var minutes = int(current_time) / 60
			var seconds = int(current_time) % 60
			timer_label.text = "%02d:%02d" % [minutes, seconds]
			
			if current_time < 30.0:
				var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
				timer_label.add_theme_color_override("font_color", Color(1.0, 0.2 + pulse * 0.4, 0.2 + pulse * 0.4))
			else:
				timer_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	# Crouch logic
	var target_height = stand_height
	if Input.is_action_pressed("crouch"):
		target_height = crouch_height
		is_crouching = true
		if in_smoke_zone:
			GameManager.crouched_in_smoke = true
	else:
		is_crouching = false
		
	# Smoothly adjust camera height and collision shape height
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
	
	var current_speed = speed
	if is_crouching:
		current_speed = speed * 0.5
	elif Input.is_action_pressed("sprint"):
		current_speed = sprint_speed
		
	if dir:
		velocity.x = dir.x * current_speed
		velocity.z = dir.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
	move_and_slide()
	
	# Interaction Raycasting
	check_interaction()
	
	# Handle Smoke Inhalation
	process_smoke_inhalation(delta)
	
	# Update log timer
	if log_timer > 0.0:
		log_timer -= delta
		if log_timer <= 0.0:
			log_label.text = ""

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
			return
			
	prompt_label.text = ""

func process_smoke_inhalation(delta):
	# If in smoke zone
	if in_smoke_zone:
		if not has_shown_crouch_tip:
			has_shown_crouch_tip = true
			show_log_message("Stay low! Crouch (C or Ctrl) to reduce smoke inhalation.")
			
		var multiplier = 0.5 if has_wet_towel else 1.0
		
		if not is_crouching:
			# Standing in smoke is deadly
			current_oxygen -= 15.0 * delta * multiplier
			GameManager.stood_up_in_smoke = true
			
			# Cough feedback
			cough_timer += delta
			if cough_timer >= 1.5:
				cough_timer = 0.0
				show_log_message("*COUGH* Heavy smoke! Stay Low (Crouch)!")
				play_cough_sound()
				# Screen shake
				camera.position.x += randf_range(-0.05, 0.05)
				camera.position.y += randf_range(-0.05, 0.05)
		else:
			# Crouched: safe or very minor inhalation
			current_oxygen -= 1.0 * delta * multiplier # Slow drain to keep tension, but very safe
	else:
		# Recover oxygen slowly if outside or in clean air
		current_oxygen = move_toward(current_oxygen, max_oxygen, 5.0 * delta)
		
	current_oxygen = clamp(current_oxygen, 0.0, max_oxygen)
	oxygen_bar.value = current_oxygen
	
	# Update HUD label for Wet Towel
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
	
	# Update smoke overlay transparency based on oxygen
	var target_alpha = 0.0
	if in_smoke_zone:
		if not is_crouching:
			target_alpha = 0.7 + (1.0 - (current_oxygen / max_oxygen)) * 0.3
		else:
			target_alpha = 0.3 # Visual indicator of being in smoke
	else:
		target_alpha = (1.0 - (current_oxygen / max_oxygen)) * 0.5
		
	smoke_overlay.color.a = lerp(smoke_overlay.color.a, target_alpha, 3.0 * delta)
	
	# Death condition
	if current_oxygen <= 0.0:
		GameManager.trigger_game_over(
			"You inhaled too much toxic smoke and suffocated!",
			"BOMBA TIP: Smoke rises and contains deadly hot gases. Always STAY LOW (crouch or crawl) during a fire. This allows you to breathe the cooler, cleaner layer of air near the ground!"
		)

func show_log_message(msg: String):
	log_label.text = msg
	log_timer = 4.0

func teleport_to_outside():
	is_outside = true
	in_smoke_zone = false
	global_position = teleport_target_pos
	# Rotate to face the phone box/assembly area
	rotation = Vector3.ZERO
	show_log_message("Safe outside! Find a phone and report the fire (999)!")

func open_phone_dialer():
	phone_active = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	phone_panel.visible = true
	dialed_number = ""
	phone_display.text = "---"
	phone_instructions.text = "Type the Emergency Number (BOMBA)"

# Phone button helper methods
func press_number(num: String):
	if dialed_number.length() < 5:
		dialed_number += num
		phone_display.text = dialed_number

func clear_dialer():
	dialed_number = ""
	phone_display.text = "---"

func call_dialer():
	if dialed_number == "999":
		phone_instructions.text = "Connecting to BOMBA..."
		await get_tree().create_timer(1.5).timeout
		phone_active = false
		phone_panel.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameManager.trigger_victory()
	else:
		phone_instructions.text = "Wrong Number! Try again (Malaysia Emergency)."
		dialed_number = ""
		phone_display.text = "ERR"

func play_cough_sound():
	var aud = AudioStreamPlayer.new()
	aud.script = load("res://scripts/synth_audio.gd")
	aud.synth_type = "cough"
	add_child(aud)

func setup_timer_hud():
	var timer_panel = Panel.new()
	timer_panel.name = "TimerPanel"
	var hud_style = $HUD/OxygenPanel.get_theme_stylebox("panel")
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
