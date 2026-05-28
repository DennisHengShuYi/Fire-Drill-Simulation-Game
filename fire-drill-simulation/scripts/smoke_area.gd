extends Area3D

# BUG 6 FIX: store the player reference on first detection instead of
# re-fetching via a hardcoded scene path, which breaks on scene renames.
var tracked_player = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.has_method("process_smoke_inhalation") and "in_smoke_zone" in body:
		tracked_player = body
		var active_smokes = body.get_meta("active_smokes", [])
		if not active_smokes.has(self):
			active_smokes.append(self)
			body.set_meta("active_smokes", active_smokes)
		body.in_smoke_zone = true

func _on_body_exited(body):
	if body == tracked_player:
		if is_instance_valid(tracked_player):
			var active_smokes = tracked_player.get_meta("active_smokes", [])
			active_smokes.erase(self)
			tracked_player.set_meta("active_smokes", active_smokes)
			if active_smokes.size() == 0:
				tracked_player.in_smoke_zone = false
		tracked_player = null
