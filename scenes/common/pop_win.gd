extends Control

signal next_level_requested
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	AudioManager.play_pass_level()
	animated_sprite_2d.play("default")

func _on_button_pressed() -> void:
	emit_signal("next_level_requested")
