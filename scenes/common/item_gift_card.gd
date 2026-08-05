@tool
extends Control

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label
@onready var check: CheckBox = $CheckBox

# 使用 set(value) 访问器，确保你在编辑器面板修改时，界面瞬间刷新
@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if icon: icon.texture = icon_texture

@export var text: String = "":
	set(value):
		text = value
		if label: label.text = text

@export var checked: bool = false:
	set(value):
		checked = value
		if check: check.button_pressed = checked

func _ready():
	_apply() # 初始化应用一次，确保运行时数据同步

func _apply():
	icon.texture = icon_texture
	label.text = text
	check.button_pressed = checked


func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		AudioManager.play_checkbox_on()
	else:
		AudioManager.play_checkbox_off()
