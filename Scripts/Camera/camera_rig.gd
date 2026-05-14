extends Node3D

@export var target_position := Vector3(6.5, 0.0, 6.5)
@export var target_height := 0.0

@export var distance: float = 18.0
@export var min_distance: float = 8.0
@export var max_distance: float = 28.0
@export var zoom_step: float = 1.0

@export var yaw: float = 0.0
@export var pitch_deg: float = -48.0
@export var min_pitch_deg: float = -80.0
@export var max_pitch_deg: float = -10.0

@export var yaw_speed: float = 0.003
@export var pitch_speed: float = 0.1

# BGM 音量范围（dB）
@export var zoom_bgm_min_db: float = -40
@export var zoom_bgm_max_db: float = -10

@onready var pivot: Node3D = $Pivot
@onready var cam: Camera3D = $Pivot/Camera3D
@onready var zoom_bgm: AudioStreamPlayer = $"../ZoomBgm"

var zoom_bgm_enabled := false

func _ready() -> void:
	_apply_camera_transform()
	_update_zoom_bgm_volume()

func enable_zoom_bgm() -> void:
	zoom_bgm_enabled = true
	if is_instance_valid(zoom_bgm) and not zoom_bgm.playing:
		zoom_bgm.play()
	_update_zoom_bgm_volume()

func _update_zoom_bgm_volume() -> void:
	if not zoom_bgm_enabled:
		return
	if not is_instance_valid(zoom_bgm):
		return

	var t := inverse_lerp(max_distance, min_distance, distance)
	t = clamp(t, 0.0, 1.0)
	t = pow(t, 2.0)
	zoom_bgm.volume_db = lerp(zoom_bgm_min_db, zoom_bgm_max_db, t)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoomIn"):
		distance = max(min_distance, distance - zoom_step)
		_apply_camera_transform()
		_update_zoom_bgm_volume()
		return

	if event.is_action_pressed("zoomOut"):
		distance = min(max_distance, distance + zoom_step)
		_apply_camera_transform()
		_update_zoom_bgm_volume()
		return

	if event is InputEventMouseMotion and Input.is_action_pressed("spin"):
		yaw -= event.relative.x * yaw_speed
		pitch_deg = clamp(
			pitch_deg - event.relative.y * pitch_speed,
			min_pitch_deg,
			max_pitch_deg
		)
		_apply_camera_transform()

func _apply_camera_transform() -> void:
	global_position = target_position + Vector3(0, target_height, 0)
	rotation = Vector3.ZERO
	rotation.y = yaw

	pivot.position = Vector3.ZERO
	pivot.rotation = Vector3.ZERO
	pivot.rotation.x = deg_to_rad(pitch_deg)

	cam.position = Vector3(0, 0, distance)
	cam.rotation = Vector3.ZERO
