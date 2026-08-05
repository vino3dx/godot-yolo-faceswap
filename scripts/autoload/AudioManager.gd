extends Node

var sfx_click: AudioStream = preload("res://assets/audio/确认键，返回键.mp3")
var sfx_error: AudioStream = preload("res://assets/audio/错误音效.mp3")
var sfx_success: AudioStream = preload("res://assets/audio/成功音效.mp3")
var sfx_checkbox_on: AudioStream = preload("res://assets/audio/打勾.mp3")
var sfx_checkbox_off: AudioStream = preload("res://assets/audio/打勾.mp3")
var sfx_pass_level: AudioStream = preload("res://assets/audio/打锣通关2(1).mp3")

var ui_volume_db: float = 0.0 ## 音量控制

# 通用播放函数（核心）
func _play(stream: AudioStream, volume_db: float = ui_volume_db):
	if stream == null:
		return

	var player := AudioStreamPlayer.new()
	add_child(player)

	player.stream = stream
	player.volume_db = volume_db
	player.play()

	player.finished.connect(func():
		player.queue_free()
	)


# 点击音效
func play_click():
	_play(sfx_click)

# 复选框勾选
func play_checkbox_on():
	_play(sfx_checkbox_on)

# 复选框取消
func play_checkbox_off():
	_play(sfx_checkbox_off)

# 错误音效
func play_error():
	_play(sfx_error)

# 成功音效
func play_success():
	_play(sfx_success)

# 过关
func play_pass_level():
	_play(sfx_pass_level)
