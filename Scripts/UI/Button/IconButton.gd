@tool
extends Button

@export var mode_text: String = "LOCAL TEST":
	set(value):
		mode_text = value
		_apply_content()

@export var mode_icon: Texture2D:
	set(value):
		mode_icon = value
		_apply_content()

@export var title_font: Font:
	set(value):
		title_font = value
		_apply_typography()

@export_range(0, 128, 1, "or_greater") var title_font_size: int = 0:
	set(value):
		title_font_size = value
		_apply_typography()

@export_group("Normal Style")
@export var normal_bg_color: Color = Color(0.12, 0.45, 0.95, 0.28):
	set(value):
		normal_bg_color = value
		_apply_style_config()

@export var normal_border_color: Color = Color(0.65, 0.95, 1.0, 0.45):
	set(value):
		normal_border_color = value
		_apply_style_config()

@export_range(0, 32, 1, "or_greater") var normal_border_width: int = 2:
	set(value):
		normal_border_width = value
		_apply_style_config()

@export var normal_shadow_color: Color = Color(0.0, 0.8, 1.0, 0.25):
	set(value):
		normal_shadow_color = value
		_apply_style_config()

@export_range(0, 64, 1, "or_greater") var normal_shadow_size: int = 8:
	set(value):
		normal_shadow_size = value
		_apply_style_config()

@export_group("Hover Style")
@export var hover_bg_color: Color = Color(0.10, 0.75, 1.0, 0.38):
	set(value):
		hover_bg_color = value
		_apply_style_config()

@export var hover_border_color: Color = Color(0.75, 1.0, 1.0, 0.9):
	set(value):
		hover_border_color = value
		_apply_style_config()

@export_range(0, 32, 1, "or_greater") var hover_border_width: int = 3:
	set(value):
		hover_border_width = value
		_apply_style_config()

@export var hover_shadow_color: Color = Color(0.0, 0.95, 1.0, 0.55):
	set(value):
		hover_shadow_color = value
		_apply_style_config()

@export_range(0, 64, 1, "or_greater") var hover_shadow_size: int = 18:
	set(value):
		hover_shadow_size = value
		_apply_style_config()

@export_group("Selected Style")
@export var selected_bg_color: Color = Color(0.00, 0.85, 0.95, 0.45):
	set(value):
		selected_bg_color = value
		_apply_style_config()

@export var selected_border_color: Color = Color(0.90, 1.0, 1.0, 1.0):
	set(value):
		selected_border_color = value
		_apply_style_config()

@export_range(0, 32, 1, "or_greater") var selected_border_width: int = 4:
	set(value):
		selected_border_width = value
		_apply_style_config()

@export var selected_shadow_color: Color = Color(0.0, 1.0, 1.0, 0.75):
	set(value):
		selected_shadow_color = value
		_apply_style_config()

@export_range(0, 64, 1, "or_greater") var selected_shadow_size: int = 24:
	set(value):
		selected_shadow_size = value
		_apply_style_config()

@export_group("Pressed Style")
@export var pressed_bg_color: Color = Color(0.00, 0.55, 0.80, 0.55):
	set(value):
		pressed_bg_color = value
		_apply_style_config()

@export var pressed_border_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		pressed_border_color = value
		_apply_style_config()

@export_range(0, 32, 1, "or_greater") var pressed_border_width: int = 4:
	set(value):
		pressed_border_width = value
		_apply_style_config()

@export var pressed_shadow_color: Color = Color(0.0, 0.8, 1.0, 0.75):
	set(value):
		pressed_shadow_color = value
		_apply_style_config()

@export_range(0, 64, 1, "or_greater") var pressed_shadow_size: int = 12:
	set(value):
		pressed_shadow_size = value
		_apply_style_config()

@export_group("Shared Style")
@export_range(0, 128, 1, "or_greater") var corner_radius: int = 28:
	set(value):
		corner_radius = value
		_apply_style_config()

@export var normal_title_color: Color = Color(0.88, 0.96, 1.0, 0.95):
	set(value):
		normal_title_color = value
		_update_style()

@export var selected_title_color: Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		selected_title_color = value
		_update_style()

@export_group("Corner Highlight")
@export var corner_highlight_enabled: bool = true:
	set(value):
		corner_highlight_enabled = value
		if corner_highlight_enabled:
			_queue_corner_highlight_redraw()
		else:
			_set_corner_highlight_visible(false, true)

@export var corner_highlight_color: Color = Color(0.85, 1.0, 1.0, 1.0):
	set(value):
		corner_highlight_color = value
		_queue_corner_highlight_redraw()

@export_range(0, 128, 1, "or_greater") var corner_highlight_length: int = 28:
	set(value):
		corner_highlight_length = value
		_queue_corner_highlight_redraw()

