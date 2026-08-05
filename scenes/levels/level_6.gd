extends Control

signal animation_finished
signal level_completed

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var selection_1: TextureRect = $Selection1
@onready var selection_2: TextureRect = $Selection2

const NEWLYWED_VIDEO = "res://assets/video/坐床帮新郎动画.mp4"
const BRIDE_VIDEO    = "res://assets/video/坐床帮新娘动画.mp4"


func _ready() -> void:
	selection_1.hide()
	selection_2.hide()
	await $UIAnimator.play_in_all()
	emit_signal("animation_finished")

func _play_video(path: String) -> void:
	texture_rect.hide()
	label.hide()
	
	var stream := FFmpegVideoStream.new()
	stream.file = path
	video_player.stream = stream
	video_player.play()
	
func _on_texture_button_pressed() -> void:
	texture_rect.hide()
	label.hide()
	_play_video(NEWLYWED_VIDEO)
	
	await video_player.finished
	
	await fade_in(selection_1)
	
	await get_tree().create_timer(2.0).timeout
	emit_signal("level_completed")


func _on_texture_button_2_pressed() -> void:
	texture_rect.hide()
	label.hide()
	_play_video(BRIDE_VIDEO)
	
	await video_player.finished
	
	await fade_in(selection_2)
	
	await get_tree().create_timer(2.0).timeout
	emit_signal("level_completed")


# 渐显函数
func fade_in(node: CanvasItem, duration: float = 0.5) ->void:
	node.modulate.a = 0.0
	node.show()
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	
	await tween.finished
