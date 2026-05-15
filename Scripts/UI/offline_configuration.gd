extends Control

@export_file("*.tscn") var game_scene_path := "res://Scenes/game.tscn"
@export_file("*.tscn") var mode_select_scene_path := "res://Scenes/OfflineModeSelect.tscn"
@export var bot_bridge_endpoint := "http://127.0.0.1:8001"

@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var mode_label: Label = get_node_or_null("ModeLabel")
@onready var bot_panel_title: Label = get_node_or_null("BotPanel/Title")
@onready var bot_list: ItemList = get_node_or_null("BotPanel/BotList")
@onready var bot_status_label: Label = get_node_or_null("BotPanel/StatusLabel")
@onready var model_panel_title: Label = get_node_or_null("ModelPanel/Title")
@onready var model_path_label: Label = get_node_or_null("ModelPanel/ModelPathLabel")
@onready var select_model_button: Button = get_node_or_null("ModelPanel/SelectModelButton")
@onready var status_label: Label = get_node_or_null("StatusLabel")
@onready var start_button: Button = get_node_or_null("StartButton")
@onready var back_button: Button = get_node_or_null("BackButton")
@onready var file_dialog: FileDialog = get_node_or_null("FileDialog")

var fallback_bots: Array[String] = [
	"random",
	"classic_rule",
	"reward_driven_medium",
	"reward_driven_hard",
]
var available_bots: Array[String] = []
var selected_bot_name := ""
var selected_model_path := ""
var selected_model_kind := ""
var bot_player := 0
var model_player := 0
var bot_list_request: HTTPRequest


func _ready() -> void:
	_detect_required_players()
	_configure_static_text()
	_configure_connections()
	_configure_file_dialog()
	_apply_mode_visibility()
	_load_bot_list()
	_update_start_state()


func _detect_required_players() -> void:
	bot_player = _find_player_of_type("bot")
	model_player = _find_player_of_type("model")


func _find_player_of_type(player_type: String) -> int:
	if Global.black_player_type == player_type:
		return 1
	if Global.white_player_type == player_type:
		return -1
	return 0


func _configure_static_text() -> void:
	if is_instance_valid(title_label):
		title_label.text = "OFFLINE CONFIGURATION"
	if is_instance_valid(mode_label):
		mode_label.text = _mode_summary()
	if is_instance_valid(bot_panel_title):
		bot_panel_title.text = "BOT TYPE"
	if is_instance_valid(model_panel_title):
		model_panel_title.text = "MODEL / ENGINE FILE"
	if is_instance_valid(select_model_button):
		select_model_button.text = "SELECT PY / EXE / PT"
	if is_instance_valid(start_button):
		start_button.text = "START"
	if is_instance_valid(back_button):
		back_button.text = "< BACK"


func _configure_connections() -> void:
	if is_instance_valid(bot_list) and not bot_list.item_selected.is_connected(_on_bot_selected):
		bot_list.item_selected.connect(_on_bot_selected)
	if is_instance_valid(select_model_button) and not select_model_button.pressed.is_connected(_on_select_model_pressed):
		select_model_button.pressed.connect(_on_select_model_pressed)
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(back_button) and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if is_instance_valid(file_dialog) and not file_dialog.file_selected.is_connected(_on_model_file_selected):
		file_dialog.file_selected.connect(_on_model_file_selected)


func _configure_file_dialog() -> void:
	if not is_instance_valid(file_dialog):
		return
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.filters = PackedStringArray([
		"*.py ; Python MoveEngine",
		"*.exe,*.bat,*.cmd ; Executable MoveEngine",
		"*.pt ; gomoku_ai checkpoint",
	])


func _apply_mode_visibility() -> void:
	var needs_bot := bot_player != 0
	var needs_model := model_player != 0

	if is_instance_valid(bot_list):
		bot_list.select_mode = ItemList.SELECT_SINGLE
		bot_list.allow_reselect = true
		bot_list.mouse_filter = Control.MOUSE_FILTER_STOP if needs_bot else Control.MOUSE_FILTER_IGNORE
		bot_list.modulate = Color(1, 1, 1, 1) if needs_bot else Color(1, 1, 1, 0.45)
	if is_instance_valid(bot_status_label):
		bot_status_label.text = "Select a Bot for %s." % _player_name(bot_player) if needs_bot else "No Bot is needed for this mode."

	if is_instance_valid(select_model_button):
		select_model_button.disabled = not needs_model
	if is_instance_valid(model_path_label):
		model_path_label.text = "Select a Python script, executable, or .pt checkpoint." if needs_model else "No model file is needed for this mode."


