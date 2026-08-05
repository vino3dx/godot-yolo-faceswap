extends Control

signal previous_level
signal back_home

@onready var both: TextureRect = $Both
@onready var btn_back: AnimationButton = $VBoxContainer/BtnBack
@onready var btn_take_photo: AnimationButton = $VBoxContainer/BtnTakePhoto
@onready var btn_to_home: AnimationButton = $VBoxContainer/BtnToHome


func _ready() -> void:
	# 不管男生、女生还是双人，
	# 最终都显示同一个换脸结果
	both.visible = true

	if GameState.result_path != "" and FileAccess.file_exists(GameState.result_path):
		var img := Image.new()
		var err := img.load(GameState.result_path)

		if err == OK:
			both.texture = ImageTexture.create_from_image(img)
		else:
			push_error("结果图片加载失败: " + str(err))
	else:
		push_error("没有找到换脸结果路径: " + GameState.result_path)


func _on_btn_back_pressed() -> void:
	emit_signal("previous_level")


func _on_btn_take_photo_pressed() -> void:
	emit_signal("previous_level")


func _on_btn_to_home_pressed() -> void:
	emit_signal("back_home")
