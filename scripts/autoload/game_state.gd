extends Node

const SETTINGS_PATH: String = "user://settings.cfg"

var window_mode: int = DisplayServer.WINDOW_MODE_WINDOWED
var resolution: Vector2i = Vector2i(1920, 1080)
var vsync_mode: int = DisplayServer.VSYNC_ENABLED
var target_fps: int = 0
var master_volume: float = 1.0

var chart_path: String = ""
var skin_path: String = ""
var scroll_time: float = 0.5


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(SETTINGS_PATH)
	if err != OK:
		_default_skin()
		return

	window_mode = config.get_value("display", "window_mode", window_mode)
	resolution.x = config.get_value("display", "resolution_x", resolution.x)
	resolution.y = config.get_value("display", "resolution_y", resolution.y)
	vsync_mode = config.get_value("display", "vsync_mode", vsync_mode)
	target_fps = config.get_value("display", "target_fps", target_fps)
	master_volume = config.get_value("audio", "master_volume", master_volume)

	skin_path = config.get_value("game", "skin_path", skin_path)
	scroll_time = config.get_value("game", "scroll_time", scroll_time)
	if skin_path.is_empty() or not FileAccess.file_exists(skin_path):
		_default_skin()


func _default_skin() -> void:
	var candidates := [
		"res://skins/default/skin.json",
		"res://skins/default_bar/skin.json",
		"res://skins/sdvx/skin.json",
	]
	for p in candidates:
		if FileAccess.file_exists(p):
			skin_path = p
			return


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "window_mode", window_mode)
	config.set_value("display", "resolution_x", resolution.x)
	config.set_value("display", "resolution_y", resolution.y)
	config.set_value("display", "vsync_mode", vsync_mode)
	config.set_value("display", "target_fps", target_fps)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("game", "skin_path", skin_path)
	config.set_value("game", "scroll_time", scroll_time)
	config.save(SETTINGS_PATH)


func apply_settings() -> void:
	DisplayServer.window_set_mode(window_mode)
	if window_mode == DisplayServer.WINDOW_MODE_WINDOWED and resolution.x > 0 and resolution.y > 0:
		DisplayServer.window_set_size(resolution)

	DisplayServer.window_set_vsync_mode(vsync_mode)
	Engine.max_fps = target_fps

	var master_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(master_volume))
