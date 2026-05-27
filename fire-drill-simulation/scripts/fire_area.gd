extends Area3D

var tracked_player = null

func _physics_process(_delta):
	var player_in_fire = false
	for body in get_overlapping_bodies():
		if body.has_method("process_smoke_inhalation") and "in_fire_zone" in body:
			tracked_player = body
			body.in_fire_zone = true
			player_in_fire = true
			break
	if not player_in_fire and tracked_player:
		tracked_player.in_fire_zone = false
