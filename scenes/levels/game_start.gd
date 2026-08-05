extends Control

signal start_game

@onready var btn_start: Button = $Btn_Enter

func _ready() -> void:
	btn_start.pressed.connect(_on_btn_start_pressed)
	print("🔘 按钮信号已连接")

func _on_btn_start_pressed() -> void:
	print("🔘 按钮被点击了")
	emit_signal("start_game")
