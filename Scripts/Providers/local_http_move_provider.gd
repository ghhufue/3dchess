extends Node

signal move_ready(row: int, col: int)
signal move_failed(message: String)

const PLAYER_TYPE_BOT := "bot"
const PLAYER_TYPE_MODEL := "model"

@export var bot_bridge_endpoint := "http://127.0.0.1:8001"
@export var model_endpoint := "http://127.0.0.1:8000"

@export_group("Service Startup")
@export var auto_start_services := true
@export var python_command := "python"
@export var startup_poll_attempts := 40
@export var startup_poll_interval := 0.25
@export var request_timeout_sec := 5.0

var _awakened_bots: Dictionary = {}
var _started_services: Dictionary = {}

func warm_up_services(player_types: Array) -> void:
	var service_types := {}
	for player_type in player_types:
		var resolved_type := str(player_type).strip_edges().to_lower()
		if resolved_type == PLAYER_TYPE_BOT:
			service_types[PLAYER_TYPE_BOT] = _trim_trailing_slash(bot_bridge_endpoint)
		elif resolved_type == PLAYER_TYPE_MODEL:
			service_types[PLAYER_TYPE_MODEL] = _trim_trailing_slash(model_endpoint)

	for service_type in service_types.keys():
		await _ensure_service_ready(str(service_type), str(service_types[service_type]))


func request_move(
	board: Array,
	current_player: int,
	player_type := PLAYER_TYPE_BOT,
	player_name := "",
	engine_kind := "",
	engine_path := "",
	engine_args: Array[String] = []
) -> void:
	var resolved_type := str(player_type).strip_edges().to_lower()
	var resolved_name := str(player_name).strip_edges()

	if resolved_type == "":
		resolved_type = PLAYER_TYPE_BOT
	if resolved_name == "":
		resolved_name = Global.bot_name

	match resolved_type:
		PLAYER_TYPE_BOT:
			await _request_bot_move(board, current_player, resolved_name)
		PLAYER_TYPE_MODEL:
			await _request_model_move(
				board,
				current_player,
				resolved_name,
				str(engine_kind).strip_edges(),
				str(engine_path).strip_edges(),
				engine_args
			)
		_:
			move_failed.emit("Unsupported local player type: %s" % resolved_type)


func _request_bot_move(board: Array, current_player: int, bot_name: String) -> void:
	var base_url := _trim_trailing_slash(bot_bridge_endpoint)
	var is_ready: bool = await _ensure_service_ready(PLAYER_TYPE_BOT, base_url)
	if not is_ready:
		return

	var is_awake: bool = await _wake_bot(base_url, bot_name)
	if not is_awake:
		return

	var payload := {
		"board": board,
		"current_player": current_player,
		"bot_name": bot_name
	}
	var data: Dictionary = await _post_json("%s/bot_move" % base_url, payload)
	_emit_move_from_response(data, "Bot bridge")


func _request_model_move(
	board: Array,
	current_player: int,
	engine_name: String,
	engine_kind: String,
	engine_path: String,
	engine_args: Array[String]
) -> void:
	var base_url := _trim_trailing_slash(model_endpoint)
	var is_ready: bool = await _ensure_service_ready(PLAYER_TYPE_MODEL, base_url)
	if not is_ready:
		return

	var payload := {
		"board": board,
		"current_player": current_player,
		"engine_name": engine_name
	}
	if engine_kind != "":
		payload["engine_kind"] = engine_kind
	if engine_path != "":
		payload["engine_path"] = engine_path
	if not engine_args.is_empty():
		payload["engine_args"] = engine_args

	var data: Dictionary = await _post_json("%s/bot_move" % base_url, payload)
	_emit_move_from_response(data, "Local inference service")


func _wake_bot(base_url: String, bot_name: String) -> bool:
	if _awakened_bots.has(bot_name):
		return true

	var data: Dictionary = await _post_json("%s/wake" % base_url, {"bot_name": bot_name})
	if data.is_empty():
		return false

	_awakened_bots[bot_name] = true
	return true