@export_range(0, 32, 1, "or_greater") var corner_highlight_thickness: int = 3:
	set(value):
		corner_highlight_thickness = value
		_queue_corner_highlight_redraw()

@export_range(0, 64, 1, "or_greater") var corner_highlight_outset: int = 4:
	set(value):
		corner_highlight_outset = value
		_queue_corner_highlight_redraw()

@export_range(0.0, 1.0, 0.01, "or_greater") var corner_highlight_fade_duration: float = 0.08

@export_group("")
@export var show_icon: bool = true:
	set(value):
		show_icon = value
		_apply_visibility()

@export var show_title: bool = true:
	set(value):
		show_title = value
		_apply_visibility()

@export var selected: bool = false:
	set(value):
		selected = value
		_update_style()

var normal_style: StyleBoxFlat
var hover_style: StyleBoxFlat
var selected_style: StyleBoxFlat
var pressed_style: StyleBoxFlat
var corner_highlight_tween: Tween


func _ready() -> void:
	text = ""
	custom_minimum_size = Vector2(0, 110)

	_set_children_mouse_filter()

	_apply_content()
	_apply_visibility()
	_apply_typography()

	_apply_style_config()
	_setup_corner_highlight()
	_set_corner_highlight_visible(false, true)

	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)
	if not button_down.is_connected(_on_button_down):
		button_down.connect(_on_button_down)
	if not button_up.is_connected(_on_button_up):
		button_up.connect(_on_button_up)


func _apply_content() -> void:
	if not is_inside_tree():
		return

	var icon_rect := _icon_rect()
	var title_label := _title_label()

	if icon_rect != null:
		icon_rect.texture = mode_icon
	if title_label != null:
		title_label.text = mode_text


func _apply_typography() -> void:
	if not is_inside_tree():
		return

	var title_label := _title_label()
	if title_label == null:
		return

	if title_font != null:
		title_label.add_theme_font_override("font", title_font)
	else:
		title_label.remove_theme_font_override("font")

	if title_font_size > 0:
		title_label.add_theme_font_size_override("font_size", title_font_size)
	else:
		title_label.remove_theme_font_size_override("font_size")


func _apply_visibility() -> void:
	if not is_inside_tree():
		return

	_set_collapsed(_icon_rect(), show_icon)
	_set_collapsed(_title_label(), show_title)


func _set_collapsed(node: Control, is_shown: bool) -> void:
	if node == null:
		return

	node.visible = is_shown


func _build_styles() -> void:
	normal_style = _make_style(
		_color_or_default(normal_bg_color, Color(0.12, 0.45, 0.95, 0.28)),
		_color_or_default(normal_border_color, Color(0.65, 0.95, 1.0, 0.45)),
		_int_or_default(normal_border_width, 2),
		_color_or_default(normal_shadow_color, Color(0.0, 0.8, 1.0, 0.25)),
		_int_or_default(normal_shadow_size, 8)
	)

	hover_style = _make_style(
		_color_or_default(hover_bg_color, Color(0.10, 0.75, 1.0, 0.38)),
		_color_or_default(hover_border_color, Color(0.75, 1.0, 1.0, 0.9)),
		_int_or_default(hover_border_width, 3),
		_color_or_default(hover_shadow_color, Color(0.0, 0.95, 1.0, 0.55)),
		_int_or_default(hover_shadow_size, 18)
	)

	selected_style = _make_style(
		_color_or_default(selected_bg_color, Color(0.00, 0.85, 0.95, 0.45)),
		_color_or_default(selected_border_color, Color(0.90, 1.0, 1.0, 1.0)),
		_int_or_default(selected_border_width, 4),
		_color_or_default(selected_shadow_color, Color(0.0, 1.0, 1.0, 0.75)),
		_int_or_default(selected_shadow_size, 24)
	)

	pressed_style = _make_style(
		_color_or_default(pressed_bg_color, Color(0.00, 0.55, 0.80, 0.55)),
		_color_or_default(pressed_border_color, Color(1.0, 1.0, 1.0, 1.0)),
		_int_or_default(pressed_border_width, 4),
		_color_or_default(pressed_shadow_color, Color(0.0, 0.8, 1.0, 0.75)),
		_int_or_default(pressed_shadow_size, 12)
	)

	add_theme_stylebox_override("normal", normal_style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", pressed_style)
	add_theme_stylebox_override("focus", selected_style)


func _apply_style_config() -> void:
	_build_styles()
	_update_style()


func _ensure_styles() -> void:
	if normal_style == null:
		_build_styles()


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


func _float_or_default(value: Variant, fallback: float) -> float:
	if value is float:
		return value

	if value is int:
		return float(value)

	return fallback


func _make_style(
	bg: Color,
	border: Color,
	border_width: int,
	shadow: Color,
	shadow_size: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = bg

	var radius := _int_or_default(corner_radius, 28)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius

	style.border_color = border
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.border_width_top = border_width
	style.border_width_bottom = border_width

	style.shadow_color = shadow
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2.ZERO

	style.anti_aliasing = true

	return style


func _update_style() -> void:
	if not is_inside_tree():
		return

	_ensure_styles()

	var title_label := _title_label()
	if title_label == null:
		return

	if selected:
		add_theme_stylebox_override("normal", selected_style)
		title_label.modulate = _color_or_default(selected_title_color, Color(1.0, 1.0, 1.0, 1.0))
	else:
		add_theme_stylebox_override("normal", normal_style)
		title_label.modulate = _color_or_default(normal_title_color, Color(0.88, 0.96, 1.0, 0.95))


func _on_mouse_entered() -> void:
	if not selected:
		add_theme_stylebox_override("normal", hover_style)

	_set_corner_highlight_visible(true)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.08)


func _on_mouse_exited() -> void:
	_update_style()
	_set_corner_highlight_visible(false)

	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.08)


