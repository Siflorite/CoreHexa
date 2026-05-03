extends Node2D

@export var chart_path: String = "res://charts/godish/godish.json"
@export var skin_path: String = "res://skins/default/skin.json"
var audio_path: String = ""
var background_path: String = ""

var chart_data: HexaType.ChartData = null
var skin_data: ModuleType.HexaSkin = null
var background: Texture2D = null
var audio_player: AudioStreamPlayer = null
@export var scroll_time: float = 0.5
const RENDER_ADVANCE_TIME: float = 0.5
var offset: float = 0.0
## 视口相关
const DESIGN_WIDTH: float = 1920
const DESIGN_HEIGHT: float = 1080
var viewport_size: Vector2 = Vector2(0, 0)
var keep_size_nodes: Array[Node] = []

var existing_notes: Array[Note] = []
var index: int = 0
var note_scene: Resource = preload("res://scenes/notes/note.tscn")
var long_note_scene: Resource = preload("res://scenes/notes/long_note.tscn")

var current_time: float = 0.0
const START_DELAY: float = 3.0
var visual_time: float = -START_DELAY
const SMOOTH_FACTOR: float = 0.2 # 将渲染时间平滑到音频时间的参数，越低就越平滑，但平滑速度慢

var time_label: Label = null

var output_latency: float = 0.0

var column_pos: Array[Vector2] = []

var single_head_textures: Array[Texture2D] = []
var ln_head_textures: Array[Texture2D] = []
var ln_body_textures: Array[Texture2D] = []
var ln_tail_textures: Array[Texture2D] = []

var single_sizes: Array[Vector2] = []
var single_z_indexes: Array[int] = []

var ln_head_sizes: Array[Vector2] = []
var ln_head_z_indexes: Array[int] = []

var ln_body_sizes: Array[Vector2] = []
var ln_body_z_indexes: Array[int] = []

var ln_tail_sizes: Array[Vector2] = []
var ln_tail_z_indexes: Array[int] = []

## 窗口高度变化时更新内部变量，保证物件位置和下落速度相对窗口高度比例不变
func _update_size() -> void:
	viewport_size = get_viewport_rect().size
	var target_scale: Vector2 = viewport_size / Vector2(DESIGN_WIDTH, DESIGN_HEIGHT)
	$GameArea.scale = target_scale
	for node in keep_size_nodes:
		var uniform_scale: float = max(target_scale.x, target_scale.y)
		node.scale = Vector2(uniform_scale, uniform_scale) / target_scale

func load_chart() -> void:
	# 加载谱面文件
	chart_data = ChartLoader.load_chart(chart_path)
	if chart_data == null:
		push_error("谱面加载失败")
		return
	
	# 加载音乐文件
	offset = chart_data.get_audio_offset()
	audio_path = chart_path.get_base_dir().path_join(chart_data.get_audio_filename())
	if FileAccess.file_exists(audio_path):
		var stream := load(audio_path)
		audio_player = AudioStreamPlayer.new()
		audio_player.stream = stream
		add_child(audio_player)
	else:
		push_error("音乐文件不存在: " + audio_path)

	# 加载背景
	background_path = chart_path.get_base_dir().path_join(chart_data.get_background_filename())
	if FileAccess.file_exists(background_path):
		background = load(background_path)