func _ensure_service_ready(service_type: String, base_url: String) -> bool:
	var initially_healthy: bool = await _is_service_healthy(base_url)
	if initially_healthy:
		return true

	if auto_start_services:
		_start_service(service_type)

	for _attempt in range(startup_poll_attempts):
		await get_tree().create_timer(startup_poll_interval).timeout
		var is_healthy: bool = await _is_service_healthy(base_url)
		if is_healthy:
			return true

	move_failed.emit("%s service is not available at %s" % [_service_label(service_type), base_url])
	return false


func _is_service_healthy(base_url: String) -> bool:
	var response: Dictionary = await _request_json("%s/health" % base_url, HTTPClient.METHOD_GET)
	return not response.is_empty() and str(response.get("status", "")) == "ok"


func _start_service(service_type: String) -> void:
	if _started_services.has(service_type):
		return

	_started_services[service_type] = true

	var workspace_root := ProjectSettings.globalize_path("res://..").simplify_path()
	var working_dir := workspace_root
	var args := PackedStringArray()

	match service_type:
		PLAYER_TYPE_BOT:
			working_dir = workspace_root.path_join("gomoku_ai")
			args = PackedStringArray(["-m", "bots.local_http_api"])
		PLAYER_TYPE_MODEL:
			args = PackedStringArray(["-m", "local_inference_service.main"])
		_:
			return

	var log_prefix := "godot_%s_service" % service_type
	_start_hidden_process(working_dir, _resolve_python_command(), args, workspace_root, log_prefix)


func _resolve_python_command() -> String:
	var configured := python_command.strip_edges()
	if configured != "":
		return configured
	return "python"


func _start_hidden_process(
	working_dir: String,
	command: String,
	args: PackedStringArray,
	workspace_root: String,
	log_prefix: String
) -> void:
	var escaped_args := PackedStringArray()
	for arg in args:
		escaped_args.append("'%s'" % _escape_powershell_single_quoted(arg))

	var stdout_path := workspace_root.path_join("%s.out.log" % log_prefix)
	var stderr_path := workspace_root.path_join("%s.err.log" % log_prefix)
	var ps_command := "Start-Process -WindowStyle Hidden -WorkingDirectory '%s' -FilePath '%s' -ArgumentList @(%s) -RedirectStandardOutput '%s' -RedirectStandardError '%s'" % [
		_escape_powershell_single_quoted(working_dir),
		_escape_powershell_single_quoted(command),
		",".join(escaped_args),
		_escape_powershell_single_quoted(stdout_path),
		_escape_powershell_single_quoted(stderr_path)
	]
	var ps_args := PackedStringArray(["-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps_command])
	OS.create_process("powershell", ps_args)


func _post_json(url: String, payload: Dictionary) -> Dictionary:
	return await _request_json(url, HTTPClient.METHOD_POST, payload)


func _request_json(url: String, method: int, payload := {}) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = request_timeout_sec
	add_child(http)

	var body := ""
	var headers := PackedStringArray()
	if method == HTTPClient.METHOD_POST:
		headers = PackedStringArray(["Content-Type: application/json"])
		body = JSON.stringify(payload)

	var err := http.request(url, headers, method, body)
	if err != OK:
		http.queue_free()
		return {}

	var completed: Array = await http.request_completed
	http.queue_free()

	var result := int(completed[0])
	var response_code := int(completed[1])
	var response_body: PackedByteArray = completed[3]
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		return {}

	var text := response_body.get_string_from_utf8()
	var data = JSON.parse_string(text)
	if data is Dictionary:
		return data
	return {}


func _emit_move_from_response(data: Dictionary, source: String) -> void:
	if data.is_empty():
		move_failed.emit("%s returned no usable response" % source)
		return
	if not data.has("row") or not data.has("col"):
		move_failed.emit("%s response does not contain row/col" % source)
		return

	move_ready.emit(int(data["row"]), int(data["col"]))


func _trim_trailing_slash(value: String) -> String:
	var result := value.strip_edges()
	while result.ends_with("/"):
		result = result.substr(0, result.length() - 1)
	return result


func _service_label(service_type: String) -> String:
	return "Bot bridge" if service_type == PLAYER_TYPE_BOT else "Local inference"


func _escape_powershell_single_quoted(value: String) -> String:
	return value.replace("'", "''")
