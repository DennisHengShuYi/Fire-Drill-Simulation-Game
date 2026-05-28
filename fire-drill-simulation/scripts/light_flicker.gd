extends OmniLight3D

@export var min_energy: float = 2.0
@export var max_energy: float = 5.0
@export var flicker_speed: float = 12.0

# BUG 5 FIX: make color override optional so emergency/corridor lights keep
# their designer-set colour. Set override_color = false on those lights in
# the scene; keep it true only on kitchen fire lights.
@export var override_color: bool = true
@export var flicker_color: Color = Color(1.0, 0.45, 0.08)

@export var is_emergency_light: bool = false
var original_energy: float = 1.0
var original_color: Color

var time: float = 0.0

func _ready():
	original_energy = light_energy
	original_color = light_color
	if override_color and not is_emergency_light:
		light_color = flicker_color

func _process(delta):
	if is_emergency_light:
		if GameManager.alarm_triggered:
			# Pulse green
			light_color = Color(0.2, 0.9, 0.3)
			time += delta * flicker_speed
			var flicker = sin(time) * cos(time * 0.7) * sin(time * 1.5)
			flicker = (flicker + 1.0) / 2.0
			light_energy = lerp(min_energy, max_energy, flicker)
		else:
			# Static normal white light
			light_color = Color(1.0, 1.0, 1.0)
			light_energy = original_energy
	else:
		time += delta * flicker_speed
		var flicker = sin(time) * cos(time * 0.7) * sin(time * 1.5)
		flicker = (flicker + 1.0) / 2.0
		light_energy = lerp(min_energy, max_energy, flicker)
