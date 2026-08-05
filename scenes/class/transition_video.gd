extends Control

signal finished

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

# null 表示该关卡没有过场视频，直接跳过
const LEVEL_VIDEOS := [
	"res://assets/video/媒人提亲动画.mp4",   # 第1关 → 第2关
	"res://assets/video/合八字结算动画.mp4",  # 第2关 → 第3关
	"res://assets/video/哭嫁动画.mp4",       # 第3关 → 第4关
	"res://assets/video/过礼成功动画.mp4",    # 第4关 → 第5关
	"res://assets/video/踩斗动画2.mp4",      # 第5关 → 第6关
	null,                                  # 第6关 → 第7关（无过场）
	"res://assets/video/回门动画.mp4",       # 第7关 → 结束界面
]

const START_VIDEO := "res://assets/video/待机动画.mp4"

const VIDEO_PLAYBACK_SPEED := 1.2 ## 配置全局视频播放倍速，可根据需求随时调整数字

func _ready() -> void:
	visible = false
	video_player.finished.connect(_on_video_finished)

# 待机 → 第1关
func play_start() -> void:
	await _play_file(START_VIDEO)

# 关卡过场
func play_level_transition(level_index: int) -> void:
	# index 越界
	if level_index < 0 or level_index >= LEVEL_VIDEOS.size():
		return

	var video_path = LEVEL_VIDEOS[level_index]

	# 没有视频直接跳过
	if video_path == null or video_path == "":
		return

	await _play_file(video_path)


# 播放视频文件
func _play_file(path: String) -> void:
	visible = true
	
	# 新增：启动视频前，将引擎全局时间流速调整为配置的倍速
	Engine.time_scale = VIDEO_PLAYBACK_SPEED
	
	var stream := FFmpegVideoStream.new()
	stream.file = path
	video_player.stream = stream
	video_player.play()
	await finished
#func _play_file(path: String) -> void:
	#visible = true
	#var stream := FFmpegVideoStream.new()
	#stream.file = path
	#video_player.stream = stream
	#video_player.play()
	#await finished


# 视频播放完后
func _on_video_finished() -> void:
	video_player.stop()
	video_player.stream = null
	visible = false
	
	# 新增：视频播放完毕后，必须将引擎时间流速还原为 1.0，恢复正常游戏速度
	Engine.time_scale = 1.0
	
	finished.emit()
#func _on_video_finished() -> void:
	#video_player.stop()
	#video_player.stream = null
	#visible = false
	#finished.emit()
