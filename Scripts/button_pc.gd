extends Button

@export var swing_width: float = 32.0
@export var swing_height: float = 16.0
@export var speed: float = 1.8

var _original_position: Vector2
var _angle: float = 0.0

func _ready() -> void:
	_original_position = position

func _process(delta: float) -> void:
	_angle += speed * delta
	var offset = Vector2(
		swing_width * cos(_angle),
		swing_height * sin(_angle)
	)
	position = _original_position + offset
