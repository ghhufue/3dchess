@tool
extends Control

@export_group("Text")
@export_multiline var default_text: String = "":
	set(value):
		default_text = value
		_apply_text(default_text)

@export var text_label_path: NodePath:
	set(value):
		text_label_path = value
		_apply_text(current_text if current_text != "" else default_text)

@export var text_font: Font:
	set(value):
		text_font = value
		_apply_text_style()

@export_range(0, 128, 1, "or_greater") var text_font_size: int = 24:
	set(value):
		text_font_size = value
		_apply_text_style()

@export var text_color: Color = Color(0.85, 1.0, 1.0, 1.0):
	set(value):
		text_color = value
		_apply_text_style()

@export_group("Hover Text")
@export var hover_buttons: Array[NodePath] = []:
	set(value):
		hover_buttons = value
		_bind_hover_buttons()

@export_multiline var hover_text_1: String = ""
@export_multiline var hover_text_2: String = ""
@export_multiline var hover_text_3: String = ""
@export_multiline var hover_text_4: String = ""
@export_multiline var hover_text_5: String = ""

@export_group("Panel Style")
@export var bg_color: Color = Color(0.12, 0.45, 0.95, 0.16):
	set(value):
		bg_color = value
		queue_redraw()

@export var border_color: Color = Color(0.75, 1.0, 1.0, 0.75):
	set(value):
		border_color = value
		queue_redraw()

@export_range(0, 32, 1, "or_greater") var border_width: int = 2:
	set(value):
		border_width = value
		queue_redraw()

@export_range(0, 128, 1, "or_greater") var corner_radius: int = 28:
	set(value):
		corner_radius = value
		queue_redraw()

@export var shadow_color: Color = Color(0.0, 0.85, 1.0, 0.35):
	set(value):
		shadow_color = value
		queue_redraw()

@export_range(0, 128, 1, "or_greater") var shadow_size: int = 18:
	set(value):
		shadow_size = value
		queue_redraw()

@export_group("Corner Highlight")
@export var corner_highlight_enabled: bool = true:
	set(value):
		corner_highlight_enabled = value
		queue_redraw()

@export var corner_highlight_color: Color = Color(0.85, 1.0, 1.0, 1.0):
	set(value):
		corner_highlight_color = value
		queue_redraw()

@export_range(0, 128, 1, "or_greater") var corner_highlight_length: int = 34:
	set(value):
		corner_highlight_length = value
		queue_redraw()

@export_range(0, 32, 1, "or_greater") var corner_highlight_thickness: int = 3:
	set(value):
		corner_highlight_thickness = value
		queue_redraw()

@export_range(0, 64, 1, "or_greater") var corner_highlight_inset: int = 14:
	set(value):
		corner_highlight_inset = value
		queue_redraw()

var current_text: String = ""
var panel_style: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_apply_text(default_text)
	_apply_text_style()
	_bind_hover_buttons()
	queue_redraw()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return

	panel_style = _make_panel_style()
	draw_style_box(panel_style, rect)

	if corner_highlight_enabled:
		_draw_corner_highlight(rect)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func set_text(value: String) -> void:
	_apply_text(value)


func _apply_text(value: String) -> void:
	current_text = value

	var label := _text_label()
	if label == null:
		return

	label.text = current_text


func _apply_text_style() -> void:
	var label := _text_label()
	if label == null:
		return

	if text_font != null:
		label.add_theme_font_override("font", text_font)
	else:
		label.remove_theme_font_override("font")

	if text_font_size > 0:
		label.add_theme_font_size_override("font_size", text_font_size)
	else:
		label.remove_theme_font_size_override("font_size")

	label.add_theme_color_override("font_color", _color_or_default(text_color, Color(0.85, 1.0, 1.0, 1.0)))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _bind_hover_buttons() -> void:
	if not is_inside_tree():
		return

	for index in range(hover_buttons.size()):
		var button := get_node_or_null(hover_buttons[index]) as Control
		if button == null:
			continue

		var enter_callable := Callable(self, "_on_hover_button_entered").bind(index)
		if not button.mouse_entered.is_connected(enter_callable):
			button.mouse_entered.connect(enter_callable)

		var exit_callable := Callable(self, "_on_hover_button_exited").bind(index)
		if not button.mouse_exited.is_connected(exit_callable):
			button.mouse_exited.connect(exit_callable)


func _on_hover_button_entered(index: int) -> void:
	_apply_text(_hover_text_for_index(index))


func _on_hover_button_exited(_index: int) -> void:
	_apply_text(default_text)


func _hover_text_for_index(index: int) -> String:
	match index:
		0:
			return hover_text_1
		1:
			return hover_text_2
		2:
			return hover_text_3
		3:
			return hover_text_4
		4:
			return hover_text_5
		_:
			return default_text


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	var radius := _int_or_default(corner_radius, 28)
	var width := _int_or_default(border_width, 2)

	style.bg_color = _color_or_default(bg_color, Color(0.12, 0.45, 0.95, 0.16))
	style.border_color = _color_or_default(border_color, Color(0.75, 1.0, 1.0, 0.75))
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = _color_or_default(shadow_color, Color(0.0, 0.85, 1.0, 0.35))
	style.shadow_size = _int_or_default(shadow_size, 18)
	style.shadow_offset = Vector2.ZERO
	style.anti_aliasing = true

	return style


func _draw_corner_highlight(rect: Rect2) -> void:
	var inset := float(_int_or_default(corner_highlight_inset, 14))
	var length := float(_int_or_default(corner_highlight_length, 34))
	var thickness := float(_int_or_default(corner_highlight_thickness, 3))
	var color := _color_or_default(corner_highlight_color, Color(0.85, 1.0, 1.0, 1.0))

	var left := rect.position.x + inset
	var top := rect.position.y + inset
	var right := rect.position.x + rect.size.x - inset
	var bottom := rect.position.y + rect.size.y - inset

	draw_line(Vector2(left, top), Vector2(left + length, top), color, thickness)
	draw_line(Vector2(left, top), Vector2(left, top + length), color, thickness)

	draw_line(Vector2(right, bottom), Vector2(right - length, bottom), color, thickness)
	draw_line(Vector2(right, bottom), Vector2(right, bottom - length), color, thickness)


func _text_label() -> Label:
	if text_label_path != NodePath():
		return get_node_or_null(text_label_path) as Label

	return get_node_or_null("Label") as Label


func _color_or_default(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value

	return fallback


func _int_or_default(value: Variant, fallback: int) -> int:
	if value is int:
		return value

	if value is float:
		return int(value)

	return fallback
