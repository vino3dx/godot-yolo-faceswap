extends Node

var mode: String = "" ## 当前游戏模式 "wedding" = 婚嫁互动 / "face"= 换装体验
var gender: String = "" ## "male" 或 "female"
var snapshot_path: String = "" ## 拍照保存路径
var result_path: String = "" ## 新增：换脸完成后的结果图片路径
var male_birth_date: Dictionary = {} ## 男性出生年月
var female_birth_date: Dictionary = {} ## 女性出生年月

# 重置游戏状态
func reset() -> void:
	mode = ""
	gender = ""
	snapshot_path = ""
