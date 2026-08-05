extends Control

signal level_completed


func _on_btn_next_pressed() -> void:
	emit_signal("level_completed")
