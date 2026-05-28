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
@export var is_extinguisher: bool = false
@export var is_sealed: bool = false
@export var is_suitcase_npc: bool = false
@export var is_alarm_pull: bool = false
@export var resolved: bool = false
@export var is_phone_item: bool = false
@export var is_safety_ladder: bool = false
var extinguisher_used: bool = false

var original_rotation_y: float = 0.0
var original_position: Vector3
var tween: Tween

var has_trapped_npc: bool = false
var trapped_npc_quest_state: String = "none" # "none", "discovered", "resolved"
var trapped_timer: float = 0.0
var has_shouted_proximity: bool = false

func _ready():
	original_rotation_y = rotation.y
	original_position = global_position
	collision_layer = 2
	
	if is_locked_door:
		has_trapped_npc = randf() < 0.7
		trapped_timer = randf_range(0.0, 5.0)

func _process(delta):
	if is_locked_door and has_trapped_npc and trapped_npc_quest_state == "none":
		var player = get_tree().current_scene.get_node_or_null("Player")
		if player:
			var dist = global_position.distance_to(player.global_position)
			if dist < 12.0 and not has_shouted_proximity:
				has_shouted_proximity = true
				play_sound_3d("help_muffled")
				trapped_timer = 0.0
		
		trapped_timer += delta
		if trapped_timer >= 8.0:
			trapped_timer = 0.0
			if player and global_position.distance_to(player.global_position) < 15.0:
				play_sound_3d("help_muffled")

func get_interact_prompt() -> String:
	if is_door and is_stairs:
		return "[E] Open Fire Exit"
	elif is_door:
		var prompt = "[E] Open Door" + (", [F] Feel Door" if can_feel and not door_opened else "")
		if not door_opened and name.to_lower().contains("bedroom") and not is_sealed:
			prompt += ", [X] Seal Door (requires Wet Towel)"
		return prompt
	elif is_lift:
		return "[E] Press Lift Button"
	elif is_stairs:
		return "[E] Open Fire Exit"
	elif is_phone:
		return "[E] Call BOMBA (999)"
	elif is_sink:
		return "[E] Sink (Get Wet Towel)"
	elif is_locked_door:
		if has_trapped_npc and trapped_npc_quest_state == "none":
			return "[E] Try Door (Locked), [K] Knock on Door"
		elif has_trapped_npc and trapped_npc_quest_state == "discovered":
			return "[K] Talk / Respond"
		return "[E] Try Door (Locked)"
	elif is_extinguisher:
		if extinguisher_used:
			return "Fire Extinguisher (empty)"
		return "[E] Pick up Fire Extinguisher"
	elif is_npc:
		return prompt_message if prompt_message != "Object" else "[E] Report to building warden"
	elif is_alarm_pull:
		if GameManager.alarm_triggered:
			return "Manual Call Point (Activated)"
		return "[E] Pull Alarm (Manual Call Point)"
	elif is_suitcase_npc:
		if resolved:
			return "Evacuee (Evacuating)"
		return "[E] Speak to resident"
	elif is_phone_item:
		return "[E] Pick up Mobile Phone"
	elif is_safety_ladder:
		return "[E] Climb down Safety Ladder"
	if prompt_message.begins_with("[E]"):
		return prompt_message
	return "[E] " + prompt_message

# BUG 1 FIX: when BOTH is_door and is_stairs are true (GroundExitDoor),
# call toggle_door() AND handle the outside transition — the elif chain
# previously short-circuited on is_door, so use_stairs was never reached.
func interact(player: CharacterBody3D):
	if is_door and is_stairs:
		toggle_door(player)
		if door_opened:
			GameManager.used_stairs = true
			player.is_outside = true
			player.in_smoke_zone = false
			player.show_log_message("You push through the exit door to the outside! Walk to the assembly point!")
	elif is_door:
		if name == "KitchenDoor" and GameManager.fire_spread_count > 2:
			player.show_log_message("The kitchen door is completely blocked by fire!")
			return
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
	elif is_extinguisher:
		pick_up_extinguisher(player)
	elif is_locked_door:
		player.show_log_message("This neighbor's door is locked! You must evacuate using the stairs!")
	elif is_npc:
		player.show_log_message("Warden: 'Unit 8A confirmed evacuated. Now call BOMBA at 999 immediately!'")
		GameManager.reported_to_warden = true
	elif is_alarm_pull:
		if GameManager.alarm_triggered:
			return
		trigger_alarm(player)
	elif is_suitcase_npc:
		if resolved:
			return
		var npc = get_parent()
		if npc and "is_talking" in npc:
			npc.is_talking = true
		player.show_dilemma_menu(
			"This resident is trying to carry a heavy suitcase down the stairwell! This will block the evacuation path.",
			"Drop suitcase & evacuate immediately (Correct)",
			"Ignore them and run past (Incorrect)",
			self,
			"resolve_suitcase_dilemma"
		)
	elif is_phone_item:
		player.has_mobile_phone = true
		player.show_log_message("Picked up Mobile Phone! Press [P] to call emergency from a safe room or balcony.")
		queue_free()
	elif is_safety_ladder:
		player.start_climbing_ladder()

