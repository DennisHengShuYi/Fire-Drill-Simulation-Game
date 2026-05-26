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

var original_rotation_y: float = 0.0
var tween: Tween

func _ready():
	original_rotation_y = rotation.y
	# Ensure the collision layer is set up for raycasting (e.g. layer 2 for interactables)
	collision_layer = 2 # Layer 2 is interactables

func get_interact_prompt() -> String:
	if is_door:
		return "[E] Open Door" + (", [F] Feel Door" if can_feel and not door_opened else "")
	elif is_lift:
		return "[E] Press Lift Button"
	elif is_stairs:
		return "[E] Open Fire Exit"
	elif is_phone:
		return "[E] Call BOMBA (999)"
	return "[E] " + prompt_message

func interact(player: CharacterBody3D):
	if is_door:
		toggle_door(player)
	elif is_lift:
		use_lift(player)
	elif is_stairs:
		use_stairs(player)
	elif is_phone:
		use_phone(player)

func feel(player: CharacterBody3D) -> String:
	if not can_feel or door_opened:
		return "Nothing to feel."
		
	if is_door:
		if name.to_lower().contains("bedroom"):
			GameManager.felt_bedroom_door = true
		elif name.to_lower().contains("kitchen"):
			GameManager.felt_kitchen_door = true
			
		if is_hot:
			return "WARNING: The door and handle feel extremely HOT! There is fire on the other side!"
		else:
			return "The door handle feels cool. It seems safe to open slowly."
			
	return "It feels normal."

func toggle_door(player: CharacterBody3D):
	if is_hot:
		# Immediate game over: Backdraft!
		if name.to_lower().contains("kitchen"):
			GameManager.opened_kitchen_door = true
		GameManager.trigger_game_over(
			"You opened a hot door to a room on fire!",
			"BOMBA TIP: Never open a door that feels hot! Fire needs oxygen; opening the door feeds the fire and causes a dangerous backdraft explosion. Look for another escape route or seal the door and wait at the window!"
		)
		return

	if not can_feel and is_hot:
		# Just in case
		return

	# If opening the main apartment door, let's register it
	door_opened = !door_opened
	
	# Rotate the door mesh using Tween
	var door_mesh = get_node_or_null(door_mesh_path)
	if door_mesh:
		if tween:
			tween.kill()
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		var target_rot = original_rotation_y
		if door_opened:
			target_rot = original_rotation_y + deg_to_rad(open_angle)
			
		tween.tween_property(door_mesh, "rotation:y", target_rot, 0.6)
		
		# Show a message in player GUI
		player.show_log_message("Opened the door.")
	else:
		# Rotate self if no mesh path provided
		if tween:
			tween.kill()
		tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var target_rot = original_rotation_y
		if door_opened:
			target_rot = original_rotation_y + deg_to_rad(open_angle)
		tween.tween_property(self, "rotation:y", target_rot, 0.6)
		player.show_log_message("Opened the door.")

func use_lift(player: CharacterBody3D):
	GameManager.used_lift = true
	GameManager.trigger_game_over(
		"You entered the lift during a building fire!",
		"BOMBA TIP: NEVER use a lift (elevator) during a fire! Power outages can trap you inside, and lift shafts act like chimneys, quickly filling with deadly smoke and toxic gases. Always use the stairs!"
	)

func use_stairs(player: CharacterBody3D):
	GameManager.used_stairs = true
	player.show_log_message("Entered the stairwell! Go down the stairs to the ground floor exit!")
	toggle_door(player)

func use_phone(player: CharacterBody3D):
	GameManager.called_999 = true
	# Show phone screen or trigger victory directly
	player.open_phone_dialer()
