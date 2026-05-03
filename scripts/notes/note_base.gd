class_name NoteBase
extends Node2D

## 所在轨道编号，范围[0,5]
var column: int = 0
## 物件判定时间，单位为ms
var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# var velocity: float = viewport_height / scroll_time
	# position.y += velocity * delta
	pass
