extends Node

const PROGRESS_VALUES: Array[int] = [14, 24, 42, 56, 70, 84, 98] ## 婚嫁游戏关卡进度条

## 婚嫁游戏关卡
var level_paths: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
	"res://scenes/levels/level_4.tscn",
	"res://scenes/levels/level_5.tscn",
	"res://scenes/levels/level_6.tscn",
	"res://scenes/levels/level_7.tscn",
]

## 换装体验关卡
var face_level_paths: Array[String] = [
	"res://scenes/face_swapping/level_1.tscn",
	"res://scenes/face_swapping/level_2.tscn",
	"res://scenes/face_swapping/level_3.tscn",
	"res://scenes/face_swapping/level_4.tscn",
	"res://scenes/face_swapping/level_5.tscn",
	"res://scenes/face_swapping/level_6.tscn"
]

var current_scene: Node = null
var current_route: Array[String] = []
var route_index: int = 0  # 统一用这一个

@onready var level_container: Node = $"../LevelContainer"
@onready var popup_manager: Node = $"../PopupManager"
@onready var blocking_layer: Control = $"../UILayer/BlockingLayer"
@onready var progress_bar: TextureProgressBar = $"../UILayer/HUD/ProgressBar"
@onready var transition_video: Control = $"../UILayer/TransitionVideo"

func _ready() -> void:
	progress_bar.visible = false
	load_mode_select() # 这个是模式选择

# ───────────────────────────────────────────
# 模式选择
# ───────────────────────────────────────────

func load_mode_select() -> void:
	_clear_current_scene()
	progress_bar.visible = false
	var scene = load("res://scenes/mode_select/mode_select_ui.tscn").instantiate()
	level_container.add_child(scene)
	current_scene = scene
	scene.mode_selected.connect(_on_mode_selected)


# ───────────────────────────────────────────
# 婚嫁模式专用界面
# ───────────────────────────────────────────

func load_start_screen() -> void:
	_clear_current_scene()
	progress_bar.visible = false
	var scene = load("res://scenes/levels/game_start.tscn").instantiate()
	level_container.add_child(scene)
	current_scene = scene
	scene.start_game.connect(_on_start_game)


func load_end_screen() -> void:
	_clear_current_scene()
	progress_bar.visible = false
	var scene = load("res://scenes/levels/game_end.tscn").instantiate()
	level_container.add_child(scene)
	current_scene = scene
	if scene.has_signal("restart_game"):
		scene.restart_game.connect(_on_restart_game)

# ───────────────────────────────────────────
# 关卡加载
# ───────────────────────────────────────────

func load_level(index: int) -> void:
	_clear_current_scene()
	set_blocking(true)

	# 婚嫁模式才显示进度条
	if GameState.mode == "wedding":
		progress_bar.visible = true
		progress_bar.value = PROGRESS_VALUES[index]
	else:
		progress_bar.visible = false

	var scene = load(current_route[index]).instantiate()
	level_container.add_child(scene)
	current_scene = scene

	if scene.has_signal("animation_finished"):
		scene.animation_finished.connect(_on_animation_finished)
	else:
		set_blocking(false)
	
	# 关卡完成
	if scene.has_signal("level_completed"):
		scene.level_completed.connect(_on_level_completed)
		
	# 返回上一关
	if scene.has_signal("previous_level"):
		scene.previous_level.connect(_on_previous_level)

	# 返回首页
	if scene.has_signal("back_home"):
		scene.back_home.connect(_on_back_home)

# 首页2种模式选择
func _on_mode_selected(mode: String) -> void:
	GameState.mode = mode
	match mode:
		"wedding":
			current_route = level_paths
			load_start_screen()
		"face":
			current_route = face_level_paths
			route_index = 0
			load_level(route_index)
		_:
			push_error("未知模式：" + mode)

	
# 🏠返回首页
func _on_back_home():
	GameState.reset()

	load_mode_select()


# 🔼加载上一关
func _on_previous_level():
	route_index -= 1

	if route_index >= 0:
		load_level(route_index)
	else:
		print("已经是第一关")


# 🔽加载下一关
func _on_next_level() -> void:
	route_index += 1
	
	if route_index < current_route.size():
		load_level(route_index)
	else:
		# 两种模式结束后都回到模式选择
		load_end_screen()

# ───────────────────────────────────────────
# Signal 回调
# ───────────────────────────────────────────

func _on_start_game() -> void:
	route_index = 0
	# 只有婚嫁模式才播放开场视频
	if GameState.mode == "wedding":
		await transition_video.play_start()
	load_level(route_index)

func _on_restart_game() -> void:
	route_index = 0
	if GameState.mode == "wedding":
		await transition_video.play_start()
	load_level(route_index)

func _on_animation_finished() -> void:
	set_blocking(false)
	if GameState.mode == "wedding":
		popup_manager.show_tips(route_index)
	# face 模式直接解除屏蔽，不弹任何窗


# 当关卡完成时
func _on_level_completed() -> void:
	if GameState.mode == "face":
		# 换装模式：直接切下一关，无视频无弹窗
		_on_next_level()
		return

	# 婚嫁模式：过场视频 → 弹窗 → 下一关
	await transition_video.play_level_transition(route_index)
	var popup = popup_manager.show_win()
	if popup == null:
		push_error("show_win() 返回了 null，检查 win_scene 是否赋值")
		return
	await popup.next_level_requested
	popup_manager.close_popup()
	_on_next_level()

# ───────────────────────────────────────────
# 工具函数
# ───────────────────────────────────────────

func set_blocking(enabled: bool) -> void:
	blocking_layer.visible = enabled
	blocking_layer.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE

func _clear_current_scene() -> void:
	if current_scene:
		current_scene.queue_free()
		current_scene = null
