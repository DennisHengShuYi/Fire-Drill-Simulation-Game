extends SceneTree

func _init():
	var level_scene = load("res://scenes/level.tscn")
	if level_scene == null:
		printerr("FAIL: level.tscn could not be loaded")
		quit(1)
		return
	
	var level = level_scene.instantiate()
	if level == null:
		printerr("FAIL: level.tscn could not be instantiated")
		quit(1)
		return
	
	# --- 1. Check FireExtinguisher node ---
	var fe = level.get_node_or_null("Geometry/Apartment/FireExtinguisher")
	if fe == null:
		fe = _find_node_by_name(level, "FireExtinguisher")
	if fe == null:
		printerr("FAIL: FireExtinguisher node not found in scene")
	else:
		print("OK: FireExtinguisher found at " + str(fe.global_position) if fe.is_inside_tree() else "OK: FireExtinguisher found")
		# Check is_extinguisher property
		if "is_extinguisher" in fe:
			print("OK: is_extinguisher = " + str(fe.is_extinguisher))
		else:
			printerr("FAIL: FireExtinguisher missing is_extinguisher property")

	# --- 2. Check CorridorExtinguisher node ---
	var ce = _find_node_by_name(level, "CorridorExtinguisher")
	if ce == null:
		printerr("FAIL: CorridorExtinguisher node not found in scene")
	else:
		print("OK: CorridorExtinguisher found")
		if "is_extinguisher" in ce:
			print("OK: is_extinguisher = " + str(ce.is_extinguisher))
		else:
			printerr("FAIL: CorridorExtinguisher missing is_extinguisher property")

	# --- 3. Check warning signs exist ---
	var fe_sign = _find_node_by_name(level, "FireExtinguisher_Sign")
	print("OK: FireExtinguisher_Sign: " + ("FOUND" if fe_sign != null else "MISSING"))
	var ce_sign = _find_node_by_name(level, "CorridorExtinguisher_Sign")
	print("OK: CorridorExtinguisher_Sign: " + ("FOUND" if ce_sign != null else "MISSING"))

	# --- 4. Check fire hazard areas for shrink_fire ---
	var fires = []
	_collect_by_class(level, "Area3D", fires)
	var shrink_count = 0
	for f in fires:
		if f.has_method("shrink_fire"):
			shrink_count += 1
	print("OK: Fire areas with shrink_fire(): " + str(shrink_count))

	# --- 5. Check Player node ---
	var player = _find_node_by_name(level, "Player")
	if player == null:
		printerr("FAIL: Player node not found in scene")
	else:
		print("OK: Player found")
		var has_minigame = player.has_method("start_extinguisher_minigame")
		print(("OK" if has_minigame else "FAIL") + ": start_extinguisher_minigame method " + ("found" if has_minigame else "MISSING"))
		var has_process = player.has_method("process_minigame_key")
		print(("OK" if has_process else "FAIL") + ": process_minigame_key method " + ("found" if has_process else "MISSING"))

	level.free()
	print("\n=== HEADLESS CHECK COMPLETE ===")
	quit()

func _find_node_by_name(root: Node, target_name: String) -> Node:
	if root.name == target_name:
		return root
	for child in root.get_children():
		var r = _find_node_by_name(child, target_name)
		if r != null:
			return r
	return null

func _collect_by_class(root: Node, class_name_filter: String, result: Array):
	if root.get_class() == class_name_filter:
		result.append(root)
	for child in root.get_children():
		_collect_by_class(child, class_name_filter, result)
