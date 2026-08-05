extends Control

signal animation_finished
signal level_completed

@onready var btn_1: AnimationButton = $BtnSelection1
@onready var btn_2: AnimationButton = $BtnSelection2
@onready var current_ui: TextureRect = $CurrentStep
@onready var label: Label = $提示框/Label
@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	btn_1.hide()
	btn_2.hide()
	await $UIAnimator.play_in_all()
	emit_signal("animation_finished")


func _on_btn_bride_toggled(toggled_on: bool) -> void:
	if toggled_on:
		btn_1.show()
		btn_2.show()
		current_ui.current_step = current_ui.Step.STEP2
		label.text = "选择正确的祝福语\n送上祝福吧!"
	else:
		btn_1.hide()
		btn_2.hide()
		current_ui.current_step = current_ui.Step.STEP1
		label.text = "点击新娘\n让她踩上斗吧!"


func _on_btn_selection_1_pressed() -> void:
	current_ui.current_step = current_ui.Step.STEP3
	video_player.play()
	await video_player.finished
	emit_signal("level_completed")


func _on_btn_selection_2_pressed() -> void:
	label.text = "这种祝福在这里不合适哦，送上其他祝福吧!"
	await get_tree().create_timer(2.0).timeout
	label.text = "选择正确的祝福语\n送上祝福吧!"
