extends Control

signal mode_selected(mode: String)

func _ready() -> void:
	breathe($AnimationButton, 0.1)
	breathe($AnimationButton2, 0.1)
	

func breathe(btn: Control, delay: float = 0.0):
	var tween = create_tween()
	tween.set_loops()
	
	if delay > 0:
		tween.tween_interval(delay)
		
	tween.tween_property(btn, "scale", Vector2(1.08, 1.08), 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func _on_left_pressed():
	print("【模式选择】🙍‍♀️换装")
	mode_selected.emit("face")


func _on_right_pressed():
	print("【模式选择】💌婚嫁")
	mode_selected.emit("wedding")
