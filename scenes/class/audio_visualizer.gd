extends Node2D

@onready var player: AudioStreamPlayer = $AudioStreamPlayer
@onready var bars_root: Node2D = $Bars

# =========================
# 🎛 可调参数
# =========================

@export var bar_count: int = 32
@export var amplitude: float = 400.0
@export var bar_spacing: float = 14.0
@export var bar_color: Color = Color(0.2, 0.8, 1.0)
@export var max_frequency: float = 2000.0

# 🎯 中心线（重点）
@export var center_y: float = 300.0

# =========================

var bus_index: int
var spectrum: AudioEffectSpectrumAnalyzerInstance
var bars: Array[ColorRect] = []

func _ready() -> void:
		# 先打印所有 Bus 名，确认实际名字
	for i in AudioServer.bus_count:
		print("Bus %d: '%s'" % [i, AudioServer.get_bus_name(i)])
	
	bus_index = AudioServer.get_bus_index("Visualizer")

	if bus_index == -1:
		push_error("❌ 找不到 Visualizer Bus")
		return

	spectrum = AudioServer.get_bus_effect_instance(bus_index, 0)

	if spectrum == null:
		push_error("❌ Spectrum 未初始化")
		return

	_create_bars()
	


func _create_bars() -> void:
	for i in range(bar_count):
		var bar := ColorRect.new()

		bar.color = bar_color

		# 初始高度
		bar.size = Vector2(10.0, 2.0)

		# x位置
		bar.position = Vector2(float(i) * bar_spacing, center_y)

		# ⚠️ 关键：设置锚点在中间（视觉更稳定）
		bar.pivot_offset = Vector2(0, 1)

		bars_root.add_child(bar)
		bars.append(bar)


func _process(_delta: float) -> void:
	if spectrum == null:
		return

	for i in range(bar_count):
		var ratio := float(i) / float(bar_count)

		var from := ratio * max_frequency
		var to := from + 50.0

		var mag := spectrum.get_magnitude_for_frequency_range(from, to)
		var energy := mag.length()

		# =========================
		# 🔥 上下对称高度
		# =========================
		var height: float = clamp(energy * amplitude, 2.0, 300.0)

		var bar: ColorRect = bars[i]

		# 宽度固定，高度变化
		bar.size.y = lerp(bar.size.y, height, 0.2)

		# =========================
		# 🎯 关键：中心对齐
		# =========================
		bar.position.y = center_y - (bar.size.y * 0.5)


func _on_btn_play_audio_pressed() -> void:
	player.play()
