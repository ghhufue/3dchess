extends Node3D

@onready var board_manager := $Manager/BoardManager
@onready var camera: Camera3D = $CameraRig/Pivot/Camera3D

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var from = camera.project_ray_origin(event.position)
		var dir = camera.project_ray_normal(event.position)
		var to = from + dir * 1000.0

		var space = get_world_3d().direct_space_state
		var result = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))

		if result:
			var pos = result.position
			var rc = board_manager.rc_from_world(pos)
			var row = rc.x
			var col = rc.y
			if row >= 0 and row < 15 and col >= 0 and col < 15:
				board_manager.on_player_click(row, col)
