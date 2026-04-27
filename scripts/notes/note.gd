class_name Note
extends NoteBase

var head_target_size: Vector2 = Vector2(120, 40):
	set(value):
		head_target_size = value
		if is_node_ready():
			_update_head_texture_scale()
			
func set_head_texture(head_texture: Texture2D) -> void:
	$NoteHead.texture = head_texture
	_update_head_texture_scale()

## 设置锚点，锚点位置为底部中心
func _set_sprite_anchor() -> void:
	if $NoteHead.texture:
		$NoteHead.offset.y = - $NoteHead.texture.get_size().y * 0.5

## 将Sprite2D材质尺寸设置为目标尺寸
func _update_head_texture_scale() -> void:
	if $NoteHead.texture:
		$NoteHead.scale = head_target_size / $NoteHead.texture.get_size()

func _ready() -> void:
	super._ready()
	_set_sprite_anchor()
	_update_head_texture_scale()
	
func _process(delta: float) -> void:
	super._process(delta)
