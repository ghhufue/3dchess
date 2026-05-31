extends Control

const EMPTY_SLOT := "?"
const PLAYER_SLOT := " O\n/|\\\n/ \\"

@export_file("*.tscn") var online_menu_scene_path := "res://Scenes/OnlineModeSelect.tscn"
@export_file("*.tscn") var join_scene_path := "res://Scenes/OnlineJoinRoom.tscn"
@export_file("*.tscn") var model_select_scene_path := "res://Scenes/OnlineModelSelect.tscn"
@export_file("*.tscn") var game_scene_path := "res://Scenes/game.tscn"

@onready var room_label: Label = get_node_or_null("RoomLabel")
@onready var mode_label: Label = get_node_or_null("ModeLabel")
@onready var left_icon: Label = get_node_or_null("Players/LeftProfile/VBox/SlotFrame/IconLabel")
@onready var right_icon: Label = get_node_or_null("Players/RightProfile/VBox/SlotFrame/IconLabel")
@onready var left_name: LineEdit = get_node_or_null("Players/LeftProfile/VBox/NameInput")
@onready var right_name: LineEdit = get_node_or_null("Players/RightProfile/VBox/NameInput")
@onready var setup_status: Label = get_node_or_null("SetupStatus")
@onready var settings_button: Button = get_node_or_null("SettingsButton")
@onready var settings_panel: Panel = get_node_or_null("SettingsPanel")
@onready var time_limit_input: SpinBox = get_node_or_null("SettingsPanel/VBox/TimeLimitInput")
@onready var coordinates_check: CheckBox = get_node_or_null("SettingsPanel/VBox/CoordinatesCheck")
@onready var close_settings_button: Button = get_node_or_null("SettingsPanel/VBox/CloseSettingsButton")
@onready var start_button: Button = get_node_or_null("StartButton")
@onready var back_button: Button = get_node_or_null("BackButton")

var online_client: Node = null
var lobby_started := false
var room_full := false


func _ready() -> void:
	if Global.online_entry_action == "join" and not _is_joined_lobby():
		get_tree().call_deferred("change_scene_to_file", join_scene_path)
		return

	online_client = Global.get_online_match_client()
	_configure_initial_values()
	_connect_controls()
	_connect_online_client()
	_apply_initial_slots()
	_apply_pending_room_state()
	if Global.online_entry_action == "host" and not _is_joined_lobby():
		call_deferred("_start_lobby")


func _configure_initial_values() -> void:
	var joined_lobby := _is_joined_lobby()
	Global.game_mode = "online_model_vs_model"
	if not joined_lobby:
		Global.clear_online_pending_messages()
		Global.online_lobby_connected = false
		Global.online_room_id = ""
		Global.online_player_id = ""
		Global.online_player_color = 0
	room_full = false

	if is_instance_valid(mode_label):
		mode_label.text = _mode_title()
	if is_instance_valid(room_label):
		_update_room_label(Global.online_room_id)
	if is_instance_valid(left_name):
		left_name.text = Global.online_player_name
		left_name.editable = not joined_lobby and Global.online_entry_action != "host"
	if is_instance_valid(right_name):
		right_name.text = ""
		right_name.editable = false
		right_name.placeholder_text = "Waiting..."
	if is_instance_valid(time_limit_input):
		time_limit_input.value = Global.online_move_time_limit_sec
	if is_instance_valid(coordinates_check):
		coordinates_check.button_pressed = Global.online_show_coordinates
	if is_instance_valid(settings_panel):
		settings_panel.visible = false
	if is_instance_valid(setup_status):
		if joined_lobby:
			setup_status.text = "Waiting for lobby state..."
		elif Global.online_entry_action == "host":
			setup_status.text = "Creating host room..."
		else:
			setup_status.text = "Set your name, then start the online room."
	if is_instance_valid(start_button):
		start_button.text = "START"
		start_button.disabled = true if joined_lobby or Global.online_entry_action == "host" else Global.online_player_name.strip_edges() == ""


func _connect_controls() -> void:
	if is_instance_valid(settings_button) and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if is_instance_valid(close_settings_button) and not close_settings_button.pressed.is_connected(_on_close_settings_pressed):
		close_settings_button.pressed.connect(_on_close_settings_pressed)
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(back_button) and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)
	if is_instance_valid(left_name) and not left_name.text_changed.is_connected(_on_player_name_changed):
		left_name.text_changed.connect(_on_player_name_changed)


