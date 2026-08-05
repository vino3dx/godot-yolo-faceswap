extends Control

signal restart_game

@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var texture_rect: TextureRect = $TextureRect
@onready var qr_code: TextureRect = $QrCode
@onready var btn_back_to_home: Button = $Btn_BackToHome

func _ready() -> void:
	texture_rect.modulate.a = 0.0
	qr_code.modulate.a = 0.0
	btn_back_to_home.modulate.a =0.0


func _on_btn_restart_pressed() -> void:
	emit_signal("restart_game")


func _on_video_stream_player_finished() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(video_stream_player, "modulate:a", 0.0, 0.2)
	texture_rect.modulate.a = 1.0
	
	await tween.finished
	
	video_stream_player.hide()
	video_stream_player.modulate.a = 1.0
	
	qr_code.modulate.a = 1.0
	btn_back_to_home.modulate.a = 1.0
