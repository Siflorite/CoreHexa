extends Control

var window_mode_option: OptionButton
var resolution_option: OptionButton
var vsync_option: OptionButton
var fps_option: OptionButton
var volume_slider: HSlider
var skin_option: OptionButton
var skin_list: Array[String] = []
var volume_label: Label = null

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]


func _ready() -> void:
	theme = load("res://themes/default_theme.tres")
	_scan_skins()
	_setup_ui()
	_refresh_controls()


func _scan_skins() -> void:
	skin_list.clear()
	var dir := DirAccess.open("res://skins/")
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			var json_path := "res://skins/" + entry + "/skin.json"
			if FileAccess.file_exists(json_path):
				skin_list.append(json_path)
		entry = dir.get_next()
	dir.list_dir_end()


func _setup_ui() -> void:
	var back_btn := Button.new()
	back_btn.text = "← 返回"
	back_btn.position = Vector2(20, 20)
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 0)
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	vbox.add_child(_make_row("窗口模式"))
	window_mode_option = OptionButton.new()
	window_mode_option.add_item("窗口化", DisplayServer.WINDOW_MODE_WINDOWED)
	window_mode_option.add_item("无边框全屏", DisplayServer.WINDOW_MODE_FULLSCREEN)
	window_mode_option.add_item("独占全屏", DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	window_mode_option.item_selected.connect(_on_window_mode_changed)
	vbox.add_child(window_mode_option)

	vbox.add_child(_make_row("分辨率"))
	resolution_option = OptionButton.new()
	for res in RESOLUTIONS:
		resolution_option.add_item("%d × %d" % [res.x, res.y])
	resolution_option.item_selected.connect(_on_resolution_changed)
	vbox.add_child(resolution_option)

	vbox.add_child(_make_row("垂直同步"))
	vsync_option = OptionButton.new()
	vsync_option.add_item("关", DisplayServer.VSYNC_DISABLED)
	vsync_option.add_item("开", DisplayServer.VSYNC_ENABLED)
	vsync_option.add_item("自适应", DisplayServer.VSYNC_ADAPTIVE)
	vsync_option.item_selected.connect(_on_vsync_changed)
	vbox.add_child(vsync_option)

	vbox.add_child(_make_row("帧率上限"))
	fps_option = OptionButton.new()
	fps_option.add_item("30")
	fps_option.add_item("60")
	fps_option.add_item("120")
	fps_option.add_item("144")
	fps_option.add_item("240")
	fps_option.add_item("无限制")
	fps_option.item_selected.connect(_on_fps_changed)
	vbox.add_child(fps_option)

	vbox.add_child(_make_row("音量"))
	volume_slider = HSlider.new()
	volume_slider.min_value = 0
	volume_slider.max_value = 100
	volume_slider.step = 1
	volume_slider.custom_minimum_size = Vector2(400, 0)
	volume_label = Label.new()
	volume_slider.value_changed.connect(_on_volume_changed)
	vbox.add_child(volume_slider)
	vbox.add_child(volume_label)

	vbox.add_child(_make_row("默认皮肤"))
	skin_option = OptionButton.new()
	for sp in skin_list:
		var skin_name := sp.get_base_dir().get_file()
		skin_option.add_item(skin_name)
	skin_option.item_selected.connect(_on_skin_changed)
	vbox.add_child(skin_option)


func _make_row(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 24)
	return label


func _refresh_controls() -> void:
	for i in window_mode_option.item_count:
		if window_mode_option.get_item_id(i) == GameState.window_mode:
			window_mode_option.selected = i
			break

	for i in resolution_option.item_count:
		if RESOLUTIONS[i] == GameState.resolution:
			resolution_option.selected = i
			break

	for i in vsync_option.item_count:
		if vsync_option.get_item_id(i) == GameState.vsync_mode:
			vsync_option.selected = i
			break

	match GameState.target_fps:
		30: fps_option.selected = 0
		60: fps_option.selected = 1
		120: fps_option.selected = 2
		144: fps_option.selected = 3
		240: fps_option.selected = 4
		_: fps_option.selected = 5

	volume_slider.value = GameState.master_volume * 100
	volume_label.text = "%d%%" % int(volume_slider.value)

	if not GameState.skin_path.is_empty():
		for i in range(skin_list.size()):
			if skin_list[i] == GameState.skin_path:
				skin_option.selected = i
				break


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_window_mode_changed(idx: int) -> void:
	GameState.window_mode = window_mode_option.get_item_id(idx)
	GameState.apply_settings()
	GameState.save_settings()


func _on_resolution_changed(idx: int) -> void:
	GameState.resolution = RESOLUTIONS[idx]
	GameState.apply_settings()
	GameState.save_settings()


func _on_vsync_changed(idx: int) -> void:
	GameState.vsync_mode = vsync_option.get_item_id(idx)
	GameState.apply_settings()
	GameState.save_settings()


func _on_fps_changed(idx: int) -> void:
	var fps_values := [30, 60, 120, 144, 240, 0]
	GameState.target_fps = fps_values[idx]
	GameState.apply_settings()
	GameState.save_settings()


func _on_volume_changed(value: float) -> void:
	GameState.master_volume = value / 100.0
	volume_label.text = "%d%%" % int(value)
	GameState.apply_settings()
	GameState.save_settings()


func _on_skin_changed(idx: int) -> void:
	if idx >= 0 and idx < skin_list.size():
		GameState.skin_path = skin_list[idx]
		GameState.save_settings()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
