class_name HexaType

## 元数据类
class MetaData:
	var title: String
	var title_unicode: String
	var artist: String
	var artist_unicode: String
	var creator: String
	var version: String
	var audio: String
	var preview: int
	
	func _init(data: Dictionary) -> void:
		title = data.get("title", "")
		title_unicode = data.get("title_unicode", "")
		artist = data.get("artist", "")
		artist_unicode = data.get("artist_unicode", "")
		creator = data.get("creator", "")
		version = data.get("version", "")
		audio = data.get("audio", "")
		preview = data.get("preview", -1)

## 时间点（BPM变化）
class TimingPoint:
	var time: float  # 秒
	var bpm: float
	
	func _init(data: Dictionary) -> void:
		# JSON中的时间是毫秒，转换为秒
		time = data.get("time", 0.0) / 1000.0
		bpm = data.get("bpm", 120.0)

## 变速效果
class Effect:
	var time: float  # 秒
	var speed: float
	
	func _init(data: Dictionary) -> void:
		# JSON中的时间是毫秒，转换为秒
		time = data.get("time", 0.0) / 1000.0
		speed = data.get("speed", 1.0)

# 音符数据
class NoteData:
	var time: float        # 秒（目标判定时间）
	var end_time: float    # 秒（长键结束时间，-1表示单键）
	var column: int        # 轨道编号（0-based）
	var is_hold: bool      # 是否为长键
	
	func _init(data: Dictionary) -> void:
		time = data.get("time", 0.0) / 1000.0
		column = data.get("column", 0)
		
		var end = data.get("end_time")
		if end == null or end <= time:
			end_time = -1.0
			is_hold = false
		else:
			end_time = end / 1000.0
			is_hold = true
	
	func is_hold_note() -> bool:
		return is_hold and end_time > time

# 谱面主类
class ChartData:
	var meta: MetaData
	var timing_points: Array[TimingPoint]
	var effects: Array[Effect]
	var notes: Array[NoteData]
	
	func _init(data: Dictionary) -> void:
		meta = MetaData.new(data.get("meta", {}))
		
		# 解析时间点
		timing_points = []
		for tp in data.get("timing_points", []):
			timing_points.append(TimingPoint.new(tp))
		
		# 解析特效（暂时为空）
		for ef in data.get("effects", []):
			effects.append(Effect.new(ef))
		
		# 解析音符
		notes = []
		for note in data.get("notes", []):
			notes.append(NoteData.new(note))
		
		# 按时间排序
		timing_points.sort_custom(func(a: TimingPoint, b: TimingPoint): return a.time < b.time)
		effects.sort_custom(func(a: Effect, b: Effect): return a.time < b.time)
		notes.sort_custom(func(a: NoteData, b: NoteData): return a.time < b.time)
	
	## 获取音乐路径
	func get_audio_filename() -> String:
		return meta.audio if not meta.audio.is_empty() else ""
	
	func get_audio_offset() -> float:
		return timing_points[0].time
