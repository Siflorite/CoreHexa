extends Node2D

@export var chart_path: String = "res://charts/godish/godish.json"
var audio_path: String = ""

var chart_data: HexaType.ChartData = null
var audio_player: AudioStreamPlayer = null
@export var scroll_time: float = 0.5
const RENDER_ADVANCE_TIME: float = 0.5
var offset: float = 0.0
## 视口高度
var viewport_size: Vector2 = Vector2(0, 0)

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

@export var column_head_textures: Array[Texture2D] = [
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note2.png"),
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note2.png"),
	preload("res://textures/hit_objects/note1.png"),
]
@export var column_body_textures: Array[Texture2D] = [
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note2.png"),
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note2.png"),
	preload("res://textures/hit_objects/note1.png"),
]
@export var column_tail_textures: Array[Texture2D] = [
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note2.png"),
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note2.png"),
	preload("res://textures/hit_objects/note1.png"),
]
var test_texture: Texture2D = preload("res://icons/team_monokhrom_v1.png")

## 窗口高度变化时更新内部变量，保证物件位置和下落速度相对窗口高度比例不变
func _update_size() -> void:
	viewport_size = get_viewport_rect().size

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
	add_child(label)
	time_label = Label.new()
	time_label.position = Vector2(20, 120)
	time_label.add_theme_font_size_override("font_size", 24)
	add_child(time_label)

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
		long_note.set_ln_texture(column_head_textures[note_data.column], test_texture)
		long_note.column = note_data.column
		long_note.time = note_data.time
		long_note.end_time = note_data.end_time
		long_note.scroll_time = scroll_time
		long_note.set_render_priority(2, 1, 0)
	else:
		# 生成Note的实例
		note = note_scene.instantiate()
		note.column = note_data.column
		note.time = note_data.time
		note.scroll_time = scroll_time
	note.set_head_texture(column_head_textures[note.column])
	return note

## 生成新物件
## Input: 音频时间；生成从上一次结束位置开始，到物件时间为音频时间+下落时间+缓冲时间这一范围内所有的物件
func generate_new_notes(audio_time: float) -> void:
	for i in range(index, chart_data.notes.size()):
		var note_data: HexaType.NoteData = chart_data.notes[i]
		if note_data.time < audio_time + scroll_time + RENDER_ADVANCE_TIME:
			var note: Note = generate_note(note_data)
			# 确定Note的初始位置
			var x_pos: float = (0.5 + note_data.column) / 6.0 * viewport_size.x
			# 计算Y位置，需要根据变速计算出视觉位置，不过这里就先随便弄弄
			var y_pos: float = (audio_time - note_data.time + scroll_time) / scroll_time * viewport_size.y
			note.position = Vector2(x_pos, y_pos)
			add_child(note)
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
			var target_y: float = (audio_time - note.time + scroll_time) / scroll_time * viewport_size.y
			note.position.y = target_y
			still_existing_notes.append(note)
	existing_notes = still_existing_notes

func _ready() -> void:
	_update_size()
	get_viewport().size_changed.connect(_update_size)
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
