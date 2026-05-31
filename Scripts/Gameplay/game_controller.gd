extends Node

const BOARD_SIZE := 15
const EMPTY := 0
const BLACK := 1
const WHITE := -1

@export var human_vs_bot_delay := 0.5
@export var bot_vs_bot_delay := 0.05

@export var board_view_path: NodePath = NodePath("../BoardView")
@export var board_input_path: NodePath = NodePath("../../BoardInput")
@export var local_move_provider_path: NodePath = NodePath("../LocalHttpMoveProvider")
@export var online_match_client_path: NodePath = NodePath("../OnlineMatchClient")
@export var bot_label_path: NodePath = NodePath("../../UI/BotLabel")
@export var abort_button_path: NodePath = NodePath("../../UI/AbortButton")
@export var next_step_button_path: NodePath = NodePath("../../UI/Button")
@export var title_scene_path := "res://Scenes/3_dtitle.tscn"
@export var online_result_scene_path := "res://Scenes/OnlineResult.tscn"

@onready var board_view: Node = get_node_or_null(board_view_path)
@onready var board_input: Node = get_node_or_null(board_input_path)
@onready var local_move_provider: Node = get_node_or_null(local_move_provider_path)
@onready var online_match_client: Node = get_node_or_null(online_match_client_path)
@onready var bot_label: Label = get_node_or_null(bot_label_path)
@onready var abort_button: Button = get_node_or_null(abort_button_path)
@onready var next_step_button: Button = get_node_or_null(next_step_button_path)

var board := []
var current_player := BLACK
var game_over := false
var ai_waiting := false
var pending_ai_player := EMPTY
var pending_online_request_id := ""
var pending_online_room_id := ""

func _ready() -> void:
	if Global.game_mode == "online_model_vs_model":
		online_match_client = Global.get_online_match_client()
	_reset_game()
	_connect_nodes()
	_configure_ui()
	call_deferred("_warm_up_local_services")

func _reset_game() -> void:
	board.clear()
	for r in range(BOARD_SIZE):
		var row := []
		for c in range(BOARD_SIZE):
			row.append(EMPTY)
		board.append(row)

	current_player = BLACK
	game_over = false
	ai_waiting = false
	pending_ai_player = EMPTY

	if board_view != null and board_view.has_method("reset_board"):
		board_view.reset_board()

func _connect_nodes() -> void:
	if board_input != null and board_input.has_signal("cell_clicked"):
		if not board_input.cell_clicked.is_connected(_on_cell_clicked):
			board_input.cell_clicked.connect(_on_cell_clicked)

	if local_move_provider != null:
		if local_move_provider.has_signal("move_ready") and not local_move_provider.move_ready.is_connected(_on_provider_move_ready):
			local_move_provider.move_ready.connect(_on_provider_move_ready)
		if local_move_provider.has_signal("move_failed") and not local_move_provider.move_failed.is_connected(_on_provider_move_failed):
			local_move_provider.move_failed.connect(_on_provider_move_failed)

	if online_match_client != null:
		if online_match_client.has_signal("connected") and not online_match_client.connected.is_connected(_on_online_connected):
			online_match_client.connected.connect(_on_online_connected)
		if online_match_client.has_signal("room_hosted") and not online_match_client.room_hosted.is_connected(_on_online_room_hosted):
			online_match_client.room_hosted.connect(_on_online_room_hosted)
		if online_match_client.has_signal("room_created") and not online_match_client.room_created.is_connected(_on_online_room_ready):
			online_match_client.room_created.connect(_on_online_room_ready)
		if online_match_client.has_signal("room_joined") and not online_match_client.room_joined.is_connected(_on_online_room_ready):
			online_match_client.room_joined.connect(_on_online_room_ready)
		if online_match_client.has_signal("game_started") and not online_match_client.game_started.is_connected(_on_online_game_started):
			online_match_client.game_started.connect(_on_online_game_started)
		if online_match_client.has_signal("turn_requested") and not online_match_client.turn_requested.is_connected(_on_online_turn_requested):
			online_match_client.turn_requested.connect(_on_online_turn_requested)
		if online_match_client.has_signal("move_result") and not online_match_client.move_result.is_connected(_on_online_move_result):
			online_match_client.move_result.connect(_on_online_move_result)
		if online_match_client.has_signal("game_over") and not online_match_client.game_over.is_connected(_on_online_game_over):
			online_match_client.game_over.connect(_on_online_game_over)
		if online_match_client.has_signal("server_error") and not online_match_client.server_error.is_connected(_on_online_server_error):
			online_match_client.server_error.connect(_on_online_server_error)

	if is_instance_valid(abort_button) and not abort_button.pressed.is_connected(_on_abort_pressed):
		abort_button.pressed.connect(_on_abort_pressed)

	if is_instance_valid(next_step_button) and not next_step_button.pressed.is_connected(_on_next_step_pressed):
		next_step_button.pressed.connect(_on_next_step_pressed)

