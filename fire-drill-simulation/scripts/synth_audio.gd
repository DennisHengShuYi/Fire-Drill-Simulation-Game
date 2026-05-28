extends AudioStreamPlayer

@export var synth_type: String = "alarm"
@export var play_on_start: bool = true

var playback: AudioStreamGeneratorPlayback
var phase: float = 0.0
var pulse_timer: float = 0.0
var is_pulse_on: bool = true

func _ready():
	# Try to load high-fidelity imported asset first
	var stream_file = ""
	if synth_type == "alarm":
		stream_file = "res://assets/fire-alarm.mp3"
	elif synth_type == "cough":
		stream_file = "res://assets/coughing-sound-effect-type-10-294179.mp3"
		
	if stream_file != "" and ResourceLoader.exists(stream_file):
		var res = load(stream_file)
		if res:
			stream = res
			if synth_type == "alarm" and stream is AudioStreamMP3:
				stream.loop = true
			if play_on_start:
				play()
			return
			
	# Fallback to programmatic synthesis
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 22050
	gen.buffer_length = 0.1
	stream = gen
	if play_on_start:
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
			if synth_type == "alarm":
				pulse_timer += 1.0 / mix_rate
				if pulse_timer >= 0.3:
					pulse_timer = 0.0
					is_pulse_on = not is_pulse_on
				if is_pulse_on:
					sample = sin(phase) * 0.15
					phase += 2.0 * PI * 800.0 / mix_rate
				else:
					sample = 0.0
			elif synth_type == "cough":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.0 - pulse_timer * 3.0)
				sample = (randf() * 2.0 - 1.0) * 0.15 * volume
				if volume <= 0.0:
					queue_free()
					return
			elif synth_type == "click":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.0 - pulse_timer * 30.0)
				sample = (randf() * 2.0 - 1.0) * 0.15 * volume
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
			elif synth_type == "burn":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.0 - pulse_timer * 2.5) # sizzle sound over 0.4 seconds
				phase += 2.0 * PI * 180.0 / mix_rate
				sample = (randf() * 2.0 - 1.0) * 0.3 * volume + sin(phase) * 0.08 * volume
				if volume <= 0.0:
					queue_free()
					return
			elif synth_type == "wrong":
				pulse_timer += 1.0 / mix_rate
				var volume = max(0.0, 1.0 - pulse_timer * 4.0)
				phase += 2.0 * PI * 150.0 / mix_rate
				sample = sin(phase) * 0.2 * volume
				if volume <= 0.0:
					queue_free()
					return
					
			buffer[i] = Vector2(sample, sample)
			
		playback.push_buffer(buffer)