func _connect_online_client() -> void:
	if online_client == null:
		return
	if online_client.has_signal("connected") and not online_client.connected.is_connected(_on_online_connected):
		online_client.connected.connect(_on_online_connected)
	if online_client.has_signal("connection_failed") and not online_client.connection_failed.is_connected(_on_connection_failed):
		online_client.connection_failed.connect(_on_connection_failed)
	if online_client.has_signal("room_hosted") and not online_client.room_hosted.is_connected(_on_room_hosted):
		online_client.room_hosted.connect(_on_room_hosted)
	if online_client.has_signal("room_created") and not online_client.room_created.is_connected(_on_room_created):
		online_client.room_created.connect(_on_room_created)
	if online_client.has_signal("room_state") and not online_client.room_state.is_connected(_on_room_state):
		online_client.room_state.connect(_on_room_state)
	if online_client.has_signal("model_select") and not online_client.model_select.is_connected(_on_model_select):
		online_client.model_select.connect(_on_model_select)
	if online_client.has_signal("game_started") and not online_client.game_started.is_connected(_on_game_started):
		online_client.game_started.connect(_on_game_started)
	if online_client.has_signal("turn_requested") and not online_client.turn_requested.is_connected(_on_turn_requested):
		online_client.turn_requested.connect(_on_turn_requested)
	if online_client.has_signal("server_error") and not online_client.server_error.is_connected(_on_server_error):
		online_client.server_error.connect(_on_server_error)


func _apply_initial_slots() -> void:
	if _is_joined_lobby():
		if Global.online_player_color == 1:
			_set_slot(left_icon, true)
			_set_slot(right_icon, false)
			if is_instance_valid(left_name):
				left_name.text = Global.online_player_name
		else:
			_set_slot(left_icon, false)
			_set_slot(right_icon, true)
			if is_instance_valid(right_name):
				right_name.text = Global.online_player_name
		return

	if Global.online_entry_action == "host":
		_set_slot(left_icon, false)
		_set_slot(right_icon, false)
		if is_instance_valid(left_name):
			left_name.text = ""
			left_name.placeholder_text = "Waiting..."
	else:
		_set_slot(left_icon, true)
		_set_slot(right_icon, false)


func _start_lobby() -> void:
	if lobby_started:
		return
	_apply_settings()
	if not _validate():
		if is_instance_valid(start_button):
			start_button.disabled = false
			start_button.text = "START"
		return

	lobby_started = true
	if is_instance_valid(start_button):
		start_button.disabled = true
	if is_instance_valid(left_name):
		left_name.editable = false
	_set_status("Connecting to match server...")
	online_client.connect_to_server(Global.match_server_url)


func _on_start_pressed() -> void:
	if Global.online_lobby_connected:
		_start_match()
		return
	_start_lobby()


func _on_player_name_changed(new_text: String) -> void:
	if lobby_started or Global.online_entry_action == "host":
		return
	Global.online_player_name = new_text.strip_edges()
	if is_instance_valid(start_button):
		start_button.disabled = Global.online_player_name == ""
		start_button.text = "START"
	if Global.online_player_name != "":
		_set_status("Ready to create room.")


func _on_online_connected() -> void:
	if not lobby_started:
		return

	if Global.online_entry_action == "host":
		online_client.host_game(Global.online_player_name)
		_set_status("Creating host room...")
	else:
		online_client.create_room(Global.online_player_name, Global.online_model_name)
		_set_status("Creating room...")


func _on_room_hosted(room_id: String, spectator_id: String) -> void:
	Global.online_room_id = room_id
	Global.online_player_id = spectator_id
	Global.online_player_color = 0
	Global.online_spectator = true
	Global.online_lobby_connected = true
	_update_room_label(room_id)
	_set_status("Room %s. Waiting for two players." % room_id)


func _on_room_created(room_id: String, player_id: String, color: int) -> void:
	Global.online_room_id = room_id
	Global.online_player_id = player_id
	Global.online_player_color = color
	Global.online_spectator = false
	Global.online_lobby_connected = true
	_update_room_label(room_id)
	_set_status("Room %s. Waiting for the other player." % room_id)
	if is_instance_valid(start_button):
		start_button.disabled = true
		start_button.text = "START"


