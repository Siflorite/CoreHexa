class_name NoteBase
extends Node2D

## 所在轨道编号，范围[0,5]
var column: int = 0
## 物件判定时间，单位为ms
var time: float = 0.0
## 物件从屏幕顶端到判定线时间，单位为ms
@export var scroll_time: float = 0.5
## 视口高度
var viewport_height: float = 0.0

## 窗口高度变化时更新内部变量，保证物件位置和下落速度相对窗口高度比例不变
func _update_height() -> void:
	var new_viewport_height: float = get_viewport_rect().size.y
	if viewport_height > 0.0:
		position.y *= new_viewport_height / viewport_height
	viewport_height = new_viewport_height

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_update_height()
	get_viewport().size_changed.connect(_update_height)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var velocity: float = viewport_height / scroll_time
	position.y += velocity * delta
