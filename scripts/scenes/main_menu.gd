extends Control


func _ready() -> void:
	theme = load("res://themes/default_theme.tres")
	_setup_ui()
	_setup_input()


func _setup_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var title := Label.new()
	title.text = "CoreHexa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 64)
	vbox.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(spacer)

	var btn_single := _create_button("单人游戏")
	btn_single.pressed.connect(_on_single_player)
	vbox.add_child(btn_single)

	var btn_settings := _create_button("设  置")
	btn_settings.pressed.connect(_on_settings)
	vbox.add_child(btn_settings)

	var btn_exit := _create_button("退  出")
	btn_exit.pressed.connect(_on_exit)
	vbox.add_child(btn_exit)

	var center := CenterContainer.new()
	center.anchors_preset = Control.PRESET_FULL_RECT
	center.add_child(vbox)
	add_child(center)


func _create_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 60)
	return btn


func _setup_input() -> void:
	pass


func _on_single_player() -> void:
	get_tree().change_scene_to_file("res://scenes/song_select.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/settings.tscn")


func _on_exit() -> void:
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_show_exit_dialog()


func _show_exit_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "退出"
	dialog.dialog_text = "确定要退出游戏吗？"
	dialog.confirmed.connect(get_tree().quit)
	add_child(dialog)
	dialog.popup_centered()
