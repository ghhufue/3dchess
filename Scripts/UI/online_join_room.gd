extends Control

@export_file("*.tscn") var online_menu_scene_path := "res://Scenes/OnlineModeSelect.tscn"
@export_file("*.tscn") var game_scene_path := "res://Scenes/game.tscn"

@onready var name_input: LineEdit = get_node_or_null("Panel/VBox/NameInput")
@onready var room_input: LineEdit = get_node_or_null("Panel/VBox/RoomInput")
@onready var status_label: Label = get_node_or_null("StatusLabel")
@onready var join_button: Button = get_node_or_null("JoinButton")
@onready var back_button: Button = get_node_or_null("BackButton")

var online_client: Node = null
var join_started := false


func _ready() -> void:
	Global.game_mode = "online_model_vs_model"
	Global.clear_online_pending_messages()
	Global.online_entry_action = "join"
	Global.online_spectator = false
	Global.online_create_room = false
	Global.online_lobby_connected = false

	online_client = Global.get_online_match_client()
	if is_instance_valid(name_input):
		name_input.text = Global.online_player_name
	if is_instance_valid(room_input):
		room_input.text = Global.online_join_room_id

	_connect_controls()
	_connect_online_client()


func _connect_controls() -> void:
	if is_instance_valid(join_button) and not join_button.pressed.is_connected(_on_join_pressed):
		join_button.pressed.connect(_on_join_pressed)
	if is_instance_valid(back_button) and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


func _connect_online_client() -> void:
	if online_client == null:
		return
	if online_client.has_signal("connected") and not online_client.connected.is_connected(_on_online_connected):
		online_client.connected.connect(_on_online_connected)
	if online_client.has_signal("room_joined") and not online_client.room_joined.is_connected(_on_room_joined):
		online_client.room_joined.connect(_on_room_joined)
	if online_client.has_signal("game_started") and not online_client.game_started.is_connected(_on_game_started):
		online_client.game_started.connect(_on_game_started)
	if online_client.has_signal("turn_requested") and not online_client.turn_requested.is_connected(_on_turn_requested):
		online_client.turn_requested.connect(_on_turn_requested)
	if online_client.has_signal("server_error") and not online_client.server_error.is_connected(_on_server_error):
		online_client.server_error.connect(_on_server_error)


func _on_join_pressed() -> void:
	if join_started:
		return

	Global.online_player_name = name_input.text.strip_edges() if is_instance_valid(name_input) else Global.online_player_name
	Global.online_join_room_id = room_input.text.strip_edges() if is_instance_valid(room_input) else ""
	if Global.online_player_name == "":
		_set_status("Enter a player name.")
		return
	if Global.online_join_room_id == "":
		_set_status("Enter a room id.")
		return

	join_started = true
	if is_instance_valid(join_button):
		join_button.disabled = true
	_set_status("Connecting to match server...")
	online_client.connect_to_server(Global.match_server_url)


func _on_online_connected() -> void:
	if not join_started:
		return
	online_client.join_room(Global.online_join_room_id, Global.online_player_name, Global.online_model_name)


func _on_room_joined(room_id: String, player_id: String, color: int) -> void:
	Global.online_room_id = room_id
	Global.online_player_id = player_id
	Global.online_player_color = color
	Global.online_spectator = false
	Global.online_lobby_connected = true
	_set_status("Joined room %s. Waiting for match start..." % room_id)


func _on_game_started(payload: Dictionary) -> void:
	Global.online_pending_game_start = payload
	get_tree().change_scene_to_file(game_scene_path)


func _on_turn_requested(payload: Dictionary) -> void:
	Global.online_pending_turn = payload


func _on_server_error(code: String, message: String) -> void:
	join_started = false
	if is_instance_valid(join_button):
		join_button.disabled = false
	_set_status("[%s] %s" % [code, message])


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(online_menu_scene_path)


func _set_status(value: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = value
