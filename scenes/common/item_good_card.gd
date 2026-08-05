@tool
extends Control
class_name ItemGoodCard

signal item_toggled(item_id: int, selected: bool)

@export var card_id: int = 0

@export var icon_texture: Texture2D:
	set(value):
		icon_texture = value
		if icon: icon.texture = icon_texture

@export var label_text: String = "":
	set(value):
		label_text = value
		if label: label.text = label_text

@onready var icon: TextureRect = $TextureRect
@onready var label: Label = $Label
var check: CheckBox = null

func _ready() -> void:
	check = get_node_or_null("Checkbox")  # ← 改这里
	_apply()
	if check:
		if not check.toggled.is_connected(_on_check_toggled):
			check.toggled.connect(_on_check_toggled)
	else:
		push_warning("❌ CheckBox没找到，请检查节点名字")

func _apply() -> void:
	if icon:
		icon.texture = icon_texture
	if label:
		label.text = label_text

func _on_check_toggled(v: bool) -> void:
	AudioManager.play_checkbox_on()
	item_toggled.emit(card_id, v)

func is_selected() -> bool:
	return check.button_pressed if check else false

func get_data() -> int:
	return card_id
