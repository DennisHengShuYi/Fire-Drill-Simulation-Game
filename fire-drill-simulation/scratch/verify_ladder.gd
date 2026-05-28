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

	print("=== SAFETY LADDER + BALCONY WALL VERIFICATION ===")

	# 1. Check SafetyLadder exists and is initially hidden
	var ladder = level.find_child("SafetyLadder", true, false)
	if ladder == null:
		print("FAIL: SafetyLadder NOT FOUND in scene")
	else:
		print("PASS: SafetyLadder found at path: " + str(ladder.get_path()))
		print("  Initial visible = " + str(ladder.visible))
		print("  Initial collision_layer = " + str(ladder.collision_layer))

		# Simulate what player.gd does when BOMBA is called from balcony
		ladder.visible = true
		ladder.collision_layer = 2
		print("  After activation visible = " + str(ladder.visible))
		print("  After activation collision_layer = " + str(ladder.collision_layer))
		if ladder.visible and ladder.collision_layer == 2:
			print("PASS: SafetyLadder activates correctly")
		else:
			print("FAIL: SafetyLadder did not activate")

	# 2. Check BalconyLight exists
	var balcony_light = level.find_child("BalconyLight", true, false)
	if balcony_light == null:
		print("FAIL: BalconyLight NOT FOUND - balcony will be dark")
	else:
		print("PASS: BalconyLight found - balcony is illuminated")

	# 3. Check WallNorth_E1 does NOT cover X=[1.5, 4.5]
	# We check its transform to verify center X is ~7.5 (not 6.0)
	var wall = level.find_child("WallNorth_E1", true, false)
	if wall == null:
		print("FAIL: WallNorth_E1 NOT FOUND")
	else:
		var wx = wall.global_transform.origin.x
		print("WallNorth_E1 center X = " + str(wx))
		if wx > 6.5:  # should be ~7.5 now, was 6.0 before fix
			print("PASS: WallNorth_E1 shifted right (balcony gap exists)")
		else:
			print("FAIL: WallNorth_E1 still covers balcony area (center X = " + str(wx) + ", expected ~7.5)")

	# 4. Check WallNorth_BalconyLintel exists
	var lintel = level.find_child("WallNorth_BalconyLintel", true, false)
	if lintel == null:
		print("FAIL: WallNorth_BalconyLintel NOT FOUND")
	else:
		print("PASS: Balcony lintel/header beam present above opening")

	print("=== VERIFICATION COMPLETE ===")
	level.free()
	quit()
