extends Control

signal back_home
signal previous_level
signal level_completed

@onready var img_boy: TextureRect = $Boy
@onready var img_girl: TextureRect = $Girl
@onready var img_both: TextureRect = $Both


func _ready() -> void:
	img_boy.visible = GameState.gender == "male"
	img_girl.visible = GameState.gender == "female"
	img_both.visible = GameState.gender == "both"


func _on_btn_back_pressed() -> void:
	emit_signal("previous_level")


func _on_btn_take_photo_pressed() -> void:
	emit_signal("level_completed")


func _on_btn_to_home_pressed() -> void:
	emit_signal("back_home")
