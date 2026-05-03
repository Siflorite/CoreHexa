extends Control

var chart_list: Array[Dictionary] = []
var chart_entries: Array[Panel] = []
var selected_index: int = -1

var scroll_container: ScrollContainer
var entry_container: VBoxContainer
var skin_option: OptionButton
var scroll_time_slider: HSlider
var scroll_time_input: LineEdit
var skin_list: Array[String] = []


func _ready() -> void:
	theme = load("res://themes/default_theme.tres")
	_scan_skins()
	_scan_charts()
	_setup_ui()


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


func _scan_charts() -> void:
	chart_list.clear()
	var dir := DirAccess.open("res://charts/")
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			var subdir := "res://charts/" + entry
			var sub := DirAccess.open(subdir)
			if sub != null:
				sub.list_dir_begin()
				var file := sub.get_next()
				while file != "":
					if file.ends_with(".json") and not sub.current_is_dir():
						var full_path := subdir + "/" + file
						var meta := _load_chart_meta(full_path)
						if meta != null:
							meta["path"] = full_path
							chart_list.append(meta)
					file = sub.get_next()
				sub.list_dir_end()
		entry = dir.get_next()
	dir.list_dir_end()


func _load_chart_meta(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		return {}
	if not json.data is Dictionary:
		return {}
	var data: Dictionary = json.data
	var meta: Dictionary = data.get("meta", {})
	return {
		"title": meta.get("title", ""),
		"title_unicode": meta.get("title_unicode", meta.get("title", "")),
		"artist": meta.get("artist", ""),
		"artist_unicode": meta.get("artist_unicode", meta.get("artist", "")),
		"creator": meta.get("creator", ""),
		"version": meta.get("version", ""),
		"background": meta.get("background", ""),
	}


func _setup_ui() -> void:
	var back_btn := Button.new()
	back_btn.text = "← 返回"
	back_btn.position = Vector2(20, 20)
	back_btn.custom_minimum_size = Vector2(120, 40)
	back_btn.pressed.connect(_on_back)
	add_child(back_btn)

	scroll_container = ScrollContainer.new()
	scroll_container.anchor_left = 0.0
	scroll_container.anchor_right = 1.0
	scroll_container.anchor_top = 0.0
	scroll_container.anchor_bottom = 1.0
	scroll_container.offset_left = 40
	scroll_container.offset_right = -300
	scroll_container.offset_top = 80
	scroll_container.offset_bottom = -40
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.follow_focus = true
	add_child(scroll_container)

	entry_container = VBoxContainer.new()
	entry_container.size_flags_horizontal = Control.SIZE_FILL
	entry_container.add_theme_constant_override("separation", 4)
	scroll_container.add_child(entry_container)

	for i in chart_list.size():
		var entry := _create_chart_entry(chart_list[i], i)
		chart_entries.append(entry)
		entry_container.add_child(entry)

	var sidebar := Panel.new()
	sidebar.anchor_left = 1.0
	sidebar.anchor_right = 1.0
	sidebar.anchor_top = 0.0
	sidebar.anchor_bottom = 1.0
	sidebar.offset_left = -300
	add_child(sidebar)

	var side_vbox := VBoxContainer.new()
	side_vbox.anchor_left = 1.0
	side_vbox.anchor_right = 1.0
	side_vbox.anchor_top = 0.0
	side_vbox.anchor_bottom = 1.0
	side_vbox.offset_left = -280
	side_vbox.offset_top = 80
	side_vbox.offset_right = -20
	side_vbox.offset_bottom = -40
	side_vbox.add_theme_constant_override("separation", 16)
	add_child(side_vbox)

	side_vbox.add_child(_make_side_label("皮肤"))
	skin_option = OptionButton.new()
	for sp in skin_list:
		var skin_name := sp.get_base_dir().get_file()
		skin_option.add_item(skin_name)
	skin_option.item_selected.connect(_on_skin_changed)
	side_vbox.add_child(skin_option)

	side_vbox.add_child(_make_side_label("下落时间 (scroll_time)"))

	var st_hbox := HBoxContainer.new()
	st_hbox.add_theme_constant_override("separation", 8)
	side_vbox.add_child(st_hbox)

	scroll_time_slider = HSlider.new()
	scroll_time_slider.min_value = 0.1
	scroll_time_slider.max_value = 2.0
	scroll_time_slider.step = 0.01
	scroll_time_slider.custom_minimum_size = Vector2(140, 0)
	scroll_time_slider.tick_count = 8
	scroll_time_slider.ticks_on_borders = true
	scroll_time_slider.value_changed.connect(_on_scroll_time_slider_changed)
	st_hbox.add_child(scroll_time_slider)

	scroll_time_input = LineEdit.new()
	scroll_time_input.custom_minimum_size = Vector2(60, 36)
	scroll_time_input.placeholder_text = "0.5"
	scroll_time_input.text_submitted.connect(_on_scroll_time_input)
	scroll_time_input.focus_exited.connect(_on_scroll_time_input)
	st_hbox.add_child(scroll_time_input)

	_refresh_sidebar()

	call_deferred("select_entry", 0 if chart_list.size() > 0 else -1)


func _create_chart_entry(data: Dictionary, index: int) -> Panel:
	var panel := Panel.new()
	panel.custom_minimum_size = Vector2(0, 72)
	panel.size_flags_horizontal = Control.SIZE_FILL

	var vbox := VBoxContainer.new()
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	vbox.add_theme_constant_override("separation", 0)
	panel.add_child(vbox)

	var title_label := Label.new()
	title_label.text = "%s — %s" % [data.title_unicode, data.artist_unicode]
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_label)

	var info_label := Label.new()
	info_label.text = "Mapped by %s  |  %s" % [data.creator, data.version]
	info_label.add_theme_font_size_override("font_size", 16)
	info_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(info_label)

	panel.gui_input.connect(_on_entry_input.bind(index))
	return panel


