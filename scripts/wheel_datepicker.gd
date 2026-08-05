class_name WheelDatePicker
extends HBoxContainer

## 组合年/月/日（可选时）三到四列滚轮，自动处理月份天数联动和闰年
## 用法：代码里 new 出来 add_child 即可，不需要额外搭场景节点

signal date_changed(date: Dictionary)

@export var year_range: Vector2i = Vector2i(1970, 2010)
@export var show_hour: bool = false
@export var item_height: float = 60.0

var year_column: WheelColumn
var month_column: WheelColumn
var day_column: WheelColumn
var hour_column: WheelColumn

var _year: int
var _month: int
var _day: int
var _hour: int = 0

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 12)

	year_column = _make_column()
	month_column = _make_column()
	day_column = _make_column()

	add_child(year_column)
	add_child(_make_separator("年"))
	add_child(month_column)
	add_child(_make_separator("月"))
	add_child(day_column)
	add_child(_make_separator("日"))

	if show_hour:
		hour_column = _make_column()
		add_child(hour_column)
		add_child(_make_separator("时"))

	_setup_years()
	_setup_months()
	_update_days()
	if show_hour:
		_setup_hours()

	year_column.value_changed.connect(_on_year_changed)
	month_column.value_changed.connect(_on_month_changed)
	day_column.value_changed.connect(_on_day_changed)
	if show_hour:
		hour_column.value_changed.connect(_on_hour_changed)

	_emit_date()

func _make_column() -> WheelColumn:
	var col := WheelColumn.new()
	col.item_height = item_height
	col.custom_minimum_size = Vector2(100, item_height * 5)
	return col

func _make_separator(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return lbl

func _setup_years() -> void:
	var arr: Array[String] = []
	for y in range(year_range.x, year_range.y + 1):
		arr.append(str(y))
	year_column.values = arr
	_year = year_range.x
	year_column.set_selected_index(0)

func _setup_months() -> void:
	var arr: Array[String] = []
	for m in range(1, 13):
		arr.append(str(m))
	month_column.values = arr
	_month = 1
	month_column.set_selected_index(0)

func _setup_hours() -> void:
	var arr: Array[String] = []
	for h in range(0, 24):
		arr.append(str(h))
	hour_column.values = arr
	hour_column.set_selected_index(0)

func _update_days() -> void:
	var days_in_month: int = _get_days_in_month(_year, _month)
	var arr: Array[String] = []
	for d in range(1, days_in_month + 1):
		arr.append(str(d))
	var prev_day: int = _day if _day > 0 else 1
	day_column.values = arr
	var new_index: int = clamp(prev_day - 1, 0, arr.size() - 1)
	day_column.set_selected_index(new_index)
	_day = new_index + 1

func _get_days_in_month(year: int, month: int) -> int:
	match month:
		1, 3, 5, 7, 8, 10, 12:
			return 31
		4, 6, 9, 11:
			return 30
		2:
			return 29 if _is_leap_year(year) else 28
		_:
			return 30

func _is_leap_year(year: int) -> bool:
	return (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0)

func _on_year_changed(_index: int, value: String) -> void:
	_year = int(value)
	_update_days()
	_emit_date()

func _on_month_changed(_index: int, value: String) -> void:
	_month = int(value)
	_update_days()
	_emit_date()

func _on_day_changed(_index: int, value: String) -> void:
	_day = int(value)
	_emit_date()

func _on_hour_changed(_index: int, value: String) -> void:
	_hour = int(value)
	_emit_date()

func _emit_date() -> void:
	date_changed.emit(get_date())

## 获取当前选中的日期，返回 {"year":.., "month":.., "day":.., ["hour":..]}
func get_date() -> Dictionary:
	var d := {"year": _year, "month": _month, "day": _day}
	if show_hour:
		d["hour"] = _hour
	return d

## 设置初始日期（比如恢复上次选择，或给个默认值）
func set_date(year: int, month: int, day: int, hour: int = 0) -> void:
	_year = clamp(year, year_range.x, year_range.y)
	_month = clamp(month, 1, 12)
	year_column.set_selected_index(_year - year_range.x)
	month_column.set_selected_index(_month - 1)
	_update_days()
	var days: int = _get_days_in_month(_year, _month)
	_day = clamp(day, 1, days)
	day_column.set_selected_index(_day - 1)
	if show_hour:
		_hour = clamp(hour, 0, 23)
		hour_column.set_selected_index(_hour)
	_emit_date()
