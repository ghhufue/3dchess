extends Node

var http := HTTPRequest.new()
var board_manager: Node = null

func _ready():
	add_child(http)
	http.request_completed.connect(_on_done)

func request_bot_move(board, current_player, bot_name_override := ""):
	print("sending request to bot...")
	board_manager = get_parent().get_node("BoardManager")
	var final_bot = bot_name_override
	if final_bot == "":
		final_bot = Global.bot_name
	var payload = {
		"board": board,
		"current_player": current_player,
		"bot_name": final_bot
	}
	# if trained bot with model_path
	if (final_bot == "trained" or final_bot == Global.white_bot_name) and Global.trained_model_path != "":
		payload["model_path"] = Global.trained_model_path
	var json = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]
	var err = http.request("http://127.0.0.1:8000/bot_move", headers, HTTPClient.METHOD_POST, json)
	print("http.request err =", err)

func _on_done(result, response_code, _headers, body):
	print("http done:", result, response_code)
	var text = body.get_string_from_utf8()
	print("body:", text)

	if result != HTTPRequest.RESULT_SUCCESS:
		print("request failed, result=", result, "code=", response_code)
		return
	if response_code != 200:
		print("server error, code=", response_code)
		return

	var data = JSON.parse_string(text)
	if data and board_manager:
		board_manager.on_ai_move(data["row"], data["col"])