func _on_button_down() -> void:
	add_theme_stylebox_override("normal", pressed_style)


func _on_button_up() -> void:
	_update_style()


func _set_children_mouse_filter() -> void:
	for node in [
		get_node_or_null("MarginContainer"),
		get_node_or_null("MarginContainer/HBoxContainer"),
		_icon_rect(),
		_title_label(),
		_corner_highlight(),
	]:
		if node is Control:
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _setup_corner_highlight() -> void:
	var highlight := _corner_highlight()
	if highlight == null:
		return

	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not highlight.draw.is_connected(_on_corner_highlight_draw):
		highlight.draw.connect(_on_corner_highlight_draw)
	highlight.queue_redraw()


func _set_corner_highlight_visible(is_visible: bool, immediate: bool = false) -> void:
	var highlight := _corner_highlight()
	if highlight == null:
		return

	if not corner_highlight_enabled:
		is_visible = false
		immediate = true

	if corner_highlight_tween != null:
		corner_highlight_tween.kill()
		corner_highlight_tween = null

	highlight.visible = true
	var target_alpha := 1.0 if is_visible else 0.0

	if immediate:
		var highlight_modulate := highlight.modulate
		highlight_modulate.a = target_alpha
		highlight.modulate = highlight_modulate
		highlight.visible = is_visible
		return

	corner_highlight_tween = create_tween()
	corner_highlight_tween.tween_property(
		highlight,
		"modulate:a",
		target_alpha,
		_float_or_default(corner_highlight_fade_duration, 0.08)
	)
	if not is_visible:
		corner_highlight_tween.tween_callback(func() -> void:
			if is_instance_valid(highlight):
				highlight.visible = false
		)


func _queue_corner_highlight_redraw() -> void:
	var highlight := _corner_highlight()
	if highlight != null:
		highlight.queue_redraw()


func _on_corner_highlight_draw() -> void:
	if not corner_highlight_enabled:
		return

	var highlight := _corner_highlight()
	if highlight == null:
		return

	var rect := Rect2(Vector2.ZERO, highlight.size)
	var outset := float(_int_or_default(corner_highlight_outset, 4))
	var length := float(_int_or_default(corner_highlight_length, 28))
	var thickness := float(_int_or_default(corner_highlight_thickness, 3))
	var color := _color_or_default(corner_highlight_color, Color(0.85, 1.0, 1.0, 1.0))

	var left := rect.position.x - outset
	var top := rect.position.y - outset
	var right := rect.position.x + rect.size.x + outset
	var bottom := rect.position.y + rect.size.y + outset

	highlight.draw_line(Vector2(left, top), Vector2(left + length, top), color, thickness)
	highlight.draw_line(Vector2(left, top), Vector2(left, top + length), color, thickness)

	highlight.draw_line(Vector2(right, top), Vector2(right - length, top), color, thickness)
	highlight.draw_line(Vector2(right, top), Vector2(right, top + length), color, thickness)

	highlight.draw_line(Vector2(left, bottom), Vector2(left + length, bottom), color, thickness)
	highlight.draw_line(Vector2(left, bottom), Vector2(left, bottom - length), color, thickness)

	highlight.draw_line(Vector2(right, bottom), Vector2(right - length, bottom), color, thickness)
	highlight.draw_line(Vector2(right, bottom), Vector2(right, bottom - length), color, thickness)


func _icon_rect() -> TextureRect:
	return get_node_or_null("MarginContainer/HBoxContainer/Icon") as TextureRect


func _title_label() -> Label:
	return get_node_or_null("MarginContainer/HBoxContainer/Title") as Label


func _corner_highlight() -> Control:
	return get_node_or_null("CornerHighlight") as Control
