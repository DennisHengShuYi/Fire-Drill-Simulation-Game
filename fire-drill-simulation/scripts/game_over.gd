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

	# Experience 8: show which specific bad choices were made this run
	var mistakes: Array = []
	if GameManager.stood_up_in_smoke:
		mistakes.append("• You stood upright in the smoke corridor (should crouch)")
	if GameManager.used_lift:
		mistakes.append("• You entered the elevator during a fire")
	if GameManager.opened_kitchen_door:
		mistakes.append("• You opened the hot kitchen door without checking")

	if mistakes.size() > 0:
		var tip_panel = $Panel/TipPanel
		var mistakes_label = Label.new()
		mistakes_label.text = "This run:\n" + "\n".join(mistakes)
		mistakes_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.2))
		mistakes_label.add_theme_font_size_override("font_size", 13)
		mistakes_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		if tip_panel:
			mistakes_label.position = Vector2(
				tip_panel.position.x,
				tip_panel.position.y + tip_panel.size.y + 16
			)
			mistakes_label.size = Vector2(tip_panel.size.x, 120)
		$Panel.add_child(mistakes_label)

	$Panel/TryAgainBtn.pressed.connect(_on_try_again_pressed)
	$Panel/MainMenuBtn.pressed.connect(_on_main_menu_pressed)

func _on_try_again_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/level.tscn")

func _on_main_menu_pressed():
	GameManager.reset_state()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
