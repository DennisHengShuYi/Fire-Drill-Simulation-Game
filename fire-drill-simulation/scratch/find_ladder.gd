extends SceneTree

func _init():
	var level_scene = load("res://scenes/level.tscn")
	if level_scene == null:
		printerr("FAILED TO LOAD LEVEL SCENE")
		quit()
		return
		
	var level = level_scene.instantiate()
	if level == null:
		printerr("FAILED TO INSTANTIATE LEVEL SCENE")
		quit()
		return
		
	print("--- SEARCHING FOR Nodes ---")
	
	# Test find_child with recursive=true and owned=false
	var ladder_owned_false = level.find_child("SafetyLadder", true, false)
	print("find_child('SafetyLadder', true, false): ", ladder_owned_false)
	
	# Test find_child with recursive=true and owned=true (default)
	var ladder_owned_true = level.find_child("SafetyLadder", true, true)
	print("find_child('SafetyLadder', true, true): ", ladder_owned_true)
	
	# Recursively search children manually
	var manual_found = find_node_by_name(level, "SafetyLadder")
	print("manual_found: ", manual_found)
	if manual_found:
		print("  Path: ", manual_found.get_path())
		print("  Visible: ", manual_found.visible)
		print("  Collision Layer: ", manual_found.collision_layer)
		
	level.free()
	quit()

func find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node
	for child in node.get_children():
		var found = find_node_by_name(child, target_name)
		if found:
			return found
	return null
