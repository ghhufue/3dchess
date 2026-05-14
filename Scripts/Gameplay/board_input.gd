extends Node

signal cell_clicked(row: int, col: int)

@export var board_view_path: NodePath = NodePath("../Manager/BoardView")
@export var camera_path: NodePath = NodePath("../CameraRig/Pivot/Camera3D")

@onready var board_view: Node = get_node_or_null(board_view_path)
@onready var camera: Camera3D = get_node_or_null(camera_path)

func _unhandled_input(event: InputEvent) -> void:
	if camera == null or board_view == null:
		return
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var from := camera.project_ray_origin(event.position)
	var dir := camera.project_ray_normal(event.position)
	var to := from + dir * 1000.0

	var space := camera.get_world_3d().direct_space_state
	var result := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
	if not result:
		return

	var rc: Vector2i = board_view.rc_from_world(result.position)
	if rc.x >= 0 and rc.x < 15 and rc.y >= 0 and rc.y < 15:
		cell_clicked.emit(rc.x, rc.y)