func _on_room_state(payload: Dictionary) -> void:
	Global.online_pending_room_state = payload
	_update_room_label(str(payload.get("room_id", Global.online_room_id)))
	room_full = bool(payload.get("is_full", false))

	var black_name := str(payload.get("black_player", ""))
	var white_name := str(payload.get("white_player", ""))
	_set_slot(left_icon, black_name != "")
	_set_slot(right_icon, white_name != "")

	if is_instance_valid(left_name):
		left_name.text = black_name
	if is_instance_valid(right_name):
		right_name.text = white_name

	if room_full:
		_set_status("Both players joined. Press START to begin." if _can_start_match() else "Both players joined. Waiting for host to start.")
		if is_instance_valid(start_button):
			start_button.disabled = not _can_start_match()
			start_button.text = "START"
	else:
		_set_status("Waiting for players.")
		if is_instance_valid(start_button):
			start_button.disabled = true
			start_button.text = "START"


func _on_game_started(payload: Dictionary) -> void:
	Global.online_pending_game_start = payload
	get_tree().change_scene_to_file(game_scene_path)


func _on_model_select(payload: Dictionary) -> void:
	Global.online_pending_model_select = payload
	get_tree().change_scene_to_file(model_select_scene_path)


func _on_turn_requested(payload: Dictionary) -> void:
	Global.online_pending_turn = payload


func _on_server_error(code: String, message: String) -> void:
	lobby_started = false
	if is_instance_valid(start_button):
		start_button.disabled = false
		start_button.text = "RETRY"
	if is_instance_valid(left_name):
		left_name.editable = Global.online_entry_action != "host"
	_set_status("[%s] %s" % [code, message])


func _on_connection_failed(message: String) -> void:
	lobby_started = false
	if is_instance_valid(start_button):
		start_button.disabled = false
		start_button.text = "RETRY"
	if is_instance_valid(left_name):
		left_name.editable = Global.online_entry_action != "host"
	_set_status(message)


func _start_match() -> void:
	if not _can_start_match():
		_set_status("Waiting for host to start.")
		return
	if not room_full:
		_set_status("Waiting for the other player.")
		return
	if online_client == null or not online_client.has_method("start_game"):
		_set_status("Online client cannot start the match.")
		return

	if is_instance_valid(start_button):
		start_button.disabled = true
		start_button.text = "WAIT"
	_set_status("Starting match...")
	online_client.start_game(Global.online_room_id)


func _on_settings_pressed() -> void:
	if is_instance_valid(settings_panel):
		settings_panel.visible = true


func _on_close_settings_pressed() -> void:
	if is_instance_valid(settings_panel):
		settings_panel.visible = false


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(online_menu_scene_path)


func _apply_settings() -> void:
	Global.online_player_name = left_name.text.strip_edges() if is_instance_valid(left_name) else Global.online_player_name
	Global.online_move_time_limit_sec = int(time_limit_input.value) if is_instance_valid(time_limit_input) else Global.online_move_time_limit_sec
	Global.online_show_coordinates = coordinates_check.button_pressed if is_instance_valid(coordinates_check) else Global.online_show_coordinates

	if Global.online_entry_action == "host":
		Global.online_spectator = true
		Global.online_create_room = false
	else:
		Global.online_spectator = false
		Global.online_create_room = true
	Global.online_join_room_id = ""


func _validate() -> bool:
	if Global.online_entry_action != "host" and Global.online_player_name == "":
		_set_status("Enter a player name.")
		return false
	return true


func _set_slot(label: Label, occupied: bool) -> void:
	if is_instance_valid(label):
		label.text = PLAYER_SLOT if occupied else EMPTY_SLOT


func _update_room_label(room_id: String) -> void:
	if is_instance_valid(room_label):
		if room_id.strip_edges() == "":
			room_label.text = "ROOM ------"
		else:
			room_label.text = "ROOM %s" % room_id


func _set_status(value: String) -> void:
	if is_instance_valid(setup_status):
		setup_status.text = value


func _mode_title() -> String:
	if Global.online_entry_action == "join":
		return "JOIN ROOM"
	return "HOST GAME" if Global.online_entry_action == "host" else "CREATE ROOM"


func _is_joined_lobby() -> bool:
	return Global.online_entry_action == "join" and Global.online_lobby_connected and Global.online_room_id.strip_edges() != ""


func _can_start_match() -> bool:
	return Global.online_entry_action == "host" or (Global.online_entry_action != "join" and not Global.online_spectator)


func _apply_pending_room_state() -> void:
	if not Global.online_pending_room_state.is_empty():
		_on_room_state(Global.online_pending_room_state)
