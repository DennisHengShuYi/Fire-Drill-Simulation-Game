extends OmniLight3D

@export var min_energy: float = 2.0
@export var max_energy: float = 5.0
@export var flicker_speed: float = 12.0

# BUG 5 FIX: make color override optional so emergency/corridor lights keep
# their designer-set colour. Set override_color = false on those lights in
# the scene; keep it true only on kitchen fire lights.
@export var override_color: bool = true
@export var flicker_color: Color = Color(1.0, 0.45, 0.08)

var time: float = 0.0

func _ready():
	if override_color:
		light_color = flicker_color

func _process(delta):
	time += delta * flicker_speed
	var flicker = sin(time) * cos(time * 0.7) * sin(time * 1.5)
	flicker = (flicker + 1.0) / 2.0
	light_energy = lerp(min_energy, max_energy, flicker)
