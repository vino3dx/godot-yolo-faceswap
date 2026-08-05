extends Control

signal animation_finished
signal level_completed

@onready var label: Label = $Icon3/Label
@onready var checkboxes = [
	$GiftPanel/HBoxContainer/GiftCard1/CheckBox,
	$GiftPanel/HBoxContainer/GiftCard2/CheckBox,
	$GiftPanel/HBoxContainer/GiftCard3/CheckBox,
	$GiftPanel/HBoxContainer/GiftCard4/CheckBox,
	$GiftPanel/HBoxContainer/GiftCard5/CheckBox
]

func _ready() -> void:
	# 1. UI入场动画
	await $UIAnimator.play_in_all()
	
	# 2. 文字打字机效果
	label.visible_ratio = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(label, "visible_ratio", 1.0, 1.0)
	
	# 3. 等待文字跑完再发信号（触发pop_tips）
	await get_tree().create_timer(1.5).timeout
	emit_signal("animation_finished")

func _on_btn_confirm_pressed() -> void:
	# 必须同时勾选第1和第2项才算过关
	if checkboxes[0].button_pressed and checkboxes[1].button_pressed:
		emit_signal("level_completed")
	else:
		_show_error_feedback()

func _show_error_feedback() -> void:
	# 可以在这里做个简单的提示，比如按钮抖动或label变红
	print("❌ 至少需要选择前两项")
	AudioManager.play_error()
