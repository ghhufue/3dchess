extends Node

const BOARD_SIZE := 15
const BLACK := 1
const WHITE := -1

@export var cell_size := 1.0
@export var origin := Vector3(-0.5, 0.0, -0.5)
@export var board_root_path: NodePath = NodePath("../../BG")
@export var place_sound_path: NodePath = NodePath("../../PlaceSound")
@export var camera_rig_path: NodePath = NodePath("../../CameraRig")

@export var black_piece_y_offset := 0.18
@export var white_piece_y_offset := 0.10

@export var white_tint_enabled := true
@export var white_tint := Color(0.756, 0.451, 1.0, 1.0)

@export var hemisphere_radius := 0.38
@export var hemisphere_rings := 20
@export var hemisphere_segments := 20

@onready var board_root: Node3D = get_node_or_null(board_root_path)
@onready var place_sound: AudioStreamPlayer = get_node_or_null(place_sound_path)
@onready var camera_rig: Node = get_node_or_null(camera_rig_path)

@onready var black_prefabs := [
	preload("res://Models/GLB format/building-archery.glb"),
	preload("res://Models/GLB format/building-cabin.glb"),
	preload("res://Models/GLB format/building-castle.glb"),
	preload("res://Models/GLB format/building-dock.glb"),
	preload("res://Models/GLB format/building-farm.glb"),
	preload("res://Models/GLB format/building-house.glb"),
	preload("res://Models/GLB format/building-market.glb"),
	preload("res://Models/GLB format/building-mill.glb"),
	preload("res://Models/GLB format/building-mine.glb"),
	preload("res://Models/GLB format/building-port.glb"),
	preload("res://Models/GLB format/building-sheep.glb"),
	preload("res://Models/GLB format/building-smelter.glb"),
	preload("res://Models/GLB format/building-tower.glb"),
	preload("res://Models/GLB format/building-village.glb"),
	preload("res://Models/GLB format/building-wall.glb"),
	preload("res://Models/GLB format/building-walls.glb"),
	preload("res://Models/GLB format/building-watermill.glb"),
	preload("res://Models/GLB format/building-wizard-tower.glb"),
]
@onready var white_prefab := preload("res://Models/GLB format/grass-forest.glb")

var piece_nodes := []
var _hemisphere_mesh: ArrayMesh = null
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	reset_board()

func reset_board() -> void:
	for row in piece_nodes:
		for piece in row:
			if is_instance_valid(piece):
				piece.queue_free()

	piece_nodes.clear()
	for r in range(BOARD_SIZE):
		var node_row := []
		for c in range(BOARD_SIZE):
			node_row.append(null)
		piece_nodes.append(node_row)

func world_from_rc(row: int, col: int) -> Vector3:
	var local_pos := Vector3(
		origin.x + col * cell_size,
		origin.y,
		origin.z + row * cell_size
	)
	if board_root == null:
		return local_pos
	return board_root.to_global(local_pos)

func rc_from_world(pos: Vector3) -> Vector2i:
	if board_root == null:
		return Vector2i(-1, -1)

	var local_pos := board_root.to_local(pos)
	var col := int(round((local_pos.x - origin.x) / cell_size))
	var row := int(round((local_pos.z - origin.z) / cell_size))
	return Vector2i(row, col)

