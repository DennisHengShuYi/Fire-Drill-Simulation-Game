extends SceneTree

func _init():
	var level_scene = load("res://scenes/level.tscn")
	var level = level_scene.instantiate()
	var file = FileAccess.open("c:/Users/den51/FireDrill-Simulation/fire-drill-simulation/scratch/find_npc_out.txt", FileAccess.WRITE)
	if file:
		var npc = level.find_child("SuitcaseNPC", true, false)
		if npc:
			file.store_line("SuitcaseNPC local position: " + str(npc.position))
			file.store_line("SuitcaseNPC global position: " + str(npc.global_position))
			file.store_line("Parent node name: " + npc.get_parent().name)
			file.store_line("Parent global position: " + str(npc.get_parent().global_position) if npc.get_parent() is Node3D else "Parent not Node3D")
		else:
			file.store_line("SuitcaseNPC NOT FOUND in level.tscn!")
		file.close()
	level.free()
	quit()
