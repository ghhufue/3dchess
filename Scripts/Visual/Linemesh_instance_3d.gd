extends Node3D

@export var board_size: int = 15
@export var cell_size: float = 1.0
@export var origin: Vector3 = Vector3(-0.5, 0.0, -0.5)

@export var board_margin: float = 0.52
@export var board_thickness: float = 0.12
@export var surface_y: float = -0.035
@export var line_y: float = 0.012
@export var marker_y: float = 0.022

@export var board_color: Color = Color(0.24, 0.36, 0.30, 1.0)
@export var board_edge_color: Color = Color(0.11, 0.18, 0.15, 1.0)
@export var line_color: Color = Color(0.82, 0.96, 0.88, 0.86)
@export var star_color: Color = Color(0.95, 1.0, 0.92, 1.0)
@export var point_color: Color = Color(0.78, 0.95, 0.86, 0.48)

@export var line_width: float = 0.026
@export var border_width: float = 0.055
@export var point_radius: float = 0.035
@export var star_radius: float = 0.105
@export var marker_segments: int = 18

@export var draw_all_intersection_points := true
@export var draw_star_points := true

var _surface: MeshInstance3D
var _lines: MeshInstance3D
var _markers: MeshInstance3D
var _body: StaticBody3D
var _collision: CollisionShape3D


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	_clear_generated_children()
	_create_surface()
	_create_collision()
	_create_lines()
	_create_markers()


func _clear_generated_children() -> void:
	for child in get_children():
		child.queue_free()


func _create_surface() -> void:
	var span := _span()
	var side := span + board_margin * 2.0
	var center := _board_center()

	var mesh := BoxMesh.new()
	mesh.size = Vector3(side, board_thickness, side)

	_surface = MeshInstance3D.new()
	_surface.name = "BoardSurface"
	_surface.mesh = mesh
	_surface.position = Vector3(center.x, surface_y - board_thickness * 0.5, center.z)
	_surface.set_surface_override_material(0, _standard_material(board_color, false))
	add_child(_surface)


func _create_collision() -> void:
	var span := _span()
	var side := span + board_margin * 2.0
	var center := _board_center()

	_body = StaticBody3D.new()
	_body.name = "BoardBody"
	_body.position = Vector3(center.x, 0.0, center.z)
	add_child(_body)

	var shape := BoxShape3D.new()
	shape.size = Vector3(side, 0.12, side)

	_collision = CollisionShape3D.new()
	_collision.name = "CollisionShape3D"
	_collision.position = Vector3(0.0, surface_y, 0.0)
	_collision.shape = shape
	_body.add_child(_collision)


func _create_lines() -> void:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	var start := _grid_start()
	var span := _span()
	for i in range(board_size):
		var p := float(i) * cell_size
		var width := border_width if i == 0 or i == board_size - 1 else line_width
		_add_rect_xz(
			vertices,
			normals,
			indices,
			Vector3(start.x, line_y, start.z + p),
			Vector3(start.x + span, line_y, start.z + p),
			width
		)
		_add_rect_xz(
			vertices,
			normals,
			indices,
			Vector3(start.x + p, line_y, start.z),
			Vector3(start.x + p, line_y, start.z + span),
			width
		)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	_lines = MeshInstance3D.new()
	_lines.name = "BoardLines"
	_lines.mesh = mesh
	_lines.set_surface_override_material(0, _standard_material(line_color, true))
	add_child(_lines)


func _create_markers() -> void:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	var star_points := _star_points()

	if draw_all_intersection_points:
		for row in range(board_size):
			for col in range(board_size):
				var is_star := star_points.has(Vector2i(row, col))
				var radius := star_radius if is_star and draw_star_points else point_radius
				var color_slot := 1 if is_star and draw_star_points else 0
				_add_disc(vertices, normals, indices, _point_position(row, col, marker_y), radius, color_slot)
	elif draw_star_points:
		for rc in star_points:
			_add_disc(vertices, normals, indices, _point_position(rc.x, rc.y, marker_y), star_radius, 1)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	_markers = MeshInstance3D.new()
	_markers.name = "BoardIntersections"
	_markers.mesh = mesh
	_markers.set_surface_override_material(0, _standard_material(point_color, true))
	add_child(_markers)

	if draw_star_points:
		_create_star_overlay(star_points)


func _create_star_overlay(star_points: Array[Vector2i]) -> void:
	var mesh := ArrayMesh.new()
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for rc in star_points:
		_add_disc(vertices, normals, indices, _point_position(rc.x, rc.y, marker_y + 0.004), star_radius * 0.72, 0)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var overlay := MeshInstance3D.new()
	overlay.name = "BoardStarPoints"
	overlay.mesh = mesh
	overlay.set_surface_override_material(0, _standard_material(star_color, true))
	add_child(overlay)


func _add_rect_xz(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	indices: PackedInt32Array,
	a: Vector3,
	b: Vector3,
	width: float
) -> void:
	var dir := Vector2(b.x - a.x, b.z - a.z).normalized()
	var perp := Vector2(-dir.y, dir.x) * width * 0.5
	var base := vertices.size()
	vertices.append(Vector3(a.x + perp.x, a.y, a.z + perp.y))
	vertices.append(Vector3(a.x - perp.x, a.y, a.z - perp.y))
	vertices.append(Vector3(b.x - perp.x, b.y, b.z - perp.y))
	vertices.append(Vector3(b.x + perp.x, b.y, b.z + perp.y))
	for _i in range(4):
		normals.append(Vector3.UP)
	indices.append_array([base, base + 1, base + 2, base, base + 2, base + 3])


func _add_disc(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	indices: PackedInt32Array,
	center: Vector3,
	radius: float,
	_color_slot: int
) -> void:
	var base := vertices.size()
	vertices.append(center)
	normals.append(Vector3.UP)
	for i in range(marker_segments):
		var angle := TAU * float(i) / float(marker_segments)
		vertices.append(center + Vector3(cos(angle) * radius, 0.0, sin(angle) * radius))
		normals.append(Vector3.UP)

	for i in range(marker_segments):
		var next := 1 + ((i + 1) % marker_segments)
		indices.append_array([base, base + 1 + i, base + next])


func _standard_material(color: Color, unshaded: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat


func _grid_start() -> Vector3:
	return origin + Vector3(cell_size, 0.0, cell_size)


func _span() -> float:
	return float(board_size - 1) * cell_size


func _board_center() -> Vector3:
	var start := _grid_start()
	var half := _span() * 0.5
	return Vector3(start.x + half, 0.0, start.z + half)


func _point_position(row: int, col: int, y: float) -> Vector3:
	var start := _grid_start()
	return Vector3(start.x + float(col) * cell_size, y, start.z + float(row) * cell_size)


func _star_points() -> Array[Vector2i]:
	if board_size == 15:
		return [
			Vector2i(3, 3),
			Vector2i(3, 7),
			Vector2i(3, 11),
			Vector2i(7, 3),
			Vector2i(7, 7),
			Vector2i(7, 11),
			Vector2i(11, 3),
			Vector2i(11, 7),
			Vector2i(11, 11),
		]

	var low := int(floor(float(board_size - 1) * 0.25))
	var mid := int(floor(float(board_size - 1) * 0.5))
	var high := int(floor(float(board_size - 1) * 0.75))
	return [
		Vector2i(low, low),
		Vector2i(low, mid),
		Vector2i(low, high),
		Vector2i(mid, low),
		Vector2i(mid, mid),
		Vector2i(mid, high),
		Vector2i(high, low),
		Vector2i(high, mid),
		Vector2i(high, high),
	]
