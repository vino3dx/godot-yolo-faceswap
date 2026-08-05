extends Control

signal back_home ## 返回首页
signal previous_level ## 上一关
signal level_completed ## 关卡完成

@onready var btn_lv2_girl: AnimationButton = $BtnLv2Girl
@onready var btn_lv2_boy: AnimationButton = $BtnLv2Boy
@onready var btn_lv2_both: AnimationButton = $BtnLv2Both


func _ready() -> void:
	btn_lv2_boy.pressed.connect(_on_btn_boy_pressed)
	btn_lv2_girl.pressed.connect(_on_btn_girl_pressed)
	btn_lv2_both.pressed.connect(_on_btn_both_pressed)


# 按钮上一步
func _on_btn_previous_pressed() -> void:
	emit_signal("previous_level")


# 按钮返回主页
func _on_btn_back_home_pressed() -> void:
	emit_signal("back_home")


# 男生换装
func _on_btn_boy_pressed() -> void:
	GameState.gender = "male"
	emit_signal("level_completed")


# 女生换装
func _on_btn_girl_pressed() -> void:
	GameState.gender = "female"
	emit_signal("level_completed")


# 双人换装
func _on_btn_both_pressed() -> void:
	GameState.gender = "both"
	emit_signal("level_completed")
