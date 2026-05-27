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
		
	var file = FileAccess.open("c:/Users/den51/FireDrill-Simulation/fire-drill-simulation/scratch_check_out.txt", FileAccess.WRITE)
	if file == null:
		printerr("FAILED TO OPEN OUTPUT FILE")
		level.free()
		quit()
		return
		
	file.store_line("--- INSPECTING DOORS IN INSTANTIATED LEVEL ---")
	find_and_print_doors(level, file)
	file.close()
	print("Diagnostics written to c:/Users/den51/FireDrill-Simulation/fire-drill-simulation/scratch_check_out.txt")
	level.free()
	quit()

func find_and_print_doors(node: Node, file: FileAccess):
	if node is StaticBody3D and (node.name.to_lower().contains("door") or node.name.to_lower().contains("lift")):
		file.store_line("Node: " + node.name + " (" + str(node.get_path()) + ")")
		file.store_line("  Rotation Y Degrees: " + str(node.rotation_degrees.y))
		file.store_line("  Transform: " + str(node.transform))
		
		# Print children
		for child in node.get_children():
			file.store_line("  Child Node: " + child.name + " (" + child.get_class() + ")")
			file.store_line("    Transform: " + str(child.transform))
		file.store_line("----------------------------------------")
		
	for child in node.get_children():
		find_and_print_doors(child, file)