func render_move(row: int, col: int, player: int) -> Node3D:
	if not _is_in_bounds(row, col):
		return null
	if piece_nodes[row][col] != null:
		return piece_nodes[row][col]
	if board_root == null:
		return null

	if player == BLACK and is_instance_valid(camera_rig) and camera_rig.has_method("enable_zoom_bgm"):
		camera_rig.enable_zoom_bgm()

	var stone: Node3D
	if Global.use_simple_pieces:
		stone = _create_simple_piece_node(player)
	else:
		var scene := _create_piece_scene(player)
		stone = scene.instantiate() as Node3D
	if stone == null:
		return null

	if player == WHITE and white_tint_enabled and not Global.use_simple_pieces:
		_tint_all_meshes(stone, white_tint)

	var y_offset := black_piece_y_offset if player == BLACK else white_piece_y_offset
	stone.position = board_root.to_local(world_from_rc(row, col)) + Vector3(0, y_offset, 0)

	if player == BLACK:
		stone.rotation.y = _random_y_rotation_60deg()

	board_root.add_child(stone)
	piece_nodes[row][col] = stone

	if is_instance_valid(place_sound):
		place_sound.play()

	stone.scale = Vector3.ZERO
	var tween := create_tween()
	tween.tween_property(stone, "scale", Vector3.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

	return stone

func play_win_animation(win_line: Array[Vector2i]) -> float:
	var per_piece_delay := 0.08
	var up_time := 0.20
	var down_time := 0.20
	var jump_h := 0.55

	for i in range(win_line.size()):
		var rc := win_line[i]
		if not _is_in_bounds(rc.x, rc.y):
			continue

		var stone: Node3D = piece_nodes[rc.x][rc.y]
		if stone == null:
			continue

		var base_y := stone.position.y
		var tw := create_tween()
		tw.tween_property(stone, "position:y", base_y + jump_h, up_time)\
			.set_delay(i * per_piece_delay)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_OUT)
		tw.tween_property(stone, "position:y", base_y, down_time)\
			.set_trans(Tween.TRANS_SINE)\
			.set_ease(Tween.EASE_IN)

	return (win_line.size() - 1) * per_piece_delay + up_time + down_time + 0.15

func _is_in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < BOARD_SIZE and col >= 0 and col < BOARD_SIZE

func _create_piece_scene(player: int) -> PackedScene:
	if player == BLACK:
		if black_prefabs.is_empty():
			return white_prefab
		var index := rng.randi_range(0, black_prefabs.size() - 1)
		return black_prefabs[index]
	return white_prefab

func _build_hemisphere_mesh() -> ArrayMesh:
	var r := hemisphere_radius
	var rings := hemisphere_rings
	var segs := hemisphere_segments

	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in range(rings + 1):
		var v := float(i) / rings
		var phi := v * PI / 2.0
		var y := r * sin(phi)
		var rh := r * cos(phi)
		for j in range(segs + 1):
			var u := float(j) / segs
			var theta := u * 2.0 * PI
			var x := rh * cos(theta)
			var z := rh * sin(theta)
			verts.append(Vector3(x, y, z))
			norms.append(Vector3(x, y, z).normalized())
			uvs.append(Vector2(u, 1.0 - v))

	for i in range(rings):
		for j in range(segs):
			var a := i * (segs + 1) + j
			var b := a + segs + 1
			var c := a + 1
			var d := b + 1
			indices.append_array([c, b, a])
			indices.append_array([d, b, c])

	var center := verts.size()
	verts.append(Vector3.ZERO)
	norms.append(Vector3.DOWN)
	uvs.append(Vector2(0.5, 0.5))

	var first := verts.size()
	for j in range(segs + 1):
		var u := float(j) / segs
		var theta := u * 2.0 * PI
		verts.append(Vector3(r * cos(theta), 0.0, r * sin(theta)))
		norms.append(Vector3.DOWN)
		uvs.append(Vector2(cos(theta) * 0.5 + 0.5, sin(theta) * 0.5 + 0.5))

	for j in range(segs):
		indices.append_array([first + j, first + j + 1, center])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func _create_simple_piece_node(player: int) -> Node3D:
	if _hemisphere_mesh == null:
		_hemisphere_mesh = _build_hemisphere_mesh()

	var stone := Node3D.new()
	stone.name = "SimplePiece"

	var mi := MeshInstance3D.new()
	mi.name = "HemisphereMesh"
	mi.mesh = _hemisphere_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.15) if player == BLACK else Color(0.92, 0.92, 0.92)
	mi.set_surface_override_material(0, mat)

	stone.add_child(mi)
	return stone

func _random_y_rotation_60deg() -> float:
	var step_index := rng.randi_range(0, 5)
	return deg_to_rad(60.0 * step_index)

func _tint_all_meshes(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if mi.mesh != null:
			for i in range(mi.mesh.get_surface_count()):
				var src_mat := mi.get_active_material(i)
				var mat: StandardMaterial3D
				if src_mat is StandardMaterial3D:
					mat = (src_mat as StandardMaterial3D).duplicate()
				else:
					mat = StandardMaterial3D.new()
				mat.albedo_color = tint
				mi.set_surface_override_material(i, mat)

	for c in node.get_children():
		_tint_all_meshes(c, tint)

