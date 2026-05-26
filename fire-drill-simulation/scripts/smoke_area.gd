extends Area3D

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
	if body.name == "Player" or body.has_method("process_smoke_inhalation"):
		body.in_smoke_zone = true

func _on_body_exited(body: Node3D):
	if body.name == "Player" or body.has_method("process_smoke_inhalation"):
		body.in_smoke_zone = false
