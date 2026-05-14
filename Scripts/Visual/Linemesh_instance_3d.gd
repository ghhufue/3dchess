extends MeshInstance3D

@export var board_size: int = 15
@export var cell_size: float = 1.0
@export var origin: Vector3 = Vector3(-0.5, 0.0, -0.5)
@export var y_offset: float = 0.2

func _ready() -> void:
	var im := ImmediateMesh.new()
	var mat := ORMMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.0, 0.0, 0.0, 0.831)
	mat.no_depth_test = false 
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	var start := origin + Vector3(cell_size, 0.0, cell_size)

	var line_count := board_size
	var span := float(board_size - 1) * cell_size

	for i in range(line_count):
		var p := float(i) * cell_size
		im.surface_add_vertex(Vector3(start.x, origin.y + y_offset, start.z + p))
		im.surface_add_vertex(Vector3(start.x + span, origin.y + y_offset, start.z + p))
		im.surface_add_vertex(Vector3(start.x + p, origin.y + y_offset, start.z))
		im.surface_add_vertex(Vector3(start.x + p, origin.y + y_offset, start.z + span))

	im.surface_end()
	mesh = im
