extends Node

const BOARD_SIZE := 15
const EMPTY := 0
const BLACK := 1
const WHITE := -1

@export var human_vs_bot_delay := 0.5
@export var bot_vs_bot_delay := 0.05
@export var cell_size := 1.0
@export var origin := Vector3(-0.5, 0.0, -0.5) # local space

@export var black_piece_y_offset := 0.18
@export var white_piece_y_offset := 0.10

@export var white_tint_enabled := true
@export var white_tint := Color(0.756, 0.451, 1.0, 1.0)

@export var hemisphere_radius := 0.38
@export var hemisphere_rings := 20
@export var hemisphere_segments := 20

var _hemisphere_mesh: ArrayMesh = null

@onready var place_sound := $"../../PlaceSound"
@onready var bot_label := $"../../UI/BotLabel"
@onready var board_root := $"../../BG"
@onready var ai_client := $"../../Manager/AIClient"
@onready var abort_button := $"../../UI/AbortButton"
@onready var next_step_button := $"../../UI/Button"
@onready var camera_rig := $"../../CameraRig"

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

var board := []
var piece_nodes := []
var current_player := BLACK
var game_over := false
var ai_waiting := false
var pending_ai_player := EMPTY
var rng := RandomNumberGenerator.new()

func _ready():
	rng.randomize()
	_reset_board()
	game_over = false
	ai_waiting = false
	pending_ai_player = EMPTY
	current_player = BLACK

	if is_instance_valid(abort_button):
		abort_button.text = "<—"
		if not abort_button.pressed.is_connected(_on_abort_pressed):
			abort_button.pressed.connect(_on_abort_pressed)

	if is_instance_valid(next_step_button):
		next_step_button.text = "Next Step"
		next_step_button.visible = (Global.game_mode == "bot_vs_bot_step")
		next_step_button.disabled = false
		if not next_step_button.pressed.is_connected(_on_next_step_pressed):
			next_step_button.pressed.connect(_on_next_step_pressed)

	if is_instance_valid(bot_label):
		if Global.game_mode == "bot_vs_bot_step":
			bot_label.text = "Player1: %s  vs  Player2: %s" % [Global.black_bot_name, Global.white_bot_name]
		else:
			var label_text = Global.trained_model_label if Global.bot_name == "trained" else Global.bot_name
			bot_label.text = "Bot: " + label_text

func _on_abort_pressed():
	game_over = true
	ai_waiting = false
	pending_ai_player = EMPTY
	Global.winner_text = "Game aborted"
	get_tree().change_scene_to_file("res://Scenes/3_dtitle.tscn")

func _reset_board():
	board.clear()
	piece_nodes.clear()
	for r in range(BOARD_SIZE):
		var row := []
		var node_row := []
		for c in range(BOARD_SIZE):
			row.append(EMPTY)
			node_row.append(null)
		board.append(row)
		piece_nodes.append(node_row)

func world_from_rc(row:int, col:int) -> Vector3:
	var local_pos = Vector3(
		origin.x + col * cell_size,
		origin.y,
		origin.z + row * cell_size
	)
	return board_root.to_global(local_pos)

func rc_from_world(pos: Vector3) -> Vector2i:
	var local_pos = board_root.to_local(pos)
	var col = int(round((local_pos.x - origin.x) / cell_size))
	var row = int(round((local_pos.z - origin.z) / cell_size))
	return Vector2i(row, col)

func _create_piece_scene(player:int) -> PackedScene:
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

	# dome: equator (y=0) up to pole (y=r)
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

	# flat bottom cap
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

func place_piece(row:int, col:int, player:int):
	if board[row][col] != EMPTY:
		return
	board[row][col] = player

	if player == BLACK and is_instance_valid(camera_rig):
		camera_rig.enable_zoom_bgm()

	var stone: Node3D
	if Global.use_simple_pieces:
		stone = _create_simple_piece_node(player)
	else:
		var scene := _create_piece_scene(player)
		stone = scene.instantiate() as Node3D
	if stone == null:
		return

	# 白棋染色（简单棋子模式跳过）
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
	var tween = create_tween()
	tween.tween_property(stone, "scale", Vector3.ONE, 0.3)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func check_win(row:int, col:int, player:int) -> bool:
	var dirs = [
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(1, -1)
	]
	for d in dirs:
		var count = 1

		var r = row + d.y
		var c = col + d.x
		while r >= 0 and r < BOARD_SIZE and c >= 0 and c < BOARD_SIZE and board[r][c] == player:
			count += 1
			r += d.y
			c += d.x

		r = row - d.y
		c = col - d.x
		while r >= 0 and r < BOARD_SIZE and c >= 0 and c < BOARD_SIZE and board[r][c] == player:
			count += 1
			r -= d.y
			c -= d.x

		if count >= 5:
			return true
	return false

