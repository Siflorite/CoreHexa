class_name Note
extends Sprite2D

var column: int = 0
var time: float = 0.0
@export var scroll_time: float = 0.5
@export var target_size: Vector2 = Vector2(120, 40):
	set(value):
		target_size = value
		if is_node_ready():
			_update_texture_scale()
var viewport_height: float = 0.0

## 设置锚点，锚点位置为底部中心
func _set_sprite_anchor() -> void:
	if texture:
		offset.y = - texture.get_size().y * 0.5

## 将Sprite2D材质尺寸设置为目标尺寸
func _update_texture_scale() -> void:
	if texture:
		scale = target_size / texture.get_size()

## 窗口高度变化时更新内部变量，保证物件位置和下落速度相对窗口高度比例不变
func _update_height() -> void:
	var new_viewport_height: float = get_viewport_rect().size.y
	if viewport_height > 0.0:
		position.y *= new_viewport_height / viewport_height
	viewport_height = new_viewport_height

func _ready() -> void:
	_update_height()
	get_viewport().size_changed.connect(_update_height)
	_set_sprite_anchor()
	_update_texture_scale()
	
func _process(delta: float) -> void:
	var velocity: float = viewport_height / scroll_time
	position.y += velocity * delta
	if position.y > viewport_height + 2 * target_size.y:
		queue_free()
