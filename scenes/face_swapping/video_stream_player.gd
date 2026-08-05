extends VideoStreamPlayer # 假设此脚本挂在 VideoStreamPlayer 节点上

@export var video_path: String = "D:/1.mp4"

@onready var video_player: VideoStreamPlayer = $"."
@onready var tool_bar: VideoToolBar = $VideoToolBar

func _ready() -> void:
	# 仅仅初始化加载和绑定控制器，绝对不要在这里调用 play()
	_load_external_video()
	tool_bar.bind(video_player)


# 新增这个方法，留给外面的按钮来调用
func start_video() -> void:
	if stream != null:
		# FFmpeg 插件防卡死重置逻辑：重新赋值流以刷新解码器
		var temp_stream = stream
		stream = null
		stream = temp_stream
		
		# 重置进度并确保没有被暂停
		stream_position = 0.0
		paused = false
		
	play()


func _load_external_video() -> void:
	if not FileAccess.file_exists(video_path):
		push_error("视频文件未找到: %s" % video_path)
		return

	if not ClassDB.class_exists("FFmpegVideoStream"):
		push_error("FFmpeg 插件未启用")
		return

	# 动态创建 FFmpeg 视频流并加载路径
	var stream_ff = ClassDB.instantiate("FFmpegVideoStream")
	stream_ff.file = video_path
	video_player.stream = stream_ff
