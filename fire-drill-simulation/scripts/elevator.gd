extends Area3D

var sequence_started: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if sequence_started:
		return
	if body.name == "Player":
		sequence_started = true
		run_elevator_sequence(body)

func run_elevator_sequence(player):
	player.in_elevator_sequence = true
	player.show_log_message("You step inside the lift. The elevator is starting...")
	GameManager.used_lift = true

	var lift_door_a = get_node_or_null("/root/Level/Geometry/ElevatorLobby/LiftA")
	var lift_door_b = get_node_or_null("/root/Level/Geometry/ElevatorLobby/LiftB")
	var cabin_light = get_node_or_null("/root/Level/Geometry/ElevatorLobby/CabinLight")

	await get_tree().create_timer(1.5).timeout

	# BUG 4 FIX: close doors by reversing the 1.5 unit slide that use_lift() opened them with.
	for lift_door in [lift_door_a, lift_door_b]:
		if lift_door:
			play_sound("door_creak")
			var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			var open_pos_x = lift_door.global_position.x
			var closed_pos_x = open_pos_x - 1.5
			tween.tween_property(lift_door, "global_position:x", closed_pos_x, 2.0)
			lift_door.door_opened = false
			tween.finished.connect(func():
				var col = lift_door.get_node_or_null("CollisionShape3D")
				if col:
					col.disabled = false
			)

	await get_tree().create_timer(2.4).timeout

	player.show_log_message("Lift doors closed. Descending... *HUMMMM*")
	var hum_sound = play_sound("elevator_hum")

	await get_tree().create_timer(2.0).timeout

	player.show_log_message("*CLANK* *SHUDDER* The lift shakes violently!")
	play_sound("elevator_clank")

	if hum_sound and is_instance_valid(hum_sound):
		hum_sound.stop()
		hum_sound.queue_free()

	# CODE 4 FIX: null-check cabin_light and its light_energy property
	if cabin_light and "light_energy" in cabin_light:
		for i in range(4):
			cabin_light.light_energy = 0.1 if i % 2 == 0 else 1.2
			await get_tree().create_timer(0.1).timeout
		cabin_light.light_energy = 0.0

	player.show_log_message("POWER FAILURE! Elevator stuck! Smoke begins seeping in...")
	player.in_smoke_zone = true

	for i in range(2):
		await get_tree().create_timer(1.2).timeout
		play_sound("sizzle")
		player.play_cough_sound()

	await get_tree().create_timer(1.0).timeout

	GameManager.trigger_game_over(
		"The elevator lost power and filled with toxic smoke, trapping you inside!",
		"BOMBA TIP: NEVER use an elevator (lift) during a fire! Power failures are extremely common as fire destroys electrical cables, trapping you. In addition, elevator shafts act like chimneys, drawing toxic smoke and hot gases straight to you. Always use the emergency stairs!"
	)

func play_sound(type: String) -> Node:
	var aud = AudioStreamPlayer3D.new()
	aud.script = load("res://scripts/synth_audio_3d.gd")
	aud.synth_type = type
	aud.global_position = global_position
	aud.max_distance = 15.0
	get_tree().current_scene.add_child(aud)
	return aud
