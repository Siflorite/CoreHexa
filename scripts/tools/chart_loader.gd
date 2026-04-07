class_name ChartLoader

static func load_chart(path: String) -> HexaType.ChartData:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("无法打开谱面文件: " + path)
		return null
	
	var json_text := file.get_as_text()
	file.close()
	return parse(json_text)

static func parse(json_text: String) -> HexaType.ChartData:
	var json := JSON.new()
	var error := json.parse(json_text)
	
	if error != OK:
		push_error("JSON解析错误: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		return null
	
	if not json.data is Dictionary:
		push_error("谱面根节点必须是对象")
		return null
	
	return HexaType.ChartData.new(json.data)
