class_name LongNote
extends Note

var end_time: float = 0.0
var body_target_size: Vector2 = Vector2(120, 40):
	set(value):
		body_target_size = value
		if is_node_ready():
			_update_body_texture_scale()
			_update_tail_texture_position()

var tail_target_size: Vector2 = Vector2(120, 120):
	set(value):
		tail_target_size = value
		if is_node_ready():
			_update_tail_texture_scale()

func set_ln_texture(body_texture: Texture2D, tail_texture: Texture2D) -> void:
	$NoteBody.set_texture(body_texture)
	$NoteTail.set_texture(tail_texture)
	_update_body_texture_scale()
	if tail_texture == null:
		tail_target_size.y = 0
	else:
		_update_tail_texture_scale()
		_update_tail_texture_position()
	
func set_render_priority(head_z: int, body_z: int, tail_z: int) -> void:
	z_index = head_z
	$NoteBody.z_index = body_z
	$NoteTail.z_index = tail_z

func _update_body_texture_scale() -> void:
	if $NoteBody.texture:
		$NoteBody.scale = body_target_size / $NoteBody.texture.get_size()

func _update_tail_texture_scale() -> void:
	if $NoteTail.texture:
		$NoteTail.scale = tail_target_size / $NoteTail.texture.get_size()

func _update_tail_texture_position() -> void:
	$NoteTail.position.y = - body_target_size.y # 尾部位置为中段长度-尾端长度
		
## 设置长键Body与Tail的锚点
func _set_ln_sprite_anchor() -> void:
	# NoteBody和NoteTail都是相对NoteHead作为基础零点
	if $NoteBody.texture:
		$NoteBody.offset.y = - $NoteBody.texture.get_size().y * 0.5
	if $NoteTail.texture:
		$NoteTail.offset.y = - $NoteTail.texture.get_size().y * 0.5

func _ready() -> void:
	super._ready()
	_set_ln_sprite_anchor()
	pass
	
func _process(delta: float) -> void:
	super._process(delta)
