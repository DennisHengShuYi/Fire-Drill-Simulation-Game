extends Area3D

var tracked_player = null
var time_since_spread: float = 0.0
const SPREAD_INTERVAL: float = 15.0 # Grow/spread every 15 seconds
var growth_stage: int = 0
const MAX_GROWTH_STAGES: int = 4
var is_spread_copy: bool = false

func _ready():
	if not is_spread_copy:
		# Stagger the start slightly so not all fires grow at the exact same frame
		time_since_spread = randf_range(-5.0, 0.0)

func _physics_process(delta):
	var player_in_this_fire = false
	for body in get_overlapping_bodies():
		if body.has_method("process_smoke_inhalation") and "in_fire_zone" in body:
			tracked_player = body
			player_in_this_fire = true
			
			var active_fires = body.get_meta("active_fires", [])
			if not active_fires.has(self):
				active_fires.append(self)
				body.set_meta("active_fires", active_fires)
			
			body.in_fire_zone = true
			break
			
	if not player_in_this_fire and tracked_player:
		if is_instance_valid(tracked_player):
			var active_fires = tracked_player.get_meta("active_fires", [])
			active_fires.erase(self)
			tracked_player.set_meta("active_fires", active_fires)
			if active_fires.size() == 0:
				tracked_player.in_fire_zone = false
		tracked_player = null

	# Handle fire growth and spread
	if not is_spread_copy:
		time_since_spread += delta
		if time_since_spread >= SPREAD_INTERVAL:
			time_since_spread = 0.0
			if growth_stage < MAX_GROWTH_STAGES:
				grow_fire()

func grow_fire():
	growth_stage += 1
	
	# Scale this hazard area (which scales its BoxShape3D collision)
	var new_scale = 1.0 + growth_stage * 0.4 # stages: 1.4x, 1.8x, 2.2x, 2.6x
	scale = Vector3(new_scale, new_scale, new_scale)
	
	# Find and scale sibling CPUParticles3D
	var particle_name = name.replace("_Hazard", "")
	var particles = get_parent().get_node_or_null(particle_name)
	if particles and particles is CPUParticles3D:
		particles.scale = Vector3(new_scale, new_scale, new_scale)
	
	# Only trigger spawning from the main fires to avoid infinite sprawl
	var is_kitchen_fire = name.to_lower().contains("kitchen") or name.to_lower().contains("fireparticle")
	if is_kitchen_fire:
		GameManager.fire_spread_count += 1
		
		# Log message to player based on current spread count
		var player = get_tree().current_scene.get_node_or_null("Player")
		if player and player.has_method("show_log_message"):
			if GameManager.fire_spread_count == 1:
				player.show_log_message("WARNING: The fire is spreading from the kitchen into the dining area!")
			elif GameManager.fire_spread_count == 2:
				player.show_log_message("WARNING: Thick smoke and flames are engulfing the living room!")
			elif GameManager.fire_spread_count == 3:
				player.show_log_message("CRITICAL: The kitchen door is now completely blocked by fire!")
			elif GameManager.fire_spread_count >= 4:
				player.show_log_message("CRITICAL: The fire has breached the front door and is spreading into the corridor!")
		
	# Spawn a new adjacent fire towards the West (Living/Dining Room)
	# Scale offset by growth_stage so it spreads progressively West
	var spread_offset = Vector3(-1.5 * growth_stage, 0.0, randf_range(-0.5, 0.5))
	spawn_adjacent_fire(spread_offset, "_W")

	# Also spread Northward towards the corridor (positive Z) as the fire grows
	if growth_stage >= 2:
		var corridor_offset = Vector3(randf_range(-1.0, 1.0), 0.0, 1.8 * growth_stage)
		spawn_adjacent_fire(corridor_offset, "_N")

func spawn_adjacent_fire(offset: Vector3, suffix: String = ""):
	var particle_name = name.replace("_Hazard", "")
	var particles = get_parent().get_node_or_null(particle_name)
	if not particles:
		return
		
	# Duplicate particles and this hazard Area3D
	var new_particles = particles.duplicate()
	var new_hazard = duplicate()
	
	# Set unique names to avoid conflicts
	new_hazard.name = name + "_Spread_" + str(GameManager.fire_spread_count) + suffix
	new_particles.name = particle_name + "_Spread_" + str(GameManager.fire_spread_count) + suffix
	
	# Prevent the new hazard from growing and spawning more hazards
	new_hazard.is_spread_copy = true
	new_hazard.growth_stage = MAX_GROWTH_STAGES
	new_hazard.time_since_spread = -99999.0
	
	# Set positions using local position offsets before adding to the tree (prevents split-frame origin emissions)
	new_particles.position = particles.position + offset
	new_hazard.position = position + offset
	
	# Add to the same parent node so they are part of the scene tree
	get_parent().add_child(new_particles)
	get_parent().add_child(new_hazard)
	
	# Ensure the duplicated particle system emits immediately at the new spot
	if "emitting" in new_particles:
		new_particles.emitting = true
	if new_particles.has_method("restart"):
		new_particles.restart()

