extends Control

signal animation_finished
signal level_completed

@onready var btn_confirm: Button = $Btn_Confirm

# 按你实际场景结构调整这两个容器路径，用来分别摆放男/女的滚轮选择器
@onready var male_wheel_container: Control = $MaleWheelContainer
@onready var female_wheel_container: Control = $FemaleWheelContainer

var male_picker: WheelDatePicker
var female_picker: WheelDatePicker

func _ready() -> void:
	await $UIAnimator.play_in_all()
	emit_signal("animation_finished")

	male_picker = _create_picker()
	male_wheel_container.add_child(male_picker)

	female_picker = _create_picker()
	female_wheel_container.add_child(female_picker)

	btn_confirm.pressed.connect(_on_confirm_pressed)

func _create_picker() -> WheelDatePicker:
	var picker := WheelDatePicker.new()
	var current_year: int = Time.get_date_dict_from_system()["year"]
	picker.year_range = Vector2i(1930, current_year)  # 按婚嫁场景合理的年龄范围调整
	picker.item_height = 70.0
	picker.custom_minimum_size = Vector2(0, 350)
	return picker

func _on_confirm_pressed() -> void:
	var male_date: Dictionary = male_picker.get_date()
	var female_date: Dictionary = female_picker.get_date()

	# 存进全局状态，供后续关卡或结果展示使用
	GameState.male_birth_date = male_date
	GameState.female_birth_date = female_date

	print("男方生辰: ", male_date, " 女方生辰: ", female_date)

	emit_signal("level_completed")
