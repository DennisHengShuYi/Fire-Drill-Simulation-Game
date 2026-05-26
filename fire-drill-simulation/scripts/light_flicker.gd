extends OmniLight3D

@export var min_energy: float = 2.0
@export var max_energy: float = 5.0
@export var flicker_speed: float = 12.0

var time: float = 0.0

func _ready():
	# Give it a warm fire orange color
	light_color = Color(1.0, 0.45, 0.08)

func _process(delta):
	time += delta * flicker_speed
	# Simple noise-like flicker using sin waves of different frequencies
	var flicker = sin(time) * cos(time * 0.7) * sin(time * 1.5)
	# Normalize to 0-1 range
	flicker = (flicker + 1.0) / 2.0
	# Set energy
	light_energy = lerp(min_energy, max_energy, flicker)