func _load_bot_list() -> void:
	_set_bot_items(fallback_bots)
	if bot_player == 0:
		return

	bot_list_request = HTTPRequest.new()
	add_child(bot_list_request)
	bot_list_request.request_completed.connect(_on_bot_list_request_completed)
	var endpoint := "%s/bots" % _trim_trailing_slash(bot_bridge_endpoint)
	var err := bot_list_request.request(endpoint)
	if err != OK and is_instance_valid(bot_status_label):
		bot_status_label.text = "Using built-in Bot list. Bot bridge is not available."


func _set_bot_items(items: Array[String]) -> void:
	available_bots.clear()
	for item in items:
		available_bots.append(item)
	if not is_instance_valid(bot_list):
		return

	bot_list.clear()
	for bot_name in available_bots:
		bot_list.add_item(bot_name)

	if bot_player != 0 and not available_bots.is_empty():
		selected_bot_name = _current_bot_name()
		var index := available_bots.find(selected_bot_name)
		if index < 0:
			index = 0
			selected_bot_name = available_bots[index]
		bot_list.select(index)


func _on_bot_list_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if is_instance_valid(bot_list_request):
		bot_list_request.queue_free()
		bot_list_request = null

	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		return

	var data = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		return

	var bots = data.get("bots", [])
	if not (bots is Array) or bots.is_empty():
		return

	var names: Array[String] = []
	for item in bots:
		names.append(str(item))
	_set_bot_items(names)
	if is_instance_valid(bot_status_label):
		bot_status_label.text = "Select a Bot for %s." % _player_name(bot_player)


func _on_bot_selected(index: int) -> void:
	if index < 0 or index >= available_bots.size():
		return
	selected_bot_name = available_bots[index]
	_update_start_state()


func _on_select_model_pressed() -> void:
	if is_instance_valid(file_dialog):
		file_dialog.popup_centered_ratio(0.72)


func _on_model_file_selected(path: String) -> void:
	selected_model_path = path
	selected_model_kind = _infer_engine_kind(path)
	if is_instance_valid(model_path_label):
		model_path_label.text = "%s\n%s" % [selected_model_kind, selected_model_path]
	_update_start_state()


func _on_start_pressed() -> void:
	if not _validate_selection():
		return

	if bot_player != 0:
		_apply_bot_selection(bot_player, selected_bot_name)
	if model_player != 0:
		_apply_model_selection(model_player, selected_model_path, selected_model_kind)

	get_tree().change_scene_to_file(game_scene_path)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(mode_select_scene_path)


func _validate_selection() -> bool:
	if bot_player != 0 and selected_bot_name == "":
		_set_status("Select a Bot before starting.")
		return false
	if model_player != 0 and selected_model_path == "":
		_set_status("Select a Python script, executable, or .pt checkpoint before starting.")
		return false
	return true


func _update_start_state() -> void:
	if not is_instance_valid(start_button):
		return
	start_button.disabled = false
	if model_player != 0 and selected_model_path == "":
		start_button.disabled = true


func _apply_bot_selection(player: int, bot_name: String) -> void:
	if player == 1:
		Global.black_player_type = "bot"
		Global.black_player_name = bot_name
		Global.black_bot_name = bot_name
		Global.black_engine_kind = ""
		Global.black_engine_path = ""
		Global.black_engine_args.clear()
	else:
		Global.white_player_type = "bot"
		Global.white_player_name = bot_name
		Global.white_bot_name = bot_name
		Global.white_engine_kind = ""
		Global.white_engine_path = ""
		Global.white_engine_args.clear()

	if Global.game_mode == "human_vs_bot":
		Global.bot_name = bot_name


func _apply_model_selection(player: int, path: String, kind: String) -> void:
	var model_name := path.get_file().get_basename()
	if player == 1:
		Global.black_player_type = "model"
		Global.black_player_name = model_name
		Global.black_engine_kind = kind
		Global.black_engine_path = path
		Global.black_engine_args.clear()
	else:
		Global.white_player_type = "model"
		Global.white_player_name = model_name
		Global.white_engine_kind = kind
		Global.white_engine_path = path
		Global.white_engine_args.clear()


func _current_bot_name() -> String:
	if bot_player == 1:
		return Global.black_player_name if Global.black_player_name != "" else Global.black_bot_name
	if bot_player == -1:
		return Global.white_player_name if Global.white_player_name != "" else Global.white_bot_name
	return ""


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


func _mode_summary() -> String:
	return "Black: %s   White: %s" % [
		_player_description(1),
		_player_description(-1),
	]


func _player_description(player: int) -> String:
	var player_type := Global.black_player_type if player == 1 else Global.white_player_type
	var player_name := Global.black_player_name if player == 1 else Global.white_player_name
	if player_type == "human":
		return "Human"
	return "%s:%s" % [player_type.capitalize(), player_name]


func _player_name(player: int) -> String:
	return "Black" if player == 1 else "White"


func _set_status(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value


func _trim_trailing_slash(value: String) -> String:
	var result := value.strip_edges()
	while result.ends_with("/"):
		result = result.substr(0, result.length() - 1)
	return result
