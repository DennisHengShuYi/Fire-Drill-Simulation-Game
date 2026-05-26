extends Area3D

func _physics_process(_delta):
	var player_in_smoke = false
	for body in get_overlapping_bodies():
		if body.name == "Player" or body.has_method("process_smoke_inhalation"):
			body.in_smoke_zone = true
			player_in_smoke = true
			break
	if not player_in_smoke:
		# Player is at root scene level
		var player = get_node_or_null("/root/Level/Player")
		if player:
			player.in_smoke_zone = false