func _configure_ui() -> void:
	if is_instance_valid(abort_button):
		abort_button.text = "<"

	if is_instance_valid(next_step_button):
		next_step_button.text = "Next Step"
		next_step_button.visible = (Global.game_mode == "bot_vs_bot_step")
		next_step_button.disabled = false

	if is_instance_valid(bot_label):
		if Global.game_mode == "online_model_vs_model":
			bot_label.text = "Online: connecting..."
		elif Global.game_mode == "bot_vs_bot_step":
			bot_label.text = "Black: %s  vs  White: %s" % [
				_player_label_for(BLACK),
				_player_label_for(WHITE),
			]
		else:
			bot_label.text = "Black: %s  vs  White: %s" % [
				_player_label_for(BLACK),
				_player_label_for(WHITE),
			]

	if Global.game_mode == "online_model_vs_model":
		_start_online_match()


func _warm_up_local_services() -> void:
	if Global.game_mode == "online_model_vs_model":
		return
	if local_move_provider == null or not local_move_provider.has_method("warm_up_services"):
		return

	await local_move_provider.warm_up_services([
		_player_type_for_player(BLACK),
		_player_type_for_player(WHITE),
	])

func _on_abort_pressed() -> void:
	_end_game("Game aborted")

func _on_cell_clicked(row: int, col: int) -> void:
	if game_over or ai_waiting:
		return
	if Global.game_mode == "online_model_vs_model":
		return
	if _player_type_for_player(current_player) != "human":
		return

	var player := current_player
	call_deferred("_handle_human_cell_clicked", row, col, player)


func _handle_human_cell_clicked(row: int, col: int, player: int) -> void:
	if game_over or ai_waiting:
		return
	if player != current_player:
		return
	if _player_type_for_player(player) != "human":
		return

	_try_apply_move(row, col, player)

	if not game_over:
		current_player = -player
		await _request_local_player_for_current_player()

func _on_next_step_pressed() -> void:
	if Global.game_mode != "bot_vs_bot_step":
		return
	if game_over or ai_waiting:
		return

	if _player_type_for_player(current_player) == "human":
		return

	call_deferred("_request_local_player_for_current_player")

func _request_local_player_for_current_player() -> void:
	if game_over or ai_waiting:
		return
	if local_move_provider == null or not local_move_provider.has_method("request_move"):
		_on_provider_move_failed("No local move provider is configured")
		return

	var player_type := _player_type_for_player(current_player)
	if player_type == "human":
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

	await local_move_provider.request_move(
		board,
		current_player,
		player_type,
		_player_name_for_player(current_player),
		_engine_kind_for_player(current_player),
		_engine_path_for_player(current_player),
		_engine_args_for_player(current_player)
	)

func _on_provider_move_ready(row: int, col: int) -> void:
	if game_over:
		return

	ai_waiting = false
	if Global.game_mode == "online_model_vs_model":
		if online_match_client != null and online_match_client.has_method("send_move"):
			online_match_client.send_move(pending_online_room_id, pending_online_request_id, row, col)
		pending_online_request_id = ""
		pending_online_room_id = ""
		pending_ai_player = EMPTY
		return

	var player := pending_ai_player
	if player == EMPTY:
		player = current_player
	pending_ai_player = EMPTY

	_try_apply_move(row, col, player)
	if not game_over:
		current_player = -player

func _on_provider_move_failed(message: String) -> void:
	ai_waiting = false
	pending_ai_player = EMPTY
	pending_online_request_id = ""
	pending_online_room_id = ""
	push_warning(message)

func _try_apply_move(row: int, col: int, player: int) -> void:
	if not _is_in_bounds(row, col):
		return
	if board[row][col] != EMPTY:
		return

	board[row][col] = player
	if board_view != null and board_view.has_method("render_move"):
		board_view.render_move(row, col, player)

	var win_line := _find_win_line(row, col, player)
	if win_line.size() >= 5:
		await _end_game_with_animation(_winner_text_for(player), win_line)
		return

	if _is_board_full():
		_end_game("Draw")

func _find_win_line(row: int, col: int, player: int) -> Array[Vector2i]:
	var dirs: Array[Vector2i] = [
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(1, 1),
		Vector2i(1, -1)
	]

	for d: Vector2i in dirs:
		var line: Array[Vector2i] = []
		line.append(Vector2i(row, col))

		var r: int = row + d.y
		var c: int = col + d.x
		while _is_in_bounds(r, c) and board[r][c] == player:
			line.append(Vector2i(r, c))
			r += d.y
			c += d.x

		r = row - d.y
		c = col - d.x
		while _is_in_bounds(r, c) and board[r][c] == player:
			line.push_front(Vector2i(r, c))
			r -= d.y
			c -= d.x

		if line.size() >= 5:
			return line.slice(0, 5)

	return []

