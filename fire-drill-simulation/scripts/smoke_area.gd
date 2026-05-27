extends Area3D

# BUG 6 FIX: store the player reference on first detection instead of
# re-fetching via a hardcoded scene path, which breaks on scene renames.
var tracked_player = null

func _physics_process(_delta):
	var player_in_smoke = false
	for body in get_overlapping_bodies():
		if body.has_method("process_smoke_inhalation"):
			tracked_player = body
			body.in_smoke_zone = true
			player_in_smoke = true
			break
	if not player_in_smoke and tracked_player:
		tracked_player.in_smoke_zone = false
