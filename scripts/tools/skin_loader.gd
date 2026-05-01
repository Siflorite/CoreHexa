class_name SkinLoader

static func load_skin(skin_json_path: String) -> ModuleType.HexaSkin:
	var file := FileAccess.open(skin_json_path, FileAccess.READ)
	if not file:
		push_error("无法打开皮肤文件: ", skin_json_path)
		return null
	
	var json_string := file.get_as_text()
	file.close()
	var json := JSON.new()
	var error := json.parse(json_string)
	
	if error != OK:
		push_error("JSON 解析失败: ", json.get_error_message())
		return null
	
	var skin := ModuleType.HexaSkin.new(json.data, skin_json_path)
	print("成功加载皮肤: ", skin.name)
	return skin
