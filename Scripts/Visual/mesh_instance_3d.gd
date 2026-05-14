extends MeshInstance3D

@export var swing_width: float = 0.12
@export var swing_height: float = 0.10
@export var swing_z: float = 0.08
@export var speed: float = 1.8

var _original_position: Vector3
var _angle: float = 0.0

func _ready() -> void:
	_original_position = global_position

func _process(delta: float) -> void:
	_angle += speed * delta

	var offset = Vector3(
		swing_width * cos(_angle),
		swing_height * sin(_angle),
		swing_z * sin(_angle),
	)

	global_position = _original_position + offset
