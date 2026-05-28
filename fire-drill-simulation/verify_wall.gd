extends SceneTree

func _init():
	var level_scene = load("res://scenes/level.tscn")
	if level_scene == null:
		printerr("FAILED TO LOAD LEVEL")
		quit()
		return
		
	var level = level_scene.instantiate()
	if level == null:
		printerr("FAILED TO INSTANTIATE")
		quit()
		return
		
	var file = FileAccess.open("c:/Users/den51/FireDrill-Simulation/fire-drill-simulation/verify_wall_out.txt", FileAccess.WRITE)
	if file == null:
		level.free()
		quit()
		return
		
	var wall = level.find_child("CorridorMiddleWall", true, false)
	if wall == null:
		file.store_line("CorridorMiddleWall not found!")
	else:
		file.store_line("FOUND CorridorMiddleWall:")
		file.store_line("  Class: " + wall.get_class())
		file.store_line("  Position: " + str(wall.global_position))
		file.store_line("  Use Collision: " + str(wall.use_collision))
		file.store_line("  Collision Layer: " + str(wall.collision_layer))
		file.store_line("  Collision Mask: " + str(wall.collision_mask))
		file.store_line("  Visible: " + str(wall.visible))
		
	file.close()
	level.free()
	quit()