func _is_board_full() -> bool:
	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			if board[r][c] == EMPTY:
				return false
	return true

func _is_in_bounds(row: int, col: int) -> bool:
	return row >= 0 and row < BOARD_SIZE and col >= 0 and col < BOARD_SIZE

func _bot_name_for_player(player: int) -> String:
	return _player_name_for_player(player)

func _player_type_for_player(player: int) -> String:
	var value: String = Global.black_player_type if player == BLACK else Global.white_player_type
	value = str(value).strip_edges().to_lower()
	if value in ["human", "bot", "model"]:
		return value
	return "human"

func _player_name_for_player(player: int) -> String:
	var value: String = Global.black_player_name if player == BLACK else Global.white_player_name
	value = str(value).strip_edges()
	if value != "":
		return value

	if player == BLACK:
		return Global.black_bot_name
	return Global.white_bot_name

func _engine_kind_for_player(player: int) -> String:
	return Global.black_engine_kind if player == BLACK else Global.white_engine_kind

func _engine_path_for_player(player: int) -> String:
	return Global.black_engine_path if player == BLACK else Global.white_engine_path

func _engine_args_for_player(player: int) -> Array[String]:
	return Global.black_engine_args if player == BLACK else Global.white_engine_args

func _player_label_for(player: int) -> String:
	var player_type := _player_type_for_player(player)
	var player_name := _player_name_for_player(player)
	if player_type == "human":
		return "Human"
	return "%s:%s" % [player_type.capitalize(), player_name]

func _winner_text_for(player: int) -> String:
	if Global.game_mode == "bot_vs_bot_step":
		return "%s win" % _player_label_for(player)
	if player == BLACK:
		return "Player win"
	return "PC win"

func _end_game_with_animation(text: String, win_line: Array[Vector2i]) -> void:
	game_over = true
	ai_waiting = false
	pending_ai_player = EMPTY

	if board_view != null and board_view.has_method("play_win_animation") and win_line.size() >= 5:
		var total_wait: float = board_view.play_win_animation(win_line)
		await get_tree().create_timer(total_wait).timeout

	_end_game(text)

func _end_game(text: String) -> void:
	game_over = true
	ai_waiting = false
	pending_ai_player = EMPTY
	Global.winner_text = text
	get_tree().change_scene_to_file(title_scene_path)


func _start_online_match() -> void:
	if online_match_client == null or not online_match_client.has_method("connect_to_server"):
		_on_online_server_error("NO_CLIENT", "No online match client is configured")
		return

	if online_match_client.has_method("is_connected_to_server") and online_match_client.is_connected_to_server() and Global.online_room_id != "":
		_resume_online_lobby_match()
		return

	online_match_client.connect_to_server(Global.match_server_url)


func _resume_online_lobby_match() -> void:
	if is_instance_valid(bot_label):
		bot_label.text = "Online room %s" % Global.online_room_id

	if not Global.online_pending_game_start.is_empty():
		_on_online_game_started(Global.online_pending_game_start)
		Global.online_pending_game_start = {}

	if not Global.online_pending_turn.is_empty():
		_on_online_turn_requested(Global.online_pending_turn)
		Global.online_pending_turn = {}


func _on_online_connected() -> void:
	if online_match_client == null:
		return

	if Global.online_spectator or Global.online_entry_action == "host":
		online_match_client.host_game(Global.online_player_name)
	elif Global.online_create_room:
		online_match_client.create_room(Global.online_player_name, Global.online_model_name)
	else:
		online_match_client.join_room(Global.online_join_room_id, Global.online_player_name, Global.online_model_name)


func _on_online_room_hosted(room_id: String, spectator_id: String) -> void:
	Global.online_room_id = room_id
	Global.online_player_id = spectator_id
	Global.online_player_color = EMPTY
	Global.online_spectator = true

	if is_instance_valid(bot_label):
		bot_label.text = "Host room %s  waiting for players..." % room_id


func _on_online_room_ready(room_id: String, player_id: String, color: int) -> void:
	Global.online_room_id = room_id
	Global.online_player_id = player_id
	Global.online_player_color = color

	if is_instance_valid(bot_label):
		var color_name := "Black" if color == BLACK else "White"
		bot_label.text = "Room %s  %s  waiting..." % [room_id, color_name]


