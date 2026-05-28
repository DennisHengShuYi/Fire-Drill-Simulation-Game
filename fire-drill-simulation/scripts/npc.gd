extends CharacterBody3D
## Evacuating resident NPC that descends the stairwell switchback, demonstrates
## correct evacuation behaviour, and teaches the player not to push or shove.

const NPC_SPEED       : float = 2.4   # m/s (slower than player 3.5 m/s)
const GRAVITY         : float = 9.8
const WAYPOINT_REACH  : float = 1.1   # XZ radius to count waypoint as reached
const PUSH_COOLDOWN   : float = 4.0   # seconds between "Don't push!" messages
const QUEUE_RADIUS    : float = 1.6   # slow down if another NPC is this close ahead
const QUEUE_SPEED_MUL : float = 0.35  # speed multiplier when queuing behind someone

# ── Stairwell switchback waypoints (L8 → Ground → Street → Assembly) ──────────
# shaft_cx = -12.5, FLOOR_HEIGHT = 2.8
# Even landings (L8,L6,L4,L2,Ground): Z = 4.7
# Odd  landings (L7,L5,L3,L1):        Z = -3.7
# West ramp X = -13.7,  East ramp X = -11.3,  mid-Z = 0.5
var FULL_WAYPOINTS : Array = [
	Vector3(-12.5,  0.1,   4.7),   # 0  L8 landing (start/entry)
	Vector3(-13.7, -1.4,   0.5),   # 1  west ramp mid L8→L7
	Vector3(-12.5, -2.9,  -3.7),   # 2  L7 landing
	Vector3(-11.3, -4.2,   0.5),   # 3  east ramp mid L7→L6
	Vector3(-12.5, -5.7,   4.7),   # 4  L6 landing
	Vector3(-13.7, -7.0,   0.5),   # 5  west ramp mid L6→L5
	Vector3(-12.5, -8.5,  -3.7),   # 6  L5 landing
	Vector3(-11.3, -9.8,   0.5),   # 7  east ramp mid L5→L4
	Vector3(-12.5, -11.3,  4.7),   # 8  L4 landing
	Vector3(-13.7, -12.6,  0.5),   # 9  west ramp mid L4→L3
	Vector3(-12.5, -14.1, -3.7),   # 10 L3 landing
	Vector3(-11.3, -15.4,  0.5),   # 11 east ramp mid L3→L2
	Vector3(-12.5, -16.9,  4.7),   # 12 L2 landing
	Vector3(-13.7, -18.2,  0.5),   # 13 west ramp mid L2→L1
	Vector3(-12.5, -19.7, -3.7),   # 14 L1 landing
	Vector3(-11.3, -21.0,  0.5),   # 15 east ramp mid L1→Ground
	Vector3(-12.5, -22.4,  5.9),   # 16 ground exit door threshold
	Vector3(-12.5, -22.5, 13.0),   # 17 clear of building
	Vector3( -8.0, -22.5, 22.0),   # 18 assembly point (final)
]

# Which waypoint index this NPC starts at (set by build_level.py)
@export var start_waypoint : int = 0
@export var is_suitcase_npc: bool = false

var current_waypoint : int = 0
var push_cooldown    : float = 0.0
var _done            : bool  = false

var suitcase_resolved: bool = false
var is_talking: bool = false
var suitcase_choice: int = 0
var suitcase_mesh: MeshInstance3D = null

var _queue_check_timer: float = 0.0
var _cached_speed_mult: float = 1.0

# ── Mesh materials ────────────────────────────────────────────────────────────
# A bright cyan capsule body so the player can spot NPCs easily in the dim
# stairwell.  We build it in _ready() because sub-resources only exist at
# runtime in headless builds.

func _ready() -> void:
	add_to_group("npcs")
	current_waypoint = start_waypoint

	if is_suitcase_npc:
		var custom_waypoints = [
			Vector3(14.0, 0.1, 5.0),
			Vector3(0.0, 0.1, 5.0),
			Vector3(-12.5, 0.1, 5.0),
		]
		var new_wps = []
		new_wps.append_array(custom_waypoints)
		new_wps.append_array(FULL_WAYPOINTS)
		FULL_WAYPOINTS = new_wps
		current_waypoint = 0

		# Ignore collision with the interactable child StaticBody3D to prevent self-propulsion physics glitch
		var child = get_node_or_null("InteractableChild")
		if child:
			add_collision_exception_with(child)

		# Create suitcase mesh
		var box = BoxMesh.new()
		box.size = Vector3(0.5, 0.4, 0.2)
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.25, 0.15) # Brown suitcase
		mat.roughness = 0.8
		box.material = mat
		suitcase_mesh = MeshInstance3D.new()
		suitcase_mesh.name = "Suitcase"
		suitcase_mesh.mesh = box
		suitcase_mesh.position = Vector3(0.35, 0.5, 0.0) # Hold to the side
		add_child(suitcase_mesh)

	# Add CapsuleShape3D collision
	var col_shape = CapsuleShape3D.new()
	col_shape.radius = 0.28
	col_shape.height = 1.8
	var cs = CollisionShape3D.new()
	cs.shape = col_shape
	cs.position = Vector3(0, 0.9, 0)
	add_child(cs)

	# Body mesh: cyan capsule
	var cap_mesh = CapsuleMesh.new()
	cap_mesh.radius = 0.28
	cap_mesh.height = 1.8
	var body_mat = StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.15, 0.85, 0.95)
	body_mat.roughness = 0.6
	cap_mesh.material = body_mat
	var mi = MeshInstance3D.new()
	mi.mesh = cap_mesh
	mi.position = Vector3(0, 0.9, 0)
	add_child(mi)

	# Head mesh: small sphere
	var head_mesh = SphereMesh.new()
	head_mesh.radius = 0.18
	head_mesh.height = 0.36
	var head_mat = StandardMaterial3D.new()
	head_mat.albedo_color = Color(0.90, 0.78, 0.62)
	head_mat.roughness = 0.7
	head_mesh.material = head_mat
	var head_mi = MeshInstance3D.new()
	head_mi.mesh = head_mesh
	head_mi.position = Vector3(0, 1.9, 0)
	add_child(head_mi)

	# Proximity area to detect player bumps
	var detect_shape = SphereShape3D.new()
	detect_shape.radius = 0.7
	var detect_cs = CollisionShape3D.new()
	detect_cs.shape = detect_shape
	detect_cs.position = Vector3(0, 0.9, 0)
	var area = Area3D.new()
	area.name = "BumpDetector"
	area.collision_layer = 0
	area.collision_mask  = 1   # detect player (layer 1)
	area.add_child(detect_cs)
	area.body_entered.connect(_on_body_entered)
	add_child(area)

	collision_layer = 4   # layer 3 — NPC objects
	collision_mask  = 1   # hit world (1) only, prevents self-propulsion with interactable child


