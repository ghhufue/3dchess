extends Control

@export_file("*.tscn") var setup_scene_path := "res://Scenes/OnlinePlayerSetup.tscn"
@export_file("*.tscn") var game_scene_path := "res://Scenes/game.tscn"

@onready var room_label: Label = get_node_or_null("RoomLabel")
@onready var player_label: Label = get_node_or_null("PlayerLabel")
@onready var ready_label: Label = get_node_or_null("ReadyLabel")
@onready var model_name_input: LineEdit = get_node_or_null("ModelPanel/VBox/ModelNameInput")
@onready var model_path_label: Label = get_node_or_null("ModelPanel/VBox/ModelPathLabel")
@onready var select_model_button: Button = get_node_or_null("ModelPanel/VBox/SelectModelButton")
@onready var status_label: Label = get_node_or_null("StatusLabel")
@onready var start_button: Button = get_node_or_null("StartButton")
@onready var back_button: Button = get_node_or_null("BackButton")
@onready var file_dialog: FileDialog = get_node_or_null("FileDialog")

var online_client: Node = null
var local_ready := false
var all_ready := false


func _ready() -> void:
	online_client = Global.get_online_match_client()
	_configure_initial_values()
	_connect_controls()
	_connect_online_client()
	_apply_pending_state()


func _configure_initial_values() -> void:
	local_ready = not _requires_local_model()
	if is_instance_valid(room_label):
		room_label.text = "ROOM %s" % Global.online_room_id
	if is_instance_valid(player_label):
		if Global.online_spectator:
			player_label.text = "HOST  %s" % Global.online_player_name
		else:
			player_label.text = "%s  %s" % [_color_name(Global.online_player_color), Global.online_player_name]
	if is_instance_valid(model_name_input):
		model_name_input.text = Global.online_model_name if Global.online_model_name != "" else "trained"
		model_name_input.editable = _requires_local_model()
	if is_instance_valid(model_path_label):
		model_path_label.text = _model_path_text()
	if is_instance_valid(select_model_button):
		select_model_button.disabled = not _requires_local_model()
	if is_instance_valid(status_label):
		status_label.text = "Waiting for both players to select models." if Global.online_spectator else "Select your local model, then press START."
	if is_instance_valid(start_button):
		start_button.text = "READY" if Global.online_spectator else "START"
		start_button.disabled = Global.online_spectator
	if is_instance_valid(back_button):
		back_button.text = "< BACK"
	if is_instance_valid(file_dialog):
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.filters = PackedStringArray([
			"*.py ; Python MoveEngine",
			"*.exe,*.bat,*.cmd ; Executable MoveEngine",
			"*.pt ; gomoku_ai checkpoint",
		])


func _connect_controls() -> void:
	if is_instance_valid(select_model_button) and not select_model_button.pressed.is_connected(_on_select_model_pressed):
		select_model_button.pressed.connect(_on_select_model_pressed)
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(back_button) and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if is_instance_valid(file_dialog) and not file_dialog.file_selected.is_connected(_on_model_file_selected):
		file_dialog.file_selected.connect(_on_model_file_selected)


func _connect_online_client() -> void:
	if online_client == null:
		return
	if online_client.has_signal("room_state") and not online_client.room_state.is_connected(_on_room_state):
		online_client.room_state.connect(_on_room_state)
	if online_client.has_signal("game_started") and not online_client.game_started.is_connected(_on_game_started):
		online_client.game_started.connect(_on_game_started)
	if online_client.has_signal("turn_requested") and not online_client.turn_requested.is_connected(_on_turn_requested):
		online_client.turn_requested.connect(_on_turn_requested)
	if online_client.has_signal("server_error") and not online_client.server_error.is_connected(_on_server_error):
		online_client.server_error.connect(_on_server_error)


func _apply_pending_state() -> void:
	if not Global.online_pending_room_state.is_empty():
		_on_room_state(Global.online_pending_room_state)


func _on_select_model_pressed() -> void:
	if is_instance_valid(file_dialog):
		file_dialog.popup_centered_ratio(0.72)


