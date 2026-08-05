@tool
extends TextureRect

# 定义枚举
enum Step { STEP1, STEP2, STEP3 }

# 导出每一组的图片，这样你在编辑器里就能直接拖拽赋值
@export_group("Step 1 Settings")
@export var step1_normal: Texture2D
@export var step1_active: Texture2D

@export_group("Step 2 Settings")
@export var step2_normal: Texture2D
@export var step2_active: Texture2D

@export_group("Step 3 Settings")
@export var step3_normal: Texture2D
@export var step3_active: Texture2D

@export var current_step: Step = Step.STEP1:
	set(value):
		current_step = value
		_update_visuals()

# 节点引用
@onready var steps: Array[TextureRect] = [
	$HBoxContainer/Btn点击新娘Normal, 
	$HBoxContainer/Btn选择祝福Normal, 
	$HBoxContainer/Btn祝福成功Normal
]

func _ready():
	# 这一行必须有，否则游戏启动时图片不会根据当前的 current_step 初始化
	_update_visuals()

func _update_visuals():
	# 定义一个映射数组，方便遍历
	var normals = [step1_normal, step2_normal, step3_normal]
	var actives = [step1_active, step2_active, step3_active]
	
	for i in range(steps.size()):
		if not steps[i]: continue
		
		# 如果是当前步骤，用 active 图，否则用 normal 图
		if i == current_step:
			steps[i].texture = actives[i]
		else:
			steps[i].texture = normals[i]