# ── Called when a body (player) enters the proximity sphere ──────────────────
func _on_body_entered(body: Node) -> void:
	if push_cooldown > 0.0:
		return
	if not body.has_method("show_log_message"):
		return
	push_cooldown = PUSH_COOLDOWN
	body.show_log_message("Resident: 'Don't push! Keep moving calmly!'")
	_play_voice_alert()

func _play_voice_alert() -> void:
	var aud = AudioStreamPlayer3D.new()
	aud.script = load("res://scripts/synth_audio_3d.gd")
	aud.synth_type = "npc_voice"
	aud.max_distance = 8.0
	aud.unit_size = 2.0
	get_tree().current_scene.add_child(aud)
	aud.global_position = global_position

# ── Physics process ───────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if not is_inside_tree():
		return
	if not GameManager.alarm_triggered:
		velocity = Vector3.ZERO
		move_and_slide()
		return
		
	if is_suitcase_npc and is_talking:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	if push_cooldown > 0.0:
		push_cooldown -= delta

	if _done:
		return

	if current_waypoint >= FULL_WAYPOINTS.size():
		_done = true
		queue_free()
		return

	var target : Vector3 = FULL_WAYPOINTS[current_waypoint]

	# Check horizontal (XZ) proximity only — gravity handles vertical
	var flat_self   = Vector3(global_position.x, 0.0, global_position.z)
	var flat_target = Vector3(target.x, 0.0, target.z)
	if flat_self.distance_to(flat_target) < WAYPOINT_REACH:
		current_waypoint += 1
		return

	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5   # small push to stay on ramp

	# Queue-detection: scan other NPCs ahead, slow down to avoid stacking (throttled to 0.2s)
	_queue_check_timer -= delta
	if _queue_check_timer <= 0.0:
		_queue_check_timer = 0.2
		_cached_speed_mult = _calculate_queue_speed()
	var speed_mult = _cached_speed_mult

	# Horizontal movement toward waypoint
	var current_npc_speed = NPC_SPEED
	if is_suitcase_npc:
		if not suitcase_resolved or suitcase_choice == 2:
			current_npc_speed = 0.8

	var dir_xz = (flat_target - flat_self).normalized()
	velocity.x = dir_xz.x * current_npc_speed * speed_mult
	velocity.z = dir_xz.z * current_npc_speed * speed_mult

	move_and_slide()

	# Face the direction of travel
	var move_xz = Vector3(velocity.x, 0.0, velocity.z)
	if move_xz.length() > 0.05:
		var look_target = global_position + move_xz
		look_at(look_target, Vector3.UP)

func resolve_suitcase(choice: int):
	suitcase_resolved = true
	suitcase_choice = choice
	is_talking = false
	if choice == 1:
		if is_instance_valid(suitcase_mesh):
			suitcase_mesh.visible = false
			# Spawn a dropped suitcase on the ground
			var ground_case = MeshInstance3D.new()
			ground_case.mesh = suitcase_mesh.mesh
			ground_case.material_override = suitcase_mesh.material_override
			get_parent().add_child(ground_case)
			ground_case.global_position = global_position + Vector3(0.0, 0.2, 0.0)
			ground_case.rotation = rotation
		var player = get_tree().current_scene.get_node_or_null("Player")
		if player:
			player.show_log_message("Resident: 'You're right, my life is more important! I'll leave the bags!'")
	else:
		var player = get_tree().current_scene.get_node_or_null("Player")
		if player:
			player.show_log_message("Resident: 'I can't leave my valuables! I'll carry them down!'")

func _calculate_queue_speed() -> float:
	if current_waypoint >= FULL_WAYPOINTS.size():
		return 1.0
	var target : Vector3 = FULL_WAYPOINTS[current_waypoint]
	var flat_self   = Vector3(global_position.x, 0.0, global_position.z)
	var flat_target = Vector3(target.x, 0.0, target.z)
	var forward_xz = (flat_target - flat_self).normalized()
	
	for other in get_tree().get_nodes_in_group("npcs"):
		if not is_instance_valid(other) or other == self:
			continue
		var to_other = other.global_position - global_position
		if abs(to_other.y) > 2.0:
			continue
		var to_other_xz = Vector3(to_other.x, 0.0, to_other.z)
		if to_other_xz.length() < QUEUE_RADIUS:
			var dot = forward_xz.dot(to_other_xz.normalized())
			if dot > 0.4:   # other NPC is ahead of us
				return QUEUE_SPEED_MUL
	return 1.0
