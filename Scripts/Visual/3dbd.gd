extends Node3D
@export var rotation_speed: float = 45.0
@export var float_amplitude: float = 0.2
@export var float_speed: float = 1.5

var _original_y: float
func _ready():
	_original_y = global_position.y

func _process(delta: float):
	rotate_y(deg_to_rad(rotation_speed * delta))
	var time = Time.get_ticks_msec() / 1000.0
	var offset_y = float_amplitude * sin(float_speed * time)
	var pos = global_position
	pos.y = _original_y + offset_y
	global_position = pos
