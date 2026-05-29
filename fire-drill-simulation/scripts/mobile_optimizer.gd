extends Node
## MobileOptimizer — runs once after every scene change on Android/iOS.
## Reduces CPU/GPU load by:
##   1. Reducing CPUParticles3D amount from 50-60 to 12
##   2. Disabling shadow casting on all lights (atlas already set to 0 via project.godot)
##   3. Physics FPS is already set to 30Hz via project.godot physics override

var _is_mobile: bool = false
var _scene_optimize_pending: bool = false

func _ready() -> void:
	_is_mobile = OS.get_name() in ["Android", "iOS"]
	if not _is_mobile:
		queue_free()  # Remove ourselves entirely on desktop — zero overhead
		return

	print("[MobileOptimizer] Mobile detected — applying optimizations")
	# Watch for newly added nodes (dynamically spawned fire spreads etc.)
	get_tree().node_added.connect(_on_node_added)
	# Apply to current scene after a brief defer so scene is fully ready
	call_deferred("_apply_scene_optimizations")


func _on_node_added(node: Node) -> void:
	# Only handle CPUParticles3D and lights that are dynamically added after scene load
	# (e.g. fire spread copies created by fire_area.gd at runtime)
	if not _is_mobile:
		return
	if not is_instance_valid(node) or not node.is_inside_tree():
		return
	if node is CPUParticles3D:
		_optimize_particles(node)
	elif node is OmniLight3D or node is SpotLight3D:
		_optimize_light(node as Light3D)


func _apply_scene_optimizations() -> void:
	var scene = get_tree().current_scene
	if not is_instance_valid(scene):
		return
	print("[MobileOptimizer] Optimizing scene: ", scene.name)
	# Disable glow — expensive extra GPU passes on mobile GL
	var world_env = scene.find_child("WorldEnvironment", true, false)
	if world_env and world_env.environment:
		world_env.environment.glow_enabled = false
		print("[MobileOptimizer] Glow disabled")
	_walk_and_optimize(scene)


func _walk_and_optimize(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node is CPUParticles3D:
		_optimize_particles(node as CPUParticles3D)
	elif node is OmniLight3D or node is SpotLight3D:
		_optimize_light(node as Light3D)
	for child in node.get_children():
		_walk_and_optimize(child)


func _optimize_particles(p: CPUParticles3D) -> void:
	# Reduce particle count: 50-60 → 12 (still visually readable, massively cheaper)
	if p.amount > 16:
		p.amount = 12
	# Cap lifetime to reduce per-frame live particle count
	if p.lifetime > 2.5:
		p.lifetime = 2.0
	# Reduce spread to save per-particle direction computation
	p.spread = clamp(p.spread, 0.0, 30.0)


func _optimize_light(light: Light3D) -> void:
	# Disable shadow casting (shadows already have atlas_size.mobile=0 in project.godot,
	# this ensures any programmatic lights respect mobile constraints)
	light.shadow_enabled = false
	# Cap energy for additive blending headroom (4 lights max on mobile GL)
	if light.light_energy > 4.0:
		light.light_energy = 4.0
