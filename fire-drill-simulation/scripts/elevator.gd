extends Area3D

var sequence_started: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if sequence_started:
		return
		
	# Check if the body is the Player
	if body.name == "Player":
		sequence_started = true
		run_elevator_sequence(body)

func run_elevator_sequence(player):
	player.in_elevator_sequence = true
	player.show_log_message("You step inside the lift. The elevator is starting...")
	GameManager.used_lift = true
	
	# Reference to lift doors and cabin light
	var lift_door_a = get_node_or_null("/root/Level/Geometry/ElevatorLobby/LiftA")
	var lift_door_b = get_node_or_null("/root/Level/Geometry/ElevatorLobby/LiftB")
	var cabin_light = get_node_or_null("/root/Level/Geometry/ElevatorLobby/CabinLight")
	
	# Wait a moment before closing the doors
	await get_tree().create_timer(1.5).timeout
	
	# Close doors: slide them away
	for lift_door in [lift_door_a, lift_door_b]:
		if lift_door:
			play_sound("door_creak")
			var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			# Slide door back to closed X pos
			var closed_x = lift_door.global_position.x
			tween.tween_property(lift_door, "global_position:x", closed_x, 2.0)
			lift_door.door_opened = false
			tween.finished.connect(func():
				var col = lift_door.get_node_or_null("CollisionShape3D")
				if col:
					col.disabled = false
		)
		
	# Wait for door to close (2.0s animation + 0.4s buffer)
	await get_tree().create_timer(2.4).timeout
	
	# Start descending: play elevator hum
	player.show_log_message("Lift doors closed. Descending... *HUMMMM*")
	var hum_sound = play_sound("elevator_hum")
	
	# Let it descend for 2.0 seconds
	await get_tree().create_timer(2.0).timeout
	
	# Elevator crash / power cut
	player.show_log_message("*CLANK* *SHUDDER* The lift shakes violently!")
	play_sound("elevator_clank")
	
	# Stop hum
	if hum_sound:
		hum_sound.stop()
		hum_sound.queue_free()
		
	# Flicker and cut lights
	if cabin_light:
		for i in range(4):
			cabin_light.light_energy = 0.1 if i % 2 == 0 else 1.2
			await get_tree().create_timer(0.1).timeout
		cabin_light.light_energy = 0.0
		
	player.show_log_message("POWER FAILURE! Elevator stuck! Smoke begins seeping in...")
	
	# Spawn a small smoke source or overlay
	player.in_smoke_zone = true # Will cause player to cough/take damage to simulate smoke ingress
	
	# Play continuous coughs and alarm beeps
	for i in range(2):
		await get_tree().create_timer(1.2).timeout
		play_sound("sizzle") # sizzle represents electrical sparks
		player.play_cough_sound()
		
	await get_tree().create_timer(1.0).timeout
	
	# Trigger Game Over
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
