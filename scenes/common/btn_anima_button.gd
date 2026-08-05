class_name AnimationButton
extends Button

@export var hover_scale := 1.08
@export var press_scale := 0.92
@export var anim_time := 0.12

var base_scale := Vector2.ONE


func _ready():
	base_scale = scale

	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_exit)
	button_down.connect(_on_press)
	button_up.connect(_on_release)


func _on_hover():
	create_tween().tween_property(
		self,
		"scale",
		base_scale * hover_scale,
		anim_time
	)


func _on_exit():
	create_tween().tween_property(
		self,
		"scale",
		base_scale,
		anim_time
	)


func _on_press():
	create_tween().tween_property(
		self,
		"scale",
		base_scale * press_scale,
		0.05
	)
	AudioManager.play_click()


func _on_release():
	create_tween().tween_property(
		self,
		"scale",
		base_scale * hover_scale,
		anim_time
	)
