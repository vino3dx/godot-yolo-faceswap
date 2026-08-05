extends Control

signal animation_finished
signal level_completed

# =========================================================
# UI节点
# =========================================================
@onready var grid_slots: Array[TextureRect] = [
	$GridContainer/TextureRect1,
	$GridContainer/TextureRect2,
	$GridContainer/TextureRect3,
	$GridContainer/TextureRect4,
	$GridContainer/TextureRect5,
	$GridContainer/TextureRect6
]

@onready var item_cards: Array = [
	$HBoxContainer/ItemGoodCard,
	$HBoxContainer/ItemGoodCard2,
	$HBoxContainer/ItemGoodCard3,
	$HBoxContainer/ItemGoodCard4,
	$HBoxContainer/ItemGoodCard5,
	$HBoxContainer/ItemGoodCard6
]

@onready var btn_confirm: Button = $Btn_Confirm

# =========================================================
# 资源映射（id → 图标）
# =========================================================
@onready var item_textures: Dictionary = {
	1: preload("res://assets/ui/level7/chk_喜糖.png"),
	2: preload("res://assets/ui/level7/chk_酒.png"),
	3: preload("res://assets/ui/level7/chk_大米.png"),
	4: preload("res://assets/ui/level7/chk_布匹.png"),
	5: preload("res://assets/ui/level7/chk_猪肘.png"),
	6: preload("res://assets/ui/level7/chk_鸡蛋.png")
}

# 过关所需的物品ID：至少包含 2、4、6，多选不影响
const REQUIRED_IDS := [2, 4, 6]

# =========================================================
# 状态
# =========================================================
var selected_items: Array[int] = []

# =========================================================
# 初始化
# =========================================================
func _ready() -> void:
	await $UIAnimator.play_in_all()
	emit_signal("animation_finished")

	for card in item_cards:
		if card == null:
			continue
		if card.has_signal("item_toggled"):
			if not card.item_toggled.is_connected(_on_card_item_toggled):
				card.item_toggled.connect(_on_card_item_toggled)

	if btn_confirm:
		btn_confirm.pressed.connect(_on_btn_confirm_pressed)

# =========================================================
# 卡片点击 → 立即刷新右侧面板
# =========================================================
func _on_card_item_toggled(item_id: int, is_selected: bool) -> void:
	if is_selected:
		if item_id not in selected_items:
			selected_items.append(item_id)
	else:
		selected_items.erase(item_id)
	_update_grid_display()

# =========================================================
# 刷新背包显示
# =========================================================
func _update_grid_display() -> void:
	for slot in grid_slots:
		if slot:
			slot.texture = null

	for i in range(min(selected_items.size(), grid_slots.size())):
		var id: int = selected_items[i]
		if item_textures.has(id):
			grid_slots[i].texture = item_textures[id]

# =========================================================
# 确认按钮 → 校验是否包含 2、4、6
# =========================================================
func _on_btn_confirm_pressed() -> void:
	print("选中的编号：", selected_items)

	if _check_correct(selected_items):
		emit_signal("level_completed")
	else:
		print("❌ 不对，必须至少包含 ", REQUIRED_IDS)
		_show_error_feedback()

func _check_correct(ids: Array) -> bool:
	for required_id in REQUIRED_IDS:
		if required_id not in ids:
			return false
	return true

func _show_error_feedback() -> void:
	# 可以在这里做个简单的提示，比如按钮抖动或label变红
	print("❌ 至少需要选择前两项")
	AudioManager.play_error()
