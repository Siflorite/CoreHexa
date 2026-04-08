class_name LongNote
extends Note

var end_time: float = 0.0

func _ready() -> void:
	super._ready()
	var render_height = (end_time - time) / scroll_time * viewport_height
	target_size.y = render_height
	pass
	
func _process(delta: float) -> void:
	var velocity: float = viewport_height / scroll_time
	position.y += velocity * delta
	if position.y > viewport_height + target_size.y + 200:
		queue_free()
