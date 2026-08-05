@tool
extends Node
class_name ClassExplorerTool

## ClassExplorerTool：ClassDB 反射调试工具
##
## 用于查看任意已注册类的：
## - Methods
## - Properties
## - Signals
##
## 支持：
## - Inspector 输入类名（target_class）
## - 关键字过滤（keyword_filter）
## - @tool 一键运行（Run Explorer）
##
## 仅支持 ClassDB 已注册类（内置类 / class_name / GDExtension）


@export var target_class: String = "Node" ## 类的名称
@export var auto_run: bool = true ## 是否自动运行
@export var keyword_filter: String = "" ## 关键词过滤
@export_tool_button("🔍 Run Explorer") var run_button: Callable = explore_target

# 运行探索
func _ready() -> void:
	if auto_run:
		explore_target()


## 
func explore_target() -> void:
	explore(target_class)


# 探索类
func explore(cls_name: String) -> void:
	print("\n================================")
	print("🔎 搜索类名:", cls_name)
	print("================================")

	if not ClassDB.class_exists(cls_name):
		print("❌ Class 不存在（未注册或拼写错误）:", cls_name)
		return

	_print_methods(cls_name)
	_print_properties(cls_name)
	_print_signals(cls_name)

# 打印方法
func _print_methods(cls_name: String) -> void:
	print("\n📌 Methods:")
	var methods = ClassDB.class_get_method_list(cls_name, true)
	for m in methods:
		if _filter(m.name):
			print("-", m.name)



# 打印属性
func _print_properties(cls_name: String) -> void:
	print("\n📌 Properties:")
	var props = ClassDB.class_get_property_list(cls_name, true)
	for p in props:
		if _filter(p.name):
			print("-", p.name)


# 打印信号
func _print_signals(cls_name: String) -> void:
	print("\n📌 Signals:")
	var sigs = ClassDB.class_get_signal_list(cls_name, true)
	for s in sigs:
		if _filter(s.name):
			print("-", s.name)


# 过滤器
func _filter(filter_name: String) -> bool:
	if keyword_filter == "":
		return true
	return keyword_filter.to_lower() in filter_name.to_lower()
