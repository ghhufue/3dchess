extends Node

signal connected
signal connection_failed(message: String)
signal room_hosted(room_id: String, spectator_id: String)
signal room_created(room_id: String, player_id: String, color: int)
signal room_joined(room_id: String, player_id: String, color: int)
signal match_history(records: Array)
signal game_started(payload: Dictionary)
signal turn_requested(payload: Dictionary)
signal move_result(payload: Dictionary)
signal game_over(payload: Dictionary)
signal server_error(code: String, message: String)

@export var server_url := "ws://127.0.0.1:9000/ws"

var socket := WebSocketPeer.new()
var connected_to_server := false


func _process(_delta: float) -> void:
	socket.poll()
	var state := socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		if not connected_to_server:
			connected_to_server = true
			connected.emit()
		_read_packets()
		return

	if state == WebSocketPeer.STATE_CLOSED and connected_to_server:
		connected_to_server = false


func connect_to_server(url_override := "") -> void:
	var url := server_url if url_override.is_empty() else url_override
	var err := socket.connect_to_url(url)
	if err != OK:
		connection_failed.emit("Failed to connect to match server: %s" % err)


func create_room(player_name: String, model_name: String) -> void:
	_send({
		"type": "create_room",
		"player_name": player_name,
		"model_name": model_name,
		"avatar_index": Global.online_avatar_index,
	})


func host_game(player_name: String) -> void:
	_send({
		"type": "host_game",
		"player_name": player_name,
	})


func join_room(room_id: String, player_name: String, model_name: String) -> void:
	_send({
		"type": "join_room",
		"room_id": room_id,
		"player_name": player_name,
		"model_name": model_name,
		"avatar_index": Global.online_avatar_index,
	})


func request_match_history() -> void:
	_send({
		"type": "match_history",
	})


func send_move(room_id: String, request_id: String, row: int, col: int) -> void:
	_send({
		"type": "move",
		"room_id": room_id,
		"request_id": request_id,
		"row": row,
		"col": col,
		"x": col,
		"y": row,
	})


func _send(payload: Dictionary) -> void:
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		server_error.emit("NOT_CONNECTED", "WebSocket is not connected")
		return

	socket.send_text(JSON.stringify(payload))


func _read_packets() -> void:
	while socket.get_available_packet_count() > 0:
		var text := socket.get_packet().get_string_from_utf8()
		var payload = JSON.parse_string(text)
		if not (payload is Dictionary):
			server_error.emit("INVALID_JSON", "Server sent invalid JSON")
			continue
		_handle_message(payload)


func _handle_message(payload: Dictionary) -> void:
	var message_type := str(payload.get("type", ""))
	match message_type:
		"room_hosted":
			room_hosted.emit(
				str(payload.get("room_id", "")),
				str(payload.get("spectator_id", ""))
			)
		"room_created":
			room_created.emit(
				str(payload.get("room_id", "")),
				str(payload.get("player_id", "")),
				int(payload.get("color", 0))
			)
		"room_joined":
			room_joined.emit(
				str(payload.get("room_id", "")),
				str(payload.get("player_id", "")),
				int(payload.get("color", 0))
			)
		"game_start":
			game_started.emit(payload)
		"your_turn":
			turn_requested.emit(payload)
		"move_result":
			move_result.emit(payload)
		"game_over":
			game_over.emit(payload)
		"match_history":
			var records = payload.get("records", [])
			match_history.emit(records if records is Array else [])
		"error":
			server_error.emit(str(payload.get("code", "")), str(payload.get("message", "")))
		_:
			server_error.emit("UNKNOWN_MESSAGE", "Unsupported server message: %s" % message_type)
