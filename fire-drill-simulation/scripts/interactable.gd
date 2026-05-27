class_name Interactable
extends StaticBody3D

@export var prompt_message: String = "Object"
@export var can_feel: bool = true

@export_group("Door Settings")
@export var is_door: bool = false
@export var is_hot: bool = false
@export var door_opened: bool = false
@export var door_mesh_path: NodePath
@export var open_angle: float = 90.0

@export_group("Special Objects")
@export var is_lift: bool = false
@export var is_stairs: bool = false
@export var is_phone: bool = false
@export var is_sink: bool = false
@export var is_locked_door: bool = false
@export var is_npc: bool = false

var original_rotation_y: float = 0.0
var original_position: Vector3
var tween: Tween

func _ready():
	original_rotation_y = rotation.y
	original_position = global_position
	collision_layer = 2

func get_interact_prompt() -> String:
	if is_door and is_stairs:
		return "[E] Open Fire Exit"
	elif is_door:
		return "[E] Open Door" + (", [F] Feel Door" if can_feel and not door_opened else "")
	elif is_lift:
		return "[E] Press Lift Button"
	elif is_stairs:
		return "[E] Open Fire Exit"
	elif is_phone:
		return "[E] Call BOMBA (999)"
	elif is_sink:
		return "[E] Sink (Get Wet Towel)"
	elif is_locked_door:
		return "[E] Try Door (Locked)"
	elif is_npc:
		return prompt_message if prompt_message != "Object" else "[E] Report to building warden"
	return "[E] " + prompt_message

# BUG 1 FIX: when BOTH is_door and is_stairs are true (GroundExitDoor),
# call toggle_door() AND handle the outside transition — the elif chain
# previously short-circuited on is_door, so use_stairs was never reached.
func interact(player: CharacterBody3D):
	if is_door and is_stairs:
		toggle_door(player)
		if door_opened:
			GameManager.used_stairs = true
			player.teleport_to_outside()
	elif is_door:
		toggle_door(player)
		if name == "StairsExitDoor" and door_opened:
			player.is_outside = true
		elif name.to_lower().contains("firedoor") and door_opened:
			GameManager.used_stairs = true
	elif is_lift:
		use_lift(player)
	elif is_stairs:
		use_stairs(player)
	elif is_phone:
		use_phone(player)
	elif is_sink:
		use_sink(player)
	elif is_locked_door:
		player.show_log_message("This neighbor's door is locked! You must evacuate using the stairs!")
	elif is_npc:
		player.show_log_message("Warden: 'Unit 8A confirmed evacuated. Now call BOMBA at 999 immediately!'")
		GameManager.reported_to_warden = true

func feel(player: CharacterBody3D) -> String:
	if not can_feel or door_opened:
		return "Nothing to feel."

	if is_door:
		if name.to_lower().contains("bedroom"):
			GameManager.felt_bedroom_door = true
		elif name.to_lower().contains("kitchen"):
			GameManager.felt_kitchen_door = true

		if is_hot:
			play_sound_3d("sizzle")
			return "WARNING: The door and handle feel extremely HOT! There is fire on the other side!"
		else:
			play_sound_3d("door_creak")
			return "The door handle feels cool. It seems safe to open slowly."

	return "It feels normal."

func toggle_door(player: CharacterBody3D):
	if is_hot:
		if name.to_lower().contains("kitchen"):
			GameManager.opened_kitchen_door = true
		play_sound_3d("sizzle")
		GameManager.trigger_game_over(
			"You opened a hot door to a room on fire!",
			"BOMBA TIP: Never open a door that feels hot! Fire needs oxygen; opening the door feeds the fire and causes a dangerous backdraft explosion. Look for another escape route or seal the door and wait at the window!"
		)
		return

	door_opened = !door_opened
	play_sound_3d("door_creak")

	var door_mesh = get_node_or_null(door_mesh_path)
	if door_mesh:
		if tween:
			tween.kill()
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var target_rot = original_rotation_y
		if door_opened:
			target_rot = original_rotation_y + deg_to_rad(open_angle)
		tween.tween_property(door_mesh, "rotation:y", target_rot, 0.6)
		player.show_log_message("Opened the door.")
	else:
		if tween:
			tween.kill()
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		# door_opened is already toggled above, so check the new state correctly:
		# door_opened == true means we just opened it → rotate to open angle
		# door_opened == false means we just closed it → rotate back to original
		var target_rot: float
		if door_opened:
			target_rot = original_rotation_y + deg_to_rad(open_angle)
		else:
			target_rot = original_rotation_y
		tween.tween_property(self, "rotation:y", target_rot, 0.6)
		player.show_log_message("Opened the door.")

func use_lift(player: CharacterBody3D):
	if door_opened:
		return

	door_opened = true
	play_sound_3d("door_creak")

	# Instantly disable collision layer to prevent the sliding door from physically pushing the player
	collision_layer = 0
	var col = get_node_or_null("CollisionShape3D")
	if col:
		col.disabled = true

	if tween:
		tween.kill()

	# Slide door open in the X direction (into the wall cavity)
	tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var open_x: float
	if name == "LiftA":
		open_x = global_position.x - 1.2
	else:
		open_x = global_position.x + 1.2
	tween.tween_property(self, "global_position:x", open_x, 1.0)

	# Player is free to walk inside — the ElevatorCabinArea (elevator.gd)
	# triggers the sequence automatically when the player physically steps in.
	player.show_log_message("The elevator doors slide open. Step inside — or take the stairs!!")

# BUG 8 FIX: use_stairs() is now only for stairwell-entry doors (e.g. FireDoor_L8).
# GroundExitDoor (is_door+is_stairs) calls player.teleport_to_outside() directly.
func use_stairs(player: CharacterBody3D):
	GameManager.used_stairs = true
	player.show_log_message("You push through the fire exit door! Descend to the ground floor!")
	player.global_position = Vector3(-12.5, 0.05, 4.5)

func use_phone(player: CharacterBody3D):
	if not player.is_outside:
		player.show_log_message("Get outside first before calling!")
		return
	GameManager.called_999 = true
	player.open_phone_dialer()

func play_sound_3d(type: String):
	var aud = AudioStreamPlayer3D.new()
	aud.script = load("res://scripts/synth_audio_3d.gd")
	aud.synth_type = type
	aud.global_position = global_position
	aud.max_distance = 15.0
	get_tree().current_scene.add_child(aud)

func use_sink(player: CharacterBody3D):
	if player.has_wet_towel:
		player.show_log_message("You already have a wet towel!")
		return
	player.has_wet_towel = true
	GameManager.got_wet_towel = true
	play_sound_3d("sizzle")
	player.show_log_message("Wet towel obtained! Smoke exposure rate reduced by 50%!")
