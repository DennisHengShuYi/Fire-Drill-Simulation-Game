extends Node3D
## Dynamic NPC spawner that continuously spawns evacuating residents at the top of the stairwell.
## This ensures the stairwell stays populated even if the player takes their time to escape.

const SPAWN_INTERVAL : float = 8.0 # Spawn a new resident every 8 seconds
var spawn_timer : float = 0.0

func _ready() -> void:
	# Initial delay so we don't spawn immediately on top of the initial NPCs
	spawn_timer = 4.0

func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	
	spawn_timer += delta
	if spawn_timer >= SPAWN_INTERVAL:
		spawn_timer = 0.0
		# Only spawn if the current count of NPCs in the level is reasonable to protect performance
		var npc_count = get_tree().get_nodes_in_group("npcs").size()
		if npc_count < 10:
			spawn_npc()

func spawn_npc() -> void:
	var npc_script = load("res://scripts/npc.gd")
	if not npc_script:
		return
	
	var npc = CharacterBody3D.new()
	npc.set_script(npc_script)
	npc.start_waypoint = 0 # Start at the Level 8 landing
	npc.name = "Evacuee_Dynamic_" + str(Time.get_ticks_msec())
	
	# Waypoint 0 corresponds to L8 landing: Vector3(-12.5, 0.1, 4.7)
	# Add a tiny random offset to prevent direct spatial overlapping on spawn frame
	var offset = Vector3(randf_range(-0.1, 0.1), 0.0, randf_range(-0.1, 0.1))
	npc.transform.origin = Vector3(-12.5, 0.1, 4.7) + offset
	
	# Add as a child of the Stairwell geometry node
	var stairwell = get_tree().current_scene.get_node_or_null("Geometry/Stairwell")
	if stairwell:
		stairwell.add_child(npc)
	else:
		get_tree().current_scene.add_child(npc)
