extends Control

signal animation_finished
signal level_completed

# 音频资源
const SOUNDS = [
	preload("res://assets/audio/打锣通关1.mp3"),
	preload("res://assets/audio/知识卡片弹窗.mp3"),
	preload("res://assets/audio/确认键，返回键.mp3"),
	preload("res://assets/audio/试听按钮音效.mp3"),
]

# 对应关系：按钮索引 0~3 对应 爹爹/娘亲/哥哥/嫂嫂
const ANSWER_MAP = {
	0: 0,  # BtnPerson1 → 爹爹
	1: 1,  # BtnPerson2 → 娘亲
	2: 2,  # BtnPerson3 → 哥哥
	3: 3,  # BtnPerson4 → 嫂嫂
}

const CORRECT_INDEX := 1  # 娘亲
const SOUND := preload("res://assets/sound/哭嫁歌.mp3")

@onready var btn_play_audio: AnimationButton = $Btn_PlayAudio
@onready var btn_confirm: AnimationButton = $Btn_Confirm
@onready var btn_back_to_home: Button = $Btn_BackToHome
@onready var person_btns: Array = [
	$BtnPerson1,
	$BtnPerson2,
	$BtnPerson3,
	$BtnPerson4,
]
@onready var name_btns: Array = [
	$BtnPerson1/选择框,
	$BtnPerson2/选择框,
	$BtnPerson3/选择框,
	$BtnPerson4/选择框,
]

var audio_player: AudioStreamPlayer
#var current_sound_index: int = -1  # 本关随机到的音频索引
var selected_index: int = -1       # 玩家当前选中的按钮索引

func _ready() -> void:
	await $UIAnimator.play_in_all()
	emit_signal("animation_finished")
	$AudioVisualizer.show()

	# 创建音频播放器
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.bus = "Visualizer"
	audio_player.stream = SOUND

	# 连接按钮
	btn_play_audio.pressed.connect(_on_play_audio_pressed)
	btn_confirm.pressed.connect(_on_confirm_pressed)
	
	$CheckButton.button_pressed = false

	for i in person_btns.size():
		var btn = person_btns[i]
		var idx = i
		btn.pressed.connect(func(): _on_person_btn_pressed(idx))
	
	# 名字按钮
	for i in name_btns.size():
		var btn = name_btns[i]
		var idx = i  # 闭包捕获
		btn.pressed.connect(func(): _on_person_btn_pressed(idx))

# ───────────────────────────────────────────
# 播放音频
# ───────────────────────────────────────────

func _on_play_audio_pressed() -> void:
	audio_player.stop()
	audio_player.play()
	
	$CheckButton.button_pressed = true

# ───────────────────────────────────────────
# 选择人物
# ───────────────────────────────────────────

func _on_person_btn_pressed(index: int) -> void:
	selected_index = index

	# 高亮选中，取消其他
	for i in person_btns.size():
		person_btns[i].button_pressed = (i == index)

# ───────────────────────────────────────────
# 提交答案
# ───────────────────────────────────────────

func _on_confirm_pressed() -> void:
	if selected_index == -1:
		return  # 没有选择，不响应

	if selected_index == CORRECT_INDEX:
		emit_signal("level_completed")
	else:
		_shake_wrong()

func _shake_wrong() -> void:
	AudioManager.play_error()
	# 抖动选错的按钮
	var btn = person_btns[selected_index]
	var pos = btn.global_position
	var t = create_tween()
	t.tween_property(btn, "global_position:x", pos.x + 10, 0.05)
	t.tween_property(btn, "global_position:x", pos.x - 10, 0.05)
	t.tween_property(btn, "global_position:x", pos.x + 6, 0.05)
	t.tween_property(btn, "global_position:x", pos.x, 0.05)
	await t.finished

	# 重置选中状态
	selected_index = -1
	for button in person_btns:
		button.button_pressed = false


func _on_check_button_toggled(toggled_on: bool) -> void:
	print(toggled_on)

	audio_player.stream_paused = !toggled_on
