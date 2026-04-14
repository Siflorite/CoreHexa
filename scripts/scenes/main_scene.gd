extends Node2D

@export var chart_path: String = "res://charts/godish/godish.json"
var audio_path: String = ""

var chart_data: HexaType.ChartData = null
var audio_player: AudioStreamPlayer = null
@export var scroll_time: float = 0.5
var offset: float = 0.0

var all_notes: Array[Note] = []
var existing_notes: Array[Note] = []
var note_scene: Resource = preload("res://scenes/notes/note.tscn")
var long_note_scene: Resource = preload("res://scenes/notes/long_note.tscn")

var current_time: float = 0.0
const START_DELAY: float = 2.0

var time_label: Label = null

@export var column_textures: Array[Texture2D] = [
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note2.png"),
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note1.png"),
	preload("res://textures/hit_objects/note2.png"),
	preload("res://textures/hit_objects/note1.png"),
]
var test_texture: Texture2D = preload("res://icons/team_monokhrom_v1.png")

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

func spawn_notes() -> void:
	for note_data in chart_data.notes:
		var note: Note = null
		if note_data.is_hold_note():
			# 生成LongNote的实例
			note = long_note_scene.instantiate()
			var long_note := note as LongNote # No data copy, only a reference alias
			long_note.set_ln_texture(column_textures[note_data.column], test_texture)
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
		note.set_head_texture(column_textures[note.column])
		
		# 确定Note的初始位置
		var x_pos: float = (0.5 + note.column) / 6.0 * get_viewport_rect().size.x
		# 计算Y位置，需要根据变速计算出视觉位置，不过这里就先随便弄弄
		var y_pos: float = (scroll_time - START_DELAY - note.time) / scroll_time * get_viewport_rect().size.y
		note.position = Vector2(x_pos, y_pos)
		add_child(note)
		all_notes.append(note)

func _ready() -> void:
	load_chart()
	setup_ui()
	setup_input()
	spawn_notes()
	start_game()
	print("Audio Driver: ", AudioServer.get_driver_name())
	print("Audio Sample Rate: ", AudioServer.get_mix_rate())
	print("Audio Device List: ", AudioServer.get_output_device_list())
	print("Audio Device: ", AudioServer.get_output_device())
	print("Audio Latency:", AudioServer.get_output_latency() * 1000.0, " ms")
	
func _process(delta: float) -> void:
	time_label.text = "%.2f ms" % (delta * 1000.0)
	current_time += delta
