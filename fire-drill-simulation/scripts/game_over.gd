extends Control

@onready var reason_label: Label = $Panel/ReasonLabel
@onready var tip_label: Label = $Panel/TipPanel/TipLabel

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if GameManager.game_over_reason != "":
		reason_label.text = GameManager.game_over_reason
	else:
		reason_label.text = "You did not make it out safely."
		
	if GameManager.game_over_tip != "":
		tip_label.text = GameManager.game_over_tip
	else:
		tip_label.text = "BOMBA TIP: Always stay calm, check doors for heat, crouch under smoke, avoid lifts, and call 999 once outside."

	$Panel/TryAgainBtn.pressed.connect(_on_try_again_pressed)
	$Panel/MainMenuBtn.pressed.connect(_on_main_menu_pressed)

func _on_try_again_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
