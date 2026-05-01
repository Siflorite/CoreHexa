class_name ModuleType

## 所有模块的基类
class Module:
	var x: float = 0.0
	var y: float = 0.0
	var width: float = 0.0
	var height: float = 0.0
	var alpha: float = 1.0
	var z_index: int = 0
	## 原文件地址，用于将相对路径解析到绝对路径
	var _base_path: String = ""

	func _init(data: Dictionary, base_path: String) -> void:
		x = data.get("x", 0.0)
		y = data.get("y", 0.0)
		width = data.get("width", 0.0)
		height = data.get("height", 0.0)
		alpha = data.get("alpha", 1.0)
		z_index = data.get("z_index", 0)
		_base_path = base_path

	# 辅助方法：解析路径（支持相对路径）
	func resolve_path(path: String) -> String:
		if path.is_empty():
			return ""
		
		# 已经是绝对路径
		if path.begins_with("res://") or path.begins_with("user://"):
			return path
		
		# 相对路径：相对于 JSON 文件所在目录
		if _base_path != "":
			var base_dir: String = _base_path.get_base_dir()
			return base_dir.path_join(path)
		
		# 没有 JSON 路径信息，尝试作为项目路径
		return "res://" + path.trim_prefix("./")

	# 安全加载资源
	func load_resource(path: String) -> Resource:
		var absolute_path: String = resolve_path(path)
		if ResourceLoader.exists(absolute_path):
			return load(absolute_path)
		
		push_warning("资源不存在: ", absolute_path, " (原始路径: ", path, ")")
		return null

# -------- 基础模块 --------

## 图片模块
class ImageModule extends Module:
	var texture: Texture2D = null
	var stretch_mode: TextureRect.StretchMode = TextureRect.STRETCH_SCALE
	
	func _init(data: Dictionary, base_path: String) -> void:
		super._init(data, base_path)
		var texture_path: String = data.get("texture", "")
		if texture_path.is_empty():
			return
		var resource: Resource = load_resource(texture_path)
		if resource != null and resource is Texture2D:
			texture = resource
		else:
			push_warning("图片组件材质 ", texture_path, " 无法加载")
	
	func generate() -> TextureRect:
		if self.texture != null:
			var rect := TextureRect.new()
			rect.texture = self.texture
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = stretch_mode
			rect.position = Vector2(self.x, self.y)
			rect.size = Vector2(self.width, self.height)
			rect.modulate.a = self.alpha
			rect.z_index = self.z_index
			return rect
		else:
			return null

## 矩形模块
class RectModule extends Module:
	var color: Color

	func _init(data: Dictionary, base_path: String) -> void:
		super._init(data, base_path)
		var color_str: String = data.get("color", "")
		color = Color.from_string(color_str, Color.BLACK)
	
	func generate() -> ColorRect:
		var rect := ColorRect.new()
		rect.color = self.color
		rect.position = Vector2(self.x, self.y)
		rect.size = Vector2(self.width, self.height)
		rect.modulate.a = self.alpha
		rect.z_index = self.z_index
		return rect

# -------- 内置模块 --------

## 背景
class BackgroundModule extends ImageModule:
	func _init(data: Dictionary, base_path: String) -> void:
		super._init(data, base_path)
		if not data.has("z_index"):
			z_index = -1 # 背景z_index默认值为-1
		if not data.has("stretch"):
			stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

## 轨道
class ColumnModule extends ImageModule:
	var index: int
	var single: ImageModule = null
	var long_head: ImageModule = null
	var long_body: ImageModule = null
	var long_tail: ImageModule = null

	func _init(data: Dictionary, base_path: String) -> void:
		super._init(data, base_path)
		index = data.get("index", 0)
		var single_data: Dictionary = data.get("single", {})
		single = ImageModule.new(single_data, base_path)
		var head_data: Dictionary = data.get("long_head", {})
		long_head = ImageModule.new(head_data, base_path)
		var body_data: Dictionary = data.get("long_body", {})
		long_body = ImageModule.new(body_data, base_path)
		var tail_data: Dictionary = data.get("long_tail", {})
		long_tail = ImageModule.new(tail_data, base_path)

## 皮肤资源
class HexaSkin:
	var name: String
	var author: String
	var version: String
	var background: ImageModule
	var columns: Array[ColumnModule]
	var customs: Array[Module]

	func _init(data: Dictionary, json_path: String) -> void:
		name = data.get("name", "")
		author = data.get("author", "")
		version = data.get("version", "")
		background = BackgroundModule.new(data.get("background", {}), json_path)
		columns = []
		var column_set: Dictionary = {} # 好家伙，也跟Golang一样用字典做集合呗
		customs = []

		for col in data.get("columns", []):
			var column := ColumnModule.new(col, json_path)
			if column.index >= 0 and column.index <= 5 and not column_set.has(column.index):
				column_set[column.index] = null
				columns.append(ColumnModule.new(col, json_path))
		columns.sort_custom(func(a, b): return a.index < b.index)

		for custom_data in data.get("customs", []):
			var module: Module = null
			var type: String = custom_data.get("type", "")
			# 赞美模式匹配
			match type:
				"image":
					module = ImageModule.new(custom_data, json_path)
				"rect":
					module = RectModule.new(custom_data, json_path)
				_:
					push_warning("模块 ", type, " 未定义")
					continue
			if module != null:
				customs.append(module)
