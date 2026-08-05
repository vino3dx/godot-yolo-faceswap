extends TextureRect
class_name ItemCard

signal dropped(card: ItemCard)

var dragging := false
var is_snapped := false
var drag_offset := Vector2.ZERO
var origin_pos: Vector2

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	origin_pos = global_position

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if is_snapped:
				is_snapped = false
			dragging = true
			drag_offset = global_position - get_global_mouse_position()
			z_index = 100
		else:
			dragging = false
			z_index = 0
			emit_signal("dropped", self)

func _process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + drag_offset

func return_to_origin() -> void:
	is_snapped = false
	var t = create_tween()
	t.tween_property(self, "global_position", origin_pos, 0.25)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func snap_to(pos: Vector2) -> void:
	is_snapped = true
	global_position = pos
