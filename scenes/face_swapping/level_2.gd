extends Control

signal level_completed ## 关卡完成
signal previous_level

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	# 初始隐藏
	video_stream_player.visible = false


func _on_btn_next_pressed() -> void:
	emit_signal("level_completed")


func _on_btn_play_video_pressed() -> void:
	# 1. 显现出视频播放器
	video_stream_player.visible = true
	# 2. 通知播放器真正开始播放（调用刚刚新增的方法）
	if video_stream_player.has_method("start_video"):
		video_stream_player.start_video()


func _on_video_tool_bar_exit_pressed() -> void:
	# 隐藏并彻底停止
	video_stream_player.visible = false
	video_stream_player.stop()


func _on_btn_previous_pressed() -> void:
	emit_signal("previous_level")