func _make_side_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	return label


func _refresh_sidebar() -> void:
	if not GameState.skin_path.is_empty():
		for i in range(skin_list.size()):
			if skin_list[i] == GameState.skin_path:
				skin_option.selected = i
				break

	var st_value: float = GameState.scroll_time if GameState.scroll_time > 0 else 0.5
	scroll_time_slider.set_value_no_signal(st_value)
	scroll_time_input.text = "%.2f" % st_value


func select_entry(index: int) -> void:
	if index < 0 or index >= chart_entries.size():
		return

	if selected_index >= 0 and selected_index < chart_entries.size():
		_update_entry_style(selected_index, false)

	selected_index = index
	_update_entry_style(selected_index, true)

	var target_global := chart_entries[index].global_position.y
	scroll_container.scroll_vertical = int(target_global - scroll_container.global_position.y - 300)


func _update_entry_style(index: int, selected: bool) -> void:
	var panel := chart_entries[index]
	if selected:
		panel.self_modulate = Color(0.7, 0.9, 1.0)
	else:
		panel.self_modulate = Color(1.0, 1.0, 1.0)


func _on_entry_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if selected_index == index:
				_confirm_selection()
			else:
				select_entry(index)


func _confirm_selection() -> void:
	if selected_index < 0 or selected_index >= chart_list.size():
		return
	GameState.chart_path = chart_list[selected_index].path
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_skin_changed(idx: int) -> void:
	if idx >= 0 and idx < skin_list.size():
		GameState.skin_path = skin_list[idx]
		GameState.save_settings()


func _on_scroll_time_slider_changed(value: float) -> void:
	GameState.scroll_time = value
	GameState.save_settings()
	scroll_time_input.text = "%.2f" % value


func _on_scroll_time_input(_text: String = "") -> void:
	var val := scroll_time_input.text.strip_edges().to_float()
	if val > 0:
		GameState.scroll_time = val
		GameState.save_settings()
		scroll_time_slider.set_value_no_signal(val)
	else:
		scroll_time_input.text = "%.2f" % scroll_time_slider.value


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back()
		return

	if event.is_action_pressed("ui_accept"):
		_confirm_selection()
		accept_event()
		return

	if event.is_action_pressed("ui_down"):
		if chart_entries.size() == 0:
			return
		var next_idx := (selected_index + 1) % chart_entries.size()
		select_entry(next_idx)
		accept_event()
		return

	if event.is_action_pressed("ui_up"):
		if chart_entries.size() == 0:
			return
		var prev_idx := selected_index - 1
		if prev_idx < 0:
			prev_idx = chart_entries.size() - 1
		select_entry(prev_idx)
		accept_event()