func feel(player: CharacterBody3D) -> String:
	if not can_feel or door_opened:
		return "Nothing to feel."

	if is_door:
		if name == "KitchenDoor" and GameManager.fire_spread_count > 2:
			return "The kitchen door is completely blocked by fire!"
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
	aud.max_distance = 15.0
	get_tree().current_scene.add_child(aud)
	aud.global_position = global_position

func use_sink(player: CharacterBody3D):
	if player.has_wet_towel:
		player.show_log_message("You already have a wet towel!")
		return
	player.has_wet_towel = true
	GameManager.got_wet_towel = true
	play_sound_3d("sizzle")
	player.show_log_message("Wet towel obtained! Smoke exposure rate reduced by 50%!")

func pick_up_extinguisher(player: CharacterBody3D):
	if extinguisher_used:
		player.show_log_message("This extinguisher is empty!")
		return
	if player.has_extinguisher:
		player.show_log_message("You are already carrying a fire extinguisher!")
		return
		
	# Pick up
	player.has_extinguisher = true
	player.carried_extinguisher_ref = self
	
	# Hide visually and disable collision/interaction
	visible = false
	collision_layer = 0
	
	# Show in player's hands
	if player.has_method("show_hand_extinguisher"):
		player.show_hand_extinguisher()
	player.show_log_message("Picked up Fire Extinguisher! Press [Left-Click] or [E] near fire to use.")
	play_sound_3d("door_creak")

func knock(player: CharacterBody3D):
	if not is_locked_door or not has_trapped_npc:
		player.show_log_message("You knock on the door, but there is no response.")
		return
		
	if trapped_npc_quest_state == "none":
		trapped_npc_quest_state = "discovered"
		play_sound_3d("help_muffled")
		player.show_log_message("Muffled Voice: 'Help! I'm trapped! The fire block is outside my kitchen and the door lock is jammed!'")
		
	player.show_dilemma_menu(
		"Help trapped neighbor in Unit 8C?",
		"Wait & Rescue (costs 15s, risk smoke inhalation)",
		"Advise to use Balcony Exit (safe protocol)",
		self,
		"resolve_neighbor_dilemma"
	)

func resolve_neighbor_dilemma(player: CharacterBody3D, choice: int):
	trapped_npc_quest_state = "resolved"
	GameManager.neighbor_quest_attempted = true
	
	if choice == 1:
		GameManager.saved_neighbor = true
		play_sound_3d("door_creak")
		
		# Deduct 15s from timer
		player.current_time -= 15.0
		# Apply smoke penalty
		var smoke_rate = 12.0
		if player.has_wet_towel:
			smoke_rate = 6.0
		player.current_oxygen -= smoke_rate * 15.0
		
		player.show_log_message("Lock kicked open (+15s, -O2)! Resident: 'Thank you! Let's take the stairs!'")
	else:
		GameManager.neighbor_left_behind = true
		play_sound_3d("help_muffled")
		player.show_log_message("You: 'Evacuate via balcony!' Neighbor: 'Okay, I'll use the balcony exit!'")

func resolve_suitcase_dilemma(player: CharacterBody3D, choice: int):
	resolved = true
	var npc = get_parent()
	if npc and npc.has_method("resolve_suitcase"):
		npc.resolve_suitcase(choice)
	if choice == 1:
		GameManager.corrected_npc = true
	else:
		GameManager.ignored_npc = true

func trigger_alarm(player: CharacterBody3D):
	GameManager.alarm_triggered = true
	var alarm = get_tree().current_scene.get_node_or_null("AlarmAudio")
	if alarm:
		alarm.play()
	play_sound_3d("click")
	player.show_log_message("FIRE ALARM ACTIVATED! Evacuation in progress!")

