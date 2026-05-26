extends Control

@onready var tutorial_panel: Panel = $TutorialPanel

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	tutorial_panel.visible = false
	
	# Connect buttons programmatically
	$Panel/StartBtn.pressed.connect(_on_start_pressed)
	$Panel/TutorialBtn.pressed.connect(_on_tutorial_pressed)
	$Panel/ExitBtn.pressed.connect(_on_exit_pressed)
	$TutorialPanel/CloseBtn.pressed.connect(_on_close_tutorial_pressed)

func _on_start_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_tutorial_pressed():
	tutorial_panel.visible = true

func _on_close_tutorial_pressed():
	tutorial_panel.visible = false

func _on_exit_pressed():
	get_tree().quit()
