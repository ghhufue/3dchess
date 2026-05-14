extends Button

@export_group("Motion")
@export var motion_enabled := true
@export var swing_width: float = 32.0
@export var swing_height: float = 16.0
@export var speed: float = 1.8
@export var phase_offset: float = 0.0

@export_group("Scene Navigation")
@export var change_scene_on_pressed := false
@export var target_scene: PackedScene
@export_file("*.tscn") var target_scene_path := ""

var _original_position: Vector2
var _angle: float = 0.0

func _ready() -> void:
	_original_position = position
	_angle = phase_offset
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _process(delta: float) -> void:
	if not motion_enabled:
		return

	_angle += speed * delta
	var offset := Vector2(
		swing_width * cos(_angle),
		swing_height * sin(_angle)
	)
	position = _original_position + offset

func _on_pressed() -> void:
	if not change_scene_on_pressed:
		return

	if target_scene != null:
		get_tree().change_scene_to_packed(target_scene)
		return

	if not target_scene_path.is_empty():
		get_tree().change_scene_to_file(target_scene_path)
