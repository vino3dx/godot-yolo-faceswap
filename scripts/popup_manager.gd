extends Node

@export var tips_scene: PackedScene
@export var win_scene: PackedScene

@onready var popup_layer: Control = $"../UILayer/Popups"

var current_popup: Control = null

# 每关对应的提示文字
const TIPS_TEXT: Array[String] = [
	"提亲要带猪肘、面条等礼物，表示诚意和祝福。",
	"合八字是看两人是否相配，只有相合才能订婚。",
	"哭嫁是土家族特有的习俗，新娘要哭唱感谢亲人，表达不舍。",
	"过礼是男方在婚礼前送到女方家的彩礼，要敬献给祖先。",
	"新娘踩斗，祝福娘家年年五谷丰登，把富贵留下。",
	"土家族婚礼中，谁先坐到床上，将来就由谁当家，非常有趣！",
	"婚后第三天新娘带新郎回娘家，要送猪腿等礼物，表示孝敬。",
]

func show_tips(level_index: int) -> void:
	var popup = _open(tips_scene)
	if popup == null:
		return
	# 设置对应关卡的提示文字
	if level_index < TIPS_TEXT.size():
		popup.set_tip_text(TIPS_TEXT[level_index])

func show_win() -> Control:
	return _open(win_scene)

func _open(scene: PackedScene) -> Control:
	if not scene:
		push_error("PopupManager: 未分配场景，请在 Inspector 检查。")
		return null
	close_popup()
	current_popup = scene.instantiate()
	popup_layer.add_child(current_popup)
	return current_popup

func close_popup() -> void:
	if current_popup and is_instance_valid(current_popup):
		current_popup.queue_free()
		current_popup = null
