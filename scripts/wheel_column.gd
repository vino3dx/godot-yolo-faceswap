class_name WheelColumn
extends Control

## 单列滚轮选择器：显示一组字符串
## 支持两种交互：① 拖拽滑动切换  ② 点击任意可见项直接选中
## 纯 _draw() 手绘，不依赖任何贴图
##
## 触屏说明：Godot 默认开启了 Project Settings -> Input Devices -> Pointing ->
## "Emulate Mouse From Touch"，触屏点击/拖拽会自动转换成鼠标事件，
## 所以这里只处理 InputEventMouseButton / InputEventMouseMotion 即可，
## 不需要额外写 InputEventScreenTouch，避免同一次触摸被处理两次。

signal value_changed(index: int, value: String)

@export var item_height: float = 60.0
@export var visible_count: int = 5          # 建议奇数，上下对称显示的项数
@export var font_size: int = 28
@export var center_font_size: int = 36
@export var center_color: Color = Color("#53331e")   # 中心项高亮色
@export var normal_color: Color = Color(1.0, 1.0, 1.0, 1.0)

# 点击 vs 拖拽 的判定阈值：按下到松开总移动距离小于这个值(像素)，判定为"点击"
@export var tap_max_distance: float = 14.0

# 灵敏度相关：数值越大越"跟手"但也越容易甩过头，可按现场触屏手感微调
@export var friction: float = 0.85          # 越小惯性衰减越快（原来是0.9，调低更快停下）
@export var max_velocity: float = 90.0      # 单帧最大速度上限，防止快速甩动直接飞过好几项
@export var velocity_smoothing: float = 0.5 # 速度平滑系数，越小越平滑（防抖动导致的误判）

@export var values: Array[String] = []:
	set(v):
		values = v
		_current_index = clamp(_current_index, 0, max(values.size() - 1, 0))
		queue_redraw()

var _current_index: int = 0
var _offset: float = 0.0
var _dragging: bool = false
var _drag_start_y: float = 0.0
var _drag_start_offset: float = 0.0
var _velocity: float = 0.0
var _last_drag_y: float = 0.0
var _tween: Tween

# 用于区分点击/拖拽
var _press_pos: Vector2 = Vector2.ZERO
var _total_move_distance: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(120, item_height * visible_count)

## 外部设置当前选中项（比如 set_date 联动月份/天数时用），无动画立即生效
func set_selected_index(index: int) -> void:
	if values.is_empty():
		return
	if _tween:
		_tween.kill()
	index = clamp(index, 0, values.size() - 1)
	_current_index = index
	_offset = 0.0
	queue_redraw()
	value_changed.emit(_current_index, values[_current_index])

func get_selected_value() -> String:
	if values.is_empty():
		return ""
	return values[_current_index]

func get_selected_index() -> int:
	return _current_index

func _gui_input(event: InputEvent) -> void:
	if values.is_empty():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_press_pos = event.position
				_total_move_distance = 0.0
				_drag_start_y = event.position.y
				_drag_start_offset = _offset
				_velocity = 0.0
				_last_drag_y = event.position.y
				if _tween:
					_tween.kill()
			else:
				_dragging = false
				if _total_move_distance < tap_max_distance:
					# 移动距离很小，判定为"点击"，直接选中点到的那一项
					_select_by_tap(event.position.y)
				else:
					_snap_to_nearest()

	elif event is InputEventMouseMotion and _dragging:
		_total_move_distance += event.position.distance_to(
			Vector2(event.position.x, _last_drag_y)
		)
		var delta_y: float = event.position.y - _drag_start_y
		_offset = _drag_start_offset + delta_y

		var instant_velocity: float = event.position.y - _last_drag_y
		_velocity = lerp(_velocity, instant_velocity, velocity_smoothing)
		_velocity = clamp(_velocity, -max_velocity, max_velocity)

		_last_drag_y = event.position.y
		_normalize_offset()
		queue_redraw()

## 点击某个可见项（不一定是中心项），计算它对应哪个 index，平滑滚动过去选中
func _select_by_tap(click_y: float) -> void:
	var center_y: float = size.y * 0.5
	var diff: float = click_y - center_y
	var delta_index: int = int(round(diff / item_height))
	var target_index: int = clamp(_current_index + delta_index, 0, values.size() - 1)
	_animate_to_index(target_index)

func _animate_to_index(target_index: int) -> void:
	if target_index == _current_index:
		return
	if _tween:
		_tween.kill()
	var direction: float = sign(target_index - _current_index)
	_current_index = target_index
	# 起始给一个小幅反向偏移，做出"滑入定位"的效果
	_offset = -direction * item_height * 0.4
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_offset_animated, _offset, 0.0, 0.2)
	_tween.finished.connect(func():
		value_changed.emit(_current_index, values[_current_index])
	)

func _normalize_offset() -> void:
	var half: float = item_height * 0.5
	while _offset > half and _current_index > 0:
		_offset -= item_height
		_current_index -= 1
	while _offset < -half and _current_index < values.size() - 1:
		_offset += item_height
		_current_index += 1
	# 首尾项拖拽时的橡皮筋阻尼手感
	if _current_index == 0 and _offset > half:
		_offset = half + (_offset - half) * 0.3
	if _current_index == values.size() - 1 and _offset < -half:
		_offset = -half + (_offset + half) * 0.3

func _snap_to_nearest() -> void:
	if _tween:
		_tween.kill()
	var start_offset: float = _offset
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(_set_offset_animated, start_offset, 0.0, 0.2)
	_tween.finished.connect(func():
		value_changed.emit(_current_index, values[_current_index])
	)

func _set_offset_animated(v: float) -> void:
	_offset = v
	queue_redraw()

func _process(_delta: float) -> void:
	if not _dragging and abs(_velocity) > 0.5:
		_offset += _velocity
		_velocity *= friction
		_normalize_offset()
		queue_redraw()
		if abs(_velocity) < 0.5:
			_snap_to_nearest()

func _draw() -> void:
	if values.is_empty():
		return
	var center_y: float = size.y * 0.5
	var half_count: int = int(visible_count / 2.0) + 1
	var font := ThemeDB.fallback_font

	for i in range(-half_count, half_count + 1):
		var idx: int = _current_index + i
		if idx < 0 or idx >= values.size():
			continue
		var y: float = center_y + i * item_height + _offset
		if y < -item_height or y > size.y + item_height:
			continue

		var dist_ratio: float = clamp(abs(y - center_y) / (item_height * half_count), 0.0, 1.0)
		var alpha: float = lerp(1.0, 0.25, dist_ratio)
		var is_center: bool = idx == _current_index and abs(_offset) < 2.0
		var fsize: int = center_font_size if is_center else int(lerp(float(font_size), font_size * 0.7, dist_ratio))

		var text: String = values[idx]
		var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize)
		var pos := Vector2(size.x * 0.5 - text_size.x * 0.5, y + fsize * 0.35)

		var color: Color = center_color if is_center else Color(normal_color.r, normal_color.g, normal_color.b, alpha)
		draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize, color)

	# 中间高亮条，标出当前选中区域，同时给用户一个"点这里"的视觉提示
	draw_rect(Rect2(0, center_y - item_height * 0.5, size.x, item_height), Color("ffffff14"), true)
