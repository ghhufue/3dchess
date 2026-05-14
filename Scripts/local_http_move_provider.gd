extends Node

signal move_ready(row: int, col: int)
signal move_failed(message: String)

@export var endpoint := "http://127.0.0.1:8000/bot_move"

var http := HTTPRequest.new()

func _ready() -> void:
	add_child(http)
	http.request_completed.connect(_on_request_completed)

func request_move(board: Array, current_player: int, bot_name_override := "") -> void:
	var final_bot := bot_name_override
	if final_bot == "":
		final_bot = Global.bot_name

	var payload := {
		"board": board,
		"current_player": current_player,
		"bot_name": final_bot
	}

	if (final_bot == "trained" or final_bot == Global.white_bot_name) and Global.trained_model_path != "":
		payload["model_path"] = Global.trained_model_path

	var headers := ["Content-Type: application/json"]
	var err := http.request(endpoint, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		move_failed.emit("Failed to start local AI request: %s" % err)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS:
		move_failed.emit("Local AI request failed: %s" % result)
		return
	if response_code != 200:
		move_failed.emit("Local AI server returned HTTP %s" % response_code)
		return

	var text := body.get_string_from_utf8()
	var data = JSON.parse_string(text)
	if not data:
		move_failed.emit("Local AI returned invalid JSON")
		return
	if not data.has("row") or not data.has("col"):
		move_failed.emit("Local AI response does not contain row/col")
		return

	move_ready.emit(int(data["row"]), int(data["col"]))