func _find_win_line(row:int, col:int, player:int) -> Array[Vector2i]:
	var dirs = [
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(1, -1)
	]

	for d in dirs:
		var line: Array[Vector2i] = []
		line.append(Vector2i(row, col))

		var r = row + d.y
		var c = col + d.x
		while r >= 0 and r < BOARD_SIZE and c >= 0 and c < BOARD_SIZE and board[r][c] == player:
			line.append(Vector2i(r, c))
			r += d.y
			c += d.x

		r = row - d.y
		c = col - d.x
		while r >= 0 and r < BOARD_SIZE and c >= 0 and c < BOARD_SIZE and board[r][c] == player:
			line.push_front(Vector2i(r, c))
			r -= d.y
			c -= d.x

		if line.size() >= 5:
			return line.slice(0, 5)

	return []

func _play_win_line_bounce(win_line: Array[Vector2i]) -> float:
	var per_piece_delay := 0.08
	var up_time := 0.20
	var down_time := 0.20
	var jump_h := 0.55

	for i in range(win_line.size()):
		var rc := win_line[i]
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
	
func _end_game_with_animation(text:String, win_line: Array[Vector2i]) -> void:
	game_over = true
	ai_waiting = false
	pending_ai_player = EMPTY

	if win_line.size() >= 5:
		var total_wait := _play_win_line_bounce(win_line)
		await get_tree().create_timer(total_wait).timeout

	Global.winner_text = text
	get_tree().change_scene_to_file("res://Scenes/3_dtitle.tscn")

func _is_board_full() -> bool:
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			if board[r][c] == EMPTY:
				return false
	return true

func _bot_name_for_player(player:int) -> String:
	return Global.black_bot_name if player == BLACK else Global.white_bot_name

func _request_ai_for_current_player(bot_name_override := ""):
	if game_over or ai_waiting:
		return
	ai_waiting = true
	pending_ai_player = current_player

	var delay := human_vs_bot_delay
	if Global.game_mode == "bot_vs_bot_step":
		delay = bot_vs_bot_delay

	if delay > 0.0:
		await get_tree().create_timer(delay).timeout

	if game_over:
		ai_waiting = false
		pending_ai_player = EMPTY
		return

	ai_client.request_bot_move(board, current_player, bot_name_override)

func _end_game(text:String):
	game_over = true
	ai_waiting = false
	pending_ai_player = EMPTY
	Global.winner_text = text
	get_tree().change_scene_to_file("res://Scenes/3_dtitle.tscn")

func on_player_click(row:int, col:int):
	if game_over:
		return

	if Global.game_mode == "bot_vs_bot_step":
		return

	if current_player != BLACK:
		return
	if board[row][col] != EMPTY:
		return

	place_piece(row, col, BLACK)

	var win_line := _find_win_line(row, col, BLACK)
	if win_line.size() >= 5:
		await _end_game_with_animation("Player win", win_line)
		return

	if _is_board_full():
		_end_game("Draw")
		return

	current_player = WHITE
	_request_ai_for_current_player()

func _on_next_step_pressed():
	if Global.game_mode != "bot_vs_bot_step":
		return
	if game_over or ai_waiting:
		return

	var bot_name := _bot_name_for_player(current_player)
	_request_ai_for_current_player(bot_name)

func on_ai_move(row:int, col:int):
	if game_over:
		return

	ai_waiting = false
	var player := pending_ai_player
	if player == EMPTY:
		player = current_player
	pending_ai_player = EMPTY

	if row < 0 or row >= BOARD_SIZE or col < 0 or col >= BOARD_SIZE:
		return
	if board[row][col] != EMPTY:
		return

	place_piece(row, col, player)

	var win_line := _find_win_line(row, col, player)
	if win_line.size() >= 5:
		if Global.game_mode == "bot_vs_bot_step":
			var winner_bot := _bot_name_for_player(player)
			await _end_game_with_animation("%s win" % winner_bot, win_line)
		else:
			if player == BLACK:
				await _end_game_with_animation("Player win", win_line)
			else:
				await _end_game_with_animation("PC win", win_line)
		return

	if _is_board_full():
		_end_game("Draw")
		return

	current_player = -player