func load_skin() -> void:
	column_pos.resize(6)
	single_head_textures.resize(6)
	single_sizes.resize(6)
	single_z_indexes.resize(6)
	ln_head_textures.resize(6)
	ln_head_sizes.resize(6)
	ln_head_z_indexes.resize(6)
	ln_body_textures.resize(6)
	ln_body_sizes.resize(6)
	ln_body_z_indexes.resize(6)
	ln_tail_textures.resize(6)
	ln_tail_sizes.resize(6)
	ln_tail_z_indexes.resize(6)
	
	skin_data = SkinLoader.load_skin(skin_path)
	if skin_data == null:
		push_error("皮肤加载失败")
		return

	for column in skin_data.columns:
		var idx: int = column.index
		column_pos[idx] = Vector2(column.x, column.y)
		var column_rect := column.generate()
		
		if column_rect != null:
			column_rect.size.y = DESIGN_HEIGHT
			column_rect.position.y -= DESIGN_HEIGHT
			$GameArea.add_child(column_rect)
		else:
			# 使用黑色矩形代替
			var column_bar := ColorRect.new()
			column_bar.color = Color.BLACK
			column_bar.position = Vector2(column.x, column.y - DESIGN_HEIGHT)
			column_bar.size = Vector2(column.width, DESIGN_HEIGHT)
			column_bar.z_index = column.z_index
			$GameArea.add_child(column_bar)

		single_head_textures[idx] = column.single.texture
		single_sizes[idx] = Vector2(column.width, column.single.height)
		single_z_indexes[idx] = column.single.z_index

		ln_head_textures[idx] = column.long_head.texture
		ln_head_sizes[idx] = Vector2(column.width, column.long_head.height)
		ln_head_z_indexes[idx] = column.long_head.z_index

		ln_body_textures[idx] = column.long_body.texture
		var long_body_width: float = column.long_body.width if column.long_body.width > 0 else column.width
		ln_body_sizes[idx] = Vector2(long_body_width, 0)
		ln_body_z_indexes[idx] = column.long_body.z_index

		ln_tail_textures[idx] = column.long_tail.texture
		var long_tail_width: float = column.long_tail.width if column.long_tail.width > 0 else column.width
		ln_tail_sizes[idx] = Vector2(long_tail_width, column.long_tail.height)
		ln_tail_z_indexes[idx] = column.long_tail.z_index

	for module in skin_data.customs:
		if module is ModuleType.ImageModule:
			var image: TextureRect = module.generate()
			if module.stretch_mode != TextureRect.STRETCH_SCALE and image != null:
				keep_size_nodes.append(image)
			$GameArea.add_child(image)
		elif module is ModuleType.RectModule:
			var rect: ColorRect = module.generate()
			$GameArea.add_child(rect)
	pass

func setup_ui() -> void:
	# 显示歌曲信息
	var label := Label.new()
	label.text = "%s - %s [%s]\nMapped by %s" % [
		chart_data.meta.artist_unicode,
		chart_data.meta.title_unicode,
		chart_data.meta.version,
		chart_data.meta.creator
	]
	label.position = Vector2(20, 20)
	label.add_theme_font_size_override("font_size", 24)
	$GameArea.add_child(label)
	keep_size_nodes.append(label)
	time_label = Label.new()
	time_label.position = Vector2(20, 120)
	time_label.add_theme_font_size_override("font_size", 24)
	$GameArea.add_child(time_label)
	keep_size_nodes.append(time_label)

	# 设置背景
	var bg_width: float = skin_data.background.width if skin_data and skin_data.background.width > 0  else DESIGN_WIDTH
	var bg_height: float = skin_data.background.height if skin_data and skin_data.background.height > 0  else DESIGN_HEIGHT

	var background_rect: TextureRect = null
	if skin_data != null:
		skin_data.background.width = bg_width
		skin_data.background.height = bg_height
		if skin_data.background.texture == null and background != null:
			skin_data.background.texture = background
		background_rect = skin_data.background.generate()
	elif background != null:
		background_rect = TextureRect.new()
		background_rect.texture = background
		background_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		background_rect.size = Vector2(bg_width, bg_height)
		background_rect.z_index = -1
	if background_rect != null:
		keep_size_nodes.append(background_rect)
		$GameArea.add_child(background_rect)
	
func setup_input() -> void:
	# 先不设置
	pass
	
func start_game() -> void:
	var start_timer: Timer = Timer.new()
	start_timer.wait_time = START_DELAY
	start_timer.one_shot = true
	start_timer.timeout.connect(_on_start_timer_timeout)
	add_child(start_timer)
	start_timer.start()
	
func _on_start_timer_timeout() -> void:
	if audio_player != null:
		audio_player.play()

## 生成物件场景实例
## Input: 物件数据
## Output: 物件实例
func generate_note(note_data: HexaType.NoteData) -> Note:
	var note: Note = null
	if note_data.is_hold_note():
		# 生成LongNote的实例
		note = long_note_scene.instantiate()
		var long_note := note as LongNote # No data copy, only a reference alias
		var render_height: float = (note_data.end_time - note_data.time) / scroll_time * DESIGN_HEIGHT
		long_note.head_target_size = ln_head_sizes[note_data.column]
		long_note.body_target_size = Vector2(
			ln_body_sizes[note_data.column].x, 
			max(render_height - ln_tail_sizes[note_data.column].y, 0)
		) 
		# 理论上设置body长度时会同时调整tail位置，y坐标到body最上端
		# 但是因为还没加入节点树所以不会更新，太扯淡了，在set_ln_texture里面再调用一次吧
		long_note.tail_target_size = ln_tail_sizes[note_data.column]
		long_note.set_head_texture(ln_head_textures[note_data.column])
		long_note.set_ln_texture(ln_body_textures[note_data.column], ln_tail_textures[note_data.column])
		long_note.set_render_priority(
			ln_head_z_indexes[note_data.column],
			ln_body_z_indexes[note_data.column],
			ln_tail_z_indexes[note_data.column]
		)
		long_note.column = note_data.column
		long_note.time = note_data.time
		long_note.end_time = note_data.end_time
	else:
		# 生成Note的实例
		note = note_scene.instantiate()
		note.set_head_texture(single_head_textures[note_data.column])
		note.head_target_size = single_sizes[note_data.column]
		note.z_index = single_z_indexes[note_data.column]
		note.column = note_data.column
		note.time = note_data.time
	return note

