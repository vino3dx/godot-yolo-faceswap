extends Control

signal previous_level
signal level_completed

@onready var label: Label = $Countdown
@onready var timer: Timer = $Timer
@onready var tips_label: Label = $Label
@onready var portrait_frame: TextureRect = $PortraitFrame
@onready var btn_reshoot: AnimationButton = $VBoxContainer/BtnReshoot
@onready var btn_outfit: AnimationButton = $VBoxContainer/BtnOutfit
@onready var btn_back: AnimationButton = $VBoxContainer/BtnBack
@onready var camera_view := $CameraFeedView
@onready var snapshot_view: TextureRect = $SnapshotView

var countdown := 5
var captured_image: Image = null
const SAVE_PATH := "user://snapshot.png"

# ⏱️ 耗时统计变量
var photo_capture_time: int = 0      # 1. 拍照完成时刻（后台开始计算）
var btn_outfit_click_time: int = 0   # 2. 用户点击换装时刻

var is_swap_done: bool = false       # 后台换脸是否已完成
var is_user_waiting: bool = false    # 用户是否已点击换装等待中
var cached_result_path: String = ""  # 结果缓存路径

func _ready() -> void:
	snapshot_view.visible = false

	btn_reshoot.pressed.connect(_on_btn_reshoot_pressed)
	btn_outfit.pressed.connect(_on_btn_outfit_pressed)
	btn_back.pressed.connect(_on_btn_back_pressed)
	timer.timeout.connect(_on_timer_timeout)
	
	FaceSwapManager.SwapCompleted.connect(_on_swap_completed)
	FtpUploader.UploadCompleted.connect(_on_upload_completed)
	
	_start_countdown()


# 开始倒计时
func _start_countdown() -> void:
	countdown = 5
	label.text = str(countdown)
	label.visible = true
	tips_label.visible = true
	portrait_frame.visible = true
	btn_outfit.disabled = true

	# 重置计时与状态
	photo_capture_time = 0
	btn_outfit_click_time = 0
	is_swap_done = false
	is_user_waiting = false
	cached_result_path = ""
	snapshot_view.visible = false

	timer.wait_time = 1.0
	timer.start()


# 超时后
func _on_timer_timeout() -> void:
	countdown -= 1
	label.text = str(countdown)

	if countdown <= 0:
		timer.stop()
		_capture_photo()
		tips_label.visible = false
		portrait_frame.visible = false
		btn_outfit.disabled = false


# 拍照
func _capture_photo() -> void:
	label.visible = false
	var image = camera_view.capture_frame()
	if image == null:
		push_error("❌ 拍照失败，摄像头未就绪")
		return
	captured_image = image
	var err = captured_image.save_png(SAVE_PATH)
	if err == OK:
		print("✅ 照片已保存：", SAVE_PATH)
		GameState.snapshot_path = SAVE_PATH
	else:
		push_error("❌ 保存失败，错误码：" + str(err))

	var texture = ImageTexture.create_from_image(image)
	snapshot_view.texture = texture
	snapshot_view.visible = true
	btn_reshoot.visible = true
	btn_outfit.visible = true

	# ⏱️ 记录后台开始时刻，并触发 C# 换脸
	photo_capture_time = Time.get_ticks_msec()
	var real_path = ProjectSettings.globalize_path(SAVE_PATH)
	FaceSwapManager.RequestSwap(real_path, GameState.gender)


# 点击重拍按钮
func _on_btn_reshoot_pressed() -> void:
	captured_image = null
	_start_countdown()


# 点击换装按钮
func _on_btn_outfit_pressed() -> void:
	btn_outfit.disabled = true
	btn_outfit_click_time = Time.get_ticks_msec() # ⏱️ 记录用户点击换装时刻
	
	if is_swap_done:
		# 💡 情况 A：用户点按时，后台已经换完脸了（秒过）
		print("⏱️ [用户体验] 点击换装后等待耗时：0.00 秒（后台已提前完成！）")
		_apply_swap_result()
	else:
		# 💡 情况 B：后台还在跑，需要用户等待
		is_user_waiting = true
		tips_label.text = "正在生成中，请稍候..."
		tips_label.visible = true


# 当后台换脸完成（C# 信号回调）
func _on_swap_completed(result_path: String, success: bool, error_message: String) -> void:
	if success:
		# 1️⃣ 计算后台真实换脸耗时（拍照时刻 ➔ 换脸完成时刻）
		var backend_sec := (Time.get_ticks_msec() - photo_capture_time) / 1000.0
		print("⏱️ [后台算法] 真实换脸总耗时：%.2f 秒" % backend_sec)

		is_swap_done = true
		cached_result_path = result_path
		GameState.result_path = result_path

		# 2️⃣ 如果用户在等待，计算用户点击后的等待时间（点击时刻 ➔ 换脸完成时刻）
		if is_user_waiting:
			var user_wait_sec := (Time.get_ticks_msec() - btn_outfit_click_time) / 1000.0
			print("⏱️ [用户体验] 点击换装后实际等待：%.2f 秒" % user_wait_sec)
			_apply_swap_result()
	else:
		push_error("❌ 换脸失败: " + error_message)
		if error_message != "":
			tips_label.text = error_message
		else:
			tips_label.text = "生成失败，请重新拍照"
		
		tips_label.visible = true
		btn_outfit.disabled = false


# 应用结果并进行场景跳转
func _apply_swap_result() -> void:
	var img := Image.new()
	if img.load(cached_result_path) == OK:
		snapshot_view.texture = ImageTexture.create_from_image(img)
		FtpUploader.RequestUpload(img)
		emit_signal("level_completed")
	else:
		push_error("❌ 无法加载换脸结果图片")


# 后台上传完成
func _on_upload_completed(success: bool, url: String, error_message: String) -> void:
	if success:
		print("🚀 照片已成功上传至服务器，访问地址: ", url)
	else:
		print("⚠️ 后台上传失败: ", error_message)


# 点击返回按钮
func _on_btn_back_pressed() -> void:
	timer.stop()
	emit_signal("previous_level")