func _on_model_file_selected(path: String) -> void:
	Global.online_engine_path = path
	Global.online_engine_kind = _infer_engine_kind(path)
	Global.online_engine_args.clear()
	Global.online_model_name = path.get_file().get_basename()
	if is_instance_valid(model_name_input):
		model_name_input.text = Global.online_model_name
	if is_instance_valid(model_path_label):
		model_path_label.text = _model_path_text()
	if is_instance_valid(status_label):
		status_label.text = "Model selected. Press START to ready."


func _on_start_pressed() -> void:
	if _requires_local_model() and not local_ready:
		_submit_model_ready()
		return

	if not _can_start_match():
		_set_status("Waiting for the room creator to start.")
		return
	if not all_ready:
		_set_status("Waiting for both players to select models.")
		return

	if is_instance_valid(start_button):
		start_button.disabled = true
		start_button.text = "WAIT"
	_set_status("Starting match...")
	online_client.start_game(Global.online_room_id)


func _submit_model_ready() -> void:
	var model_name: String = model_name_input.text.strip_edges() if is_instance_valid(model_name_input) else Global.online_model_name
	if model_name == "":
		_set_status("Enter or select a model before starting.")
		return

	Global.online_model_name = model_name
	local_ready = true
	if is_instance_valid(start_button):
		start_button.disabled = true
		start_button.text = "READY"
	_set_status("Model ready. Waiting for the other player.")
	online_client.select_model(Global.online_room_id, Global.online_model_name)


func _on_room_state(payload: Dictionary) -> void:
	Global.online_pending_room_state = payload
	var black_ready := bool(payload.get("black_model_ready", false))
	var white_ready := bool(payload.get("white_model_ready", false))
	all_ready = bool(payload.get("all_models_ready", false))

	if Global.online_player_color == 1:
		local_ready = black_ready
	elif Global.online_player_color == -1:
		local_ready = white_ready

	if is_instance_valid(ready_label):
		ready_label.text = "BLACK %s    WHITE %s" % [
			"READY" if black_ready else "WAIT",
			"READY" if white_ready else "WAIT",
		]

	if all_ready:
		if _can_start_match():
			_set_status("Both models are ready. Press START to begin.")
			if is_instance_valid(start_button):
				start_button.disabled = false
				start_button.text = "START"
		else:
			_set_status("Both models are ready. Waiting for host to start.")
			if is_instance_valid(start_button):
				start_button.disabled = true
				start_button.text = "READY"
	elif local_ready:
		_set_status("Model ready. Waiting for the other player." if _requires_local_model() else "Waiting for both players to select models.")
		if is_instance_valid(start_button):
			start_button.disabled = true
			start_button.text = "READY"


func _on_game_started(payload: Dictionary) -> void:
	Global.online_pending_game_start = payload
	get_tree().change_scene_to_file(game_scene_path)


func _on_turn_requested(payload: Dictionary) -> void:
	Global.online_pending_turn = payload


func _on_server_error(code: String, message: String) -> void:
	if is_instance_valid(start_button) and local_ready and _can_start_match():
		start_button.disabled = false
		start_button.text = "START"
	_set_status("[%s] %s" % [code, message])


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(setup_scene_path)


func _model_path_text() -> String:
	if Global.online_engine_path == "":
		return "Using model name only. Select a Python script, executable, or .pt checkpoint for a local engine."
	return "%s\n%s" % [Global.online_engine_kind, Global.online_engine_path]


func _infer_engine_kind(path: String) -> String:
	var ext := path.get_extension().to_lower()
	match ext:
		"py":
			return "python_script"
		"pt":
			return "gomoku_ai_checkpoint"
		"exe", "bat", "cmd":
			return "executable"
		_:
			return "executable"


func _can_start_match() -> bool:
	return Global.online_entry_action == "host" or (Global.online_entry_action != "join" and not Global.online_spectator)


func _requires_local_model() -> bool:
	return not Global.online_spectator


func _color_name(color: int) -> String:
	return "BLACK" if color == 1 else "WHITE"


func _set_status(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value
