extends Control

@onready var label: Label = $Label  # 改成你实际的Label节点名

func set_tip_text(text: String) -> void:
	label.text = text

func _on_confirm_btn_pressed() -> void:
	queue_free()
