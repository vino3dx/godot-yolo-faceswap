@tool
extends VBoxContainer

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

@export var card_id: int = 0  # 编辑器里给每张卡片编号，比如礁卡片1~5

@onready var icon: TextureRect = $Icon
@onready var label: Label = $HBoxContainer/Label
@onready var check: CheckBox = $HBoxContainer/CheckBox

func _ready():
	_apply()

func _apply():
	icon.texture = icon_texture
	label.text = text
	check.button_pressed = checked

func _on_check_box_toggled(toggled_on: bool) -> void:
	checked = toggled_on
	if toggled_on:
		AudioManager.play_checkbox_on()
	else:
		AudioManager.play_checkbox_off()

func is_selected() -> bool:
	return check.button_pressed if check else checked

func get_data() -> Variant:
	return card_id