## 生成新物件
## Input: 音频时间；生成从上一次结束位置开始，到物件时间为音频时间+下落时间+缓冲时间这一范围内所有的物件
func generate_new_notes(audio_time: float) -> void:
	for i in range(index, chart_data.notes.size()):
		var note_data: HexaType.NoteData = chart_data.notes[i]
		var delta_y: float = column_pos[note_data.column].y - DESIGN_HEIGHT
		if note_data.time < audio_time + scroll_time + RENDER_ADVANCE_TIME:
			var note: Note = generate_note(note_data)
			# 确定Note的初始位置
			var x_pos: float = column_pos[note_data.column].x + note.head_target_size.x / 2
			# 计算Y位置，需要根据变速计算出视觉位置，不过这里就先随便弄弄
			var y_pos: float = (audio_time - note_data.time + scroll_time) / scroll_time * DESIGN_HEIGHT + delta_y
			note.position = Vector2(x_pos, y_pos)
			$GameArea.add_child(note)
			existing_notes.append(note)	
			# print("idx: ", i, ", col: ", note_data.column, ", time: ", note_data.time, ", endtime: ", note_data.end_time)
		else:
			index = i
			break

## 更新存在物件的位置
## Input: 音频时间；根据音频时间调整当前所有存在物件的Y坐标
func update_existing_notes(audio_time: float) -> void:
	var still_existing_notes: Array[Note] = []
	for note in existing_notes:
		var exist_time: float = 0.0 # 物件留存时间点，对于单键就是time，长键就是end_time
		var judge_y: float = column_pos[note.column].y
		var delta_y: float = judge_y - DESIGN_HEIGHT
		if note is LongNote:
			exist_time = note.end_time
		else:
			exist_time = note.time
			
		if audio_time > exist_time + 2 * scroll_time:
			# 超过临界区域，销毁当前note
			note.queue_free()
			# print("curtime: ", audio_time, ", notetime: ", note.time, ", etime: ", exist_time)
		else:
			# 调整当前note的y坐标
			var target_y: float = (audio_time - note.time + scroll_time) / scroll_time * DESIGN_HEIGHT + delta_y
			note.position.y = target_y
			if note is LongNote:
				if note.time < audio_time and note.end_time > audio_time:
					# 一个特性，在长键头部低于判定区，尾部还没到判定区时，将头部固定在判定位置，未来可能拓展为皮肤控制
					note.set_head_position_y(judge_y - target_y)
			still_existing_notes.append(note)
	existing_notes = still_existing_notes

func _ready() -> void:
	_update_size()
	get_viewport().size_changed.connect(_update_size)
	load_skin()
	load_chart()
	setup_ui()
	setup_input()
	start_game()
	print("Audio Driver: ", AudioServer.get_driver_name())
	print("Audio Sample Rate: ", AudioServer.get_mix_rate())
	print("Audio Device List: ", AudioServer.get_output_device_list())
	print("Audio Device: ", AudioServer.get_output_device())
	output_latency = AudioServer.get_output_latency()
	print("Audio Latency:", output_latency * 1000.0, " ms")
	
func _process(delta: float) -> void:
	current_time += delta
	var audio_time: float = 0.0
	if audio_player != null and audio_player.playing:
		audio_time = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix() - output_latency
	else:
		audio_time = current_time - START_DELAY
	
	visual_time += delta
	var drift: float = audio_time - visual_time
	if abs(drift) > 0.05: # 大于50ms直接跳变
		visual_time = audio_time
	elif abs(drift) > 0.01: # (10,50]ms范围内进行平滑，减少jitter
		visual_time += drift * SMOOTH_FACTOR
		
	update_existing_notes(visual_time)
	generate_new_notes(visual_time)
	time_label.text = "Render: %.2f ms\nTime: %.3f s + %.3f s" % [(delta * 1000.0), audio_time, current_time - audio_time]
