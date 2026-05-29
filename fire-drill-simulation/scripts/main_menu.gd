extends Control

@onready var tutorial_panel: Panel = $TutorialPanel

# Loading state
var _loading: bool = false
var _load_bar: ProgressBar = null
var _load_label: Label = null
var _load_overlay: ColorRect = null
var _smooth_progress: float = 0.0
var _load_time_elapsed: float = 0.0

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	GameManager.reset_state()
	tutorial_panel.visible = false
	$Panel/StartBtn.pressed.connect(_on_start_pressed)
	$Panel/TutorialBtn.pressed.connect(_on_tutorial_pressed)
	$Panel/ExitBtn.pressed.connect(_on_exit_pressed)
	$TutorialPanel/CloseBtn.pressed.connect(_on_close_tutorial_pressed)

func _on_start_pressed():
	if _loading:
		return
	_loading = true
	GameManager.reset_state()
	_show_loading_screen()
	if _load_bar:
		_load_bar.value = 0.5
	if _load_label:
		_load_label.text = "Loading Level..."
	
	# Wait 2 frames to ensure the engine renders the loading overlay before block-loading the level scene
	await get_tree().process_frame
	await get_tree().process_frame
	
	push_error("[MainMenu] Switching scene synchronously to res://scenes/level.tscn")
	var err = get_tree().change_scene_to_file("res://scenes/level.tscn")
	if err != OK:
		push_error("[MainMenu] Direct scene load failed with error code: ", err)
		_loading = false

func _show_loading_screen():
	# Dark overlay
	_load_overlay = ColorRect.new()
	_load_overlay.color = Color(0.05, 0.03, 0.02, 0.92)
	_load_overlay.anchor_right = 1.0
	_load_overlay.anchor_bottom = 1.0
	add_child(_load_overlay)

	# "Loading…" label
	_load_label = Label.new()
	_load_label.text = "Loading Level..."
	_load_label.add_theme_font_size_override("font_size", 28)
	_load_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.15))
	_load_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_load_label.anchor_left = 0.0
	_load_label.anchor_top = 0.4
	_load_label.anchor_right = 1.0
	_load_label.anchor_bottom = 0.4
	_load_label.offset_bottom = 40.0
	_load_overlay.add_child(_load_label)

	# Progress bar
	_load_bar = ProgressBar.new()
	_load_bar.min_value = 0.0
	_load_bar.max_value = 1.0
	_load_bar.value = 0.0
	_load_bar.anchor_left = 0.1
	_load_bar.anchor_top = 0.52
	_load_bar.anchor_right = 0.9
	_load_bar.anchor_bottom = 0.52
	_load_bar.offset_bottom = 28.0
	_load_bar.show_percentage = false
	# Style the bar
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.85, 0.4, 0.1)
	bar_fill.corner_radius_top_left = 5
	bar_fill.corner_radius_top_right = 5
	bar_fill.corner_radius_bottom_right = 5
	bar_fill.corner_radius_bottom_left = 5
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.15, 0.12, 0.1)
	bar_bg.corner_radius_top_left = 5
	bar_bg.corner_radius_top_right = 5
	bar_bg.corner_radius_bottom_right = 5
	bar_bg.corner_radius_bottom_left = 5
	_load_bar.add_theme_stylebox_override("fill", bar_fill)
	_load_bar.add_theme_stylebox_override("background", bar_bg)
	_load_overlay.add_child(_load_bar)

	# Tips label
	var tips = [
		"💡 Stay LOW in smoke — crouch to survive longer!",
		"🔥 Never use the elevator during a fire!",
		"📞 Call BOMBA (999) once you're safely outside.",
		"🚪 Feel the door before opening — hot = danger!",
		"🧴 A wet towel over your mouth reduces smoke inhalation.",
	]
	var tip_label = Label.new()
	tip_label.text = tips[randi() % tips.size()]
	tip_label.add_theme_font_size_override("font_size", 14)
	tip_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_label.anchor_left = 0.05
	tip_label.anchor_top = 0.62
	tip_label.anchor_right = 0.95
	tip_label.anchor_bottom = 0.62
	tip_label.offset_bottom = 60.0
	_load_overlay.add_child(tip_label)

func _process(_delta):
	pass

func _on_tutorial_pressed():
	tutorial_panel.visible = true

func _on_close_tutorial_pressed():
	tutorial_panel.visible = false

func _on_exit_pressed():
	get_tree().quit()