func _on_online_game_started(payload: Dictionary) -> void:
	_load_board_from_server(payload.get("board", []))
	current_player = int(payload.get("current_turn", BLACK))
	game_over = false
	Global.online_result = {
		"room_id": str(payload.get("room_id", Global.online_room_id)),
		"black_player": str(payload.get("black_player", "Black")),
		"white_player": str(payload.get("white_player", "White")),
		"black_model": str(payload.get("black_model", "")),
		"white_model": str(payload.get("white_model", "")),
		"local_color": Global.online_player_color,
		"winner": EMPTY,
	}
	_update_online_opponent_from_payload(payload)

	if is_instance_valid(bot_label):
		bot_label.text = _online_match_label(payload)


func _update_online_opponent_from_payload(payload: Dictionary) -> void:
	var black_name := str(payload.get("black_player", ""))
	var white_name := str(payload.get("white_player", ""))
	var black_avatar := int(payload.get("black_avatar_index", 0))
	var white_avatar := int(payload.get("white_avatar_index", 0))

	if Global.online_player_color == BLACK:
		Global.online_opponent_name = white_name
		Global.online_opponent_avatar_index = white_avatar
	elif Global.online_player_color == WHITE:
		Global.online_opponent_name = black_name
		Global.online_opponent_avatar_index = black_avatar
	else:
		Global.online_opponent_name = "%s vs %s" % [black_name, white_name]
		Global.online_opponent_avatar_index = black_avatar


func _online_match_label(payload: Dictionary) -> String:
	var black_name := str(payload.get("black_player", "Black"))
	var white_name := str(payload.get("white_player", "White"))
	var black_model := str(payload.get("black_model", ""))
	var white_model := str(payload.get("white_model", ""))
	return "BLACK %s%s  vs  WHITE %s%s" % [
		black_name,
		_model_suffix(black_model),
		white_name,
		_model_suffix(white_model),
	]


func _model_suffix(model_name: String) -> String:
	var clean_name := model_name.strip_edges()
	if clean_name == "":
		return ""
	return " [%s]" % clean_name


func _on_online_turn_requested(payload: Dictionary) -> void:
	if game_over or ai_waiting:
		return
	if Global.online_spectator:
		return

	var turn_player := int(payload.get("player", EMPTY))
	if turn_player != Global.online_player_color:
		return

	board = payload.get("board", board)
	current_player = turn_player
	pending_ai_player = turn_player
	pending_online_request_id = str(payload.get("request_id", ""))
	pending_online_room_id = str(payload.get("room_id", Global.online_room_id))

	if local_move_provider != null and local_move_provider.has_method("request_move"):
		ai_waiting = true
		await local_move_provider.request_move(
			board,
			current_player,
			"model",
			Global.online_model_name,
			Global.online_engine_kind,
			Global.online_engine_path,
			Global.online_engine_args
		)
	else:
		_on_provider_move_failed("No local move provider is configured")


func _on_online_move_result(payload: Dictionary) -> void:
	var row := int(payload.get("row", payload.get("y", -1)))
	var col := int(payload.get("col", payload.get("x", -1)))
	var player := int(payload.get("player", EMPTY))
	if _is_in_bounds(row, col) and board[row][col] == EMPTY:
		board[row][col] = player
		if board_view != null and board_view.has_method("render_move"):
			board_view.render_move(row, col, player)

	current_player = int(payload.get("next_turn", -player))


func _on_online_game_over(payload: Dictionary) -> void:
	var winner := int(payload.get("winner", EMPTY))
	_store_online_result(winner, payload)
	get_tree().change_scene_to_file(online_result_scene_path)


func _store_online_result(winner: int, payload: Dictionary) -> void:
	var result: Dictionary = Global.online_result.duplicate()
	result["winner"] = winner
	result["reason"] = str(payload.get("reason", ""))
	result["local_color"] = Global.online_player_color
	if not result.has("room_id"):
		result["room_id"] = Global.online_room_id
	if not result.has("black_player"):
		result["black_player"] = "Black"
	if not result.has("white_player"):
		result["white_player"] = "White"
	if not result.has("black_model"):
		result["black_model"] = ""
	if not result.has("white_model"):
		result["white_model"] = ""
	Global.online_result = result


func _on_online_server_error(code: String, message: String) -> void:
	push_warning("[%s] %s" % [code, message])


func _load_board_from_server(server_board) -> void:
	if not (server_board is Array):
		return

	board.clear()
	for r in range(BOARD_SIZE):
		var row := []
		for c in range(BOARD_SIZE):
			var value := EMPTY
			if r < server_board.size() and server_board[r] is Array and c < server_board[r].size():
				value = int(server_board[r][c])
			row.append(value)
		board.append(row)

	if board_view != null and board_view.has_method("reset_board"):
		board_view.reset_board()

	for r in range(BOARD_SIZE):
		for c in range(BOARD_SIZE):
			if board[r][c] != EMPTY and board_view != null and board_view.has_method("render_move"):
				board_view.render_move(r, c, board[r][c])
