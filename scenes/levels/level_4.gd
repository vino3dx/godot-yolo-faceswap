extends Control

signal animation_finished
signal level_completed

@onready var gift_items: Array = $GiftPanel.get_children()

const REQUIRED_IDS := [1, 3, 4] # 正确选中的物品ID

func _ready() -> void:
	await $UIAnimator.play_in_all()
	emit_signal("animation_finished")

func _on_btn_confirm_pressed() -> void:
	var selected_ids: Array[int] = []

	for item in $GiftPanel.get_children():
		if item.has_method("is_selected") and item.is_selected():
			selected_ids.append(item.get_data())

	print("选中的编号：", selected_ids)

	if _check_correct(selected_ids):
		emit_signal("level_completed")
	else:
		print("❌ 不对，必须同时选中 1、3、5")
		_show_error_feedback()

func _check_correct(selected_ids: Array) -> bool:
	for required_id in REQUIRED_IDS:
		if required_id not in selected_ids:
			return false
	return true

func _show_error_feedback() -> void:
	# 可以在这里做个简单的提示，比如按钮抖动或label变红
	print("❌ 至少需要选择前两项")
	AudioManager.play_error()
