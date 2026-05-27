extends AudioStreamPlayer3D

@export var synth_type: String = "fire_crackle"

var playback: AudioStreamGeneratorPlayback
var phase: float = 0.0
var pulse_timer: float = 0.0

func _ready():
	# Try to load high-fidelity imported asset first
	var stream_file = ""
	if synth_type == "fire_crackle":
		stream_file = "res://assets/fire cracking.mp3"
	elif synth_type == "sizzle":
		stream_file = "res://assets/steam-hissing-386157.mp3"
	elif synth_type == "door_creak":
		stream_file = "res://assets/creaky-old-door-472357.mp3"
	elif synth_type == "elevator_clank":
		stream_file = "res://assets/elevator-crash-sound-376882.mp3"
		
	if stream_file != "" and ResourceLoader.exists(stream_file):
		var res = load(stream_file)
		if res:
			stream = res
			if (synth_type == "fire_crackle" or synth_type == "elevator_hum") and stream is AudioStreamMP3:
				stream.loop = true
			play()
			return
			
	# Fallback to programmatic synthesis
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
	stream = gen
	play()
	playback = get_stream_playback()

func _process(_delta):
	if not playback:
		return
		
	var mix_rate = stream.mix_rate
	var frames = playback.get_frames_available()
	
	if frames > 0:
		var buffer = PackedVector2Array()
		buffer.resize(frames)
		
		for i in range(frames):
			var sample = 0.0
			if synth_type == "fire_crackle":
				phase += 2.0 * PI * 60.0 / mix_rate
				var rumble = sin(phase) * 0.08
				var crackle = 0.0
				if randf() < 0.002:
					crackle = (randf() * 2.0 - 1.0) * 0.6
				sample = rumble + crackle
			elif synth_type == "sizzle":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.0 - pulse_timer * 2.5)
				sample = (randf() * 2.0 - 1.0) * 0.15 * volume
				if volume <= 0.0:
					queue_free()
					return
			elif synth_type == "door_creak":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.0 - pulse_timer * 1.5)
				phase += 2.0 * PI * (120.0 - pulse_timer * 40.0) / mix_rate
				sample = sin(phase) * 0.1 * volume
				if volume <= 0.0:
					queue_free()
					return
			elif synth_type == "elevator_hum":
				phase += 2.0 * PI * 65.0 / mix_rate
				sample = sin(phase) * 0.15 + (randf() * 2.0 - 1.0) * 0.02
			elif synth_type == "elevator_clank":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.0 - pulse_timer * 2.0)
				phase += 2.0 * PI * 110.0 / mix_rate
				sample = (sin(phase) + (randf() * 2.0 - 1.0) * 0.3) * 0.3 * volume
				if volume <= 0.0:
					queue_free()
					return
			elif synth_type == "npc_voice":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.0 - pulse_timer * 1.5)
				phase += 2.0 * PI * (350.0 + sin(pulse_timer * 40.0) * 80.0) / mix_rate
				sample = sin(phase) * 0.25 * volume
				if volume <= 0.0:
					queue_free()
					return
			elif synth_type == "help_muffled":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.2 - pulse_timer * 0.8) # lasts 1.5s
				phase += 2.0 * PI * (250.0 + sin(pulse_timer * 20.0) * 60.0) / mix_rate
				var base_wave = sin(phase) * 0.2
				var speech_noise = (randf() * 2.0 - 1.0) * 0.015
				sample = (base_wave + speech_noise) * volume
				if volume <= 0.0:
					queue_free()
					return
					
			buffer[i] = Vector2(sample, sample)
			
		playback.push_buffer(buffer)
