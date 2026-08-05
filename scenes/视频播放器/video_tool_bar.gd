extends Control
class_name VideoToolBar

@onready var bar: Control = $Bar
@onready var btn_pause_and_play: Button = $Bar/HBoxContainer/BtnPauseAndPlay
@onready var btn_stop: Button = $Bar/HBoxContainer/BtnStop
@onready var btn_rewind: Button = $Bar/HBoxContainer/BtnRewind
@onready var btn_forward: Button = $Bar/HBoxContainer/BtnForward
@onready var h_slider_playback: HSlider = $Bar/HBoxContainer/HSliderPlayback
@onready var btn_mute: Button = $Bar/HBoxContainer/BtnMute
@onready var h_slider_volume: HSlider = $Bar/HBoxContainer/HSliderVolume
@onready var btn_exit: Button = $Bar/HBoxContainer/BtnExit

# 导出参数
@export var player_path: NodePath
@export var seek_step: float = 10.0
@export var hide_delay: float = 3.0

signal exit_pressed


# 内部变量
var _player: VideoStreamPlayer
var _is_dragging: bool = false
var _is_muted: bool = false
var _volume_before_mute: float = 0.5
var _hide_timer: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_player = _resolve_player()
	_connect_signals()

	h_slider_playback.min_value = 0
	h_slider_playback.max_value = 100
	h_slider_volume.min_value = 0
	h_slider_volume.max_value = 100
	h_slider_volume.value = (_player.volume * 100.0) if _player else 50.0

	bar.visible = false



func _process(delta: float) -> void:
	# 更新进度条
	if _player and _player.is_playing() and not _player.paused and not _is_dragging:
		var length := _player.get_stream_length()
		if length > 0:
			h_slider_playback.value = (_player.stream_position / length) * 100.0

	# 自动隐藏控制条
	if bar.visible:
		_hide_timer += delta
		if _hide_timer >= hide_delay:
			bar.visible = false



func _connect_signals() -> void:
	if _player:
		_player.finished.connect(_on_video_finished)

	h_slider_playback.drag_started.connect(_on_slider_drag_started)
	h_slider_playback.drag_ended.connect(_on_slider_drag_ended)
	h_slider_playback.value_changed.connect(_on_playback_value_changed)

	btn_pause_and_play.pressed.connect(_on_btn_pause_and_play_pressed)
	btn_stop.pressed.connect(_on_btn_stop_pressed)
	btn_rewind.pressed.connect(_on_btn_rewind_pressed)
	btn_forward.pressed.connect(_on_btn_forward_pressed)
	btn_mute.pressed.connect(_on_btn_mute_pressed)
	btn_exit.pressed.connect(_on_btn_exit_pressed)

	h_slider_volume.value_changed.connect(_on_volume_value_changed)

	mouse_entered.connect(_show_controls)
	mouse_exited.connect(_on_mouse_exited)



# 显式绑定播放器节点
func bind(player: VideoStreamPlayer) -> void:
	if _player and _player.finished.is_connected(_on_video_finished):
		_player.finished.disconnect(_on_video_finished)
	_player = player
	if _player:
		_player.finished.connect(_on_video_finished)
		h_slider_volume.value = _player.volume * 100.0



func _resolve_player() -> VideoStreamPlayer:
	if player_path != NodePath(""):
		var n := get_node_or_null(player_path)
		if n is VideoStreamPlayer:
			return n
		push_error("player_path 指向的节点不是 VideoStreamPlayer")
	var parent := get_parent()
	if parent is VideoStreamPlayer:
		return parent
	push_error("未找到 VideoStreamPlayer，请检查节点层级或 player_path")
	return null



func _on_btn_pause_and_play_pressed() -> void:
	if not _player or _player.stream == null:
		return

	if _player.is_playing():
		_player.paused = not _player.paused
	else:
		_player.play()

	_show_controls()



func _on_btn_stop_pressed() -> void:
	if _player and _player.stream != null:
		# 1. 停止播放
		_player.stop()
		
		# 2. 强制重置指针
		_player.stream_position = 0.0
		
		# 3. 显式清除暂停状态
		_player.paused = false
		
		# 4. 【关键步骤】针对 FFmpeg 插件，通过重新赋值 stream 来刷新底层解码上下文
		# 这会强制插件释放并重新初始化解码器实例
		var temp_stream = _player.stream
		_player.stream = null
		_player.stream = temp_stream
		
	h_slider_playback.value = 0
	_show_controls()


func _on_video_finished() -> void:
	h_slider_playback.value = 0
	_show_controls()



func _on_btn_rewind_pressed() -> void:
	_seek_relative(-seek_step)



func _on_btn_forward_pressed() -> void:
	_seek_relative(seek_step)



func _seek_relative(seconds: float) -> void:
	if not _player or _player.stream == null:
		return
	var length := _player.get_stream_length()
	_player.stream_position = clampf(_player.stream_position + seconds, 0.0, length)
	_show_controls()



func _on_playback_value_changed(value: float) -> void:
	if _player and _player.stream != null and _is_dragging:
		var length := _player.get_stream_length()
		if length > 0:
			_player.stream_position = (value / 100.0) * length



func _on_slider_drag_started() -> void:
	_is_dragging = true
	_show_controls()



func _on_slider_drag_ended(_value_changed: bool) -> void:
	_is_dragging = false
	_show_controls()



func _on_volume_value_changed(value: float) -> void:
	if _player:
		_player.volume = value / 100.0

	if _is_muted:
		_is_muted = false

	_show_controls()



func _on_btn_mute_pressed() -> void:
	_is_muted = not _is_muted
	if not _player:
		return

	if _is_muted:
		_volume_before_mute = _player.volume
		_player.volume = 0.0
	else:
		_player.volume = _volume_before_mute
		h_slider_volume.value = _volume_before_mute * 100.0

	_show_controls()



func _on_btn_exit_pressed() -> void:
	exit_pressed.emit()



func _show_controls() -> void:
	_hide_timer = 0.0
	bar.visible = true



func _on_mouse_exited() -> void:
	_hide_timer = 0.0
