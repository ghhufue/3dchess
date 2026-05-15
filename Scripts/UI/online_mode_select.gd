extends Control

@export_file("*.tscn") var setup_scene_path := "res://Scenes/OnlinePlayerSetup.tscn"
@export var history_poll_interval := 3.0

@onready var host_button: Button = get_node_or_null("Actions/HostButton")
@onready var create_button: Button = get_node_or_null("Actions/CreateButton")
@onready var join_button: Button = get_node_or_null("Actions/JoinButton")
@onready var back_button: Button = get_node_or_null("BackButton")
@onready var history_list: ItemList = get_node_or_null("HistoryPanel/HistoryList")
@onready var status_label: Label = get_node_or_null("HistoryPanel/StatusLabel")
@onready var history_client: Node = get_node_or_null("HistoryClient")

var history_timer: Timer


func _ready() -> void:
	_connect_buttons()
	_connect_history_client()
	_seed_history_placeholder()
	_start_history_client()


func _connect_buttons() -> void:
	if is_instance_valid(host_button) and not host_button.pressed.is_connected(_on_host_pressed):
		host_button.pressed.connect(_on_host_pressed)
	if is_instance_valid(create_button) and not create_button.pressed.is_connected(_on_create_pressed):
		create_button.pressed.connect(_on_create_pressed)
	if is_instance_valid(join_button) and not join_button.pressed.is_connected(_on_join_pressed):
		join_button.pressed.connect(_on_join_pressed)
	if is_instance_valid(back_button) and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


func _connect_history_client() -> void:
	if history_client == null:
		return
	if history_client.has_signal("connected") and not history_client.connected.is_connected(_on_history_connected):
		history_client.connected.connect(_on_history_connected)
	if history_client.has_signal("match_history") and not history_client.match_history.is_connected(_on_match_history):
		history_client.match_history.connect(_on_match_history)
	if history_client.has_signal("server_error") and not history_client.server_error.is_connected(_on_history_error):
		history_client.server_error.connect(_on_history_error)


func _start_history_client() -> void:
	if history_client != null and history_client.has_method("connect_to_server"):
		history_client.connect_to_server(Global.match_server_url)

	history_timer = Timer.new()
	history_timer.wait_time = history_poll_interval
	history_timer.autostart = true
	history_timer.timeout.connect(_request_history)
	add_child(history_timer)


func _seed_history_placeholder() -> void:
	if is_instance_valid(history_list):
		history_list.clear()
		history_list.add_item("No completed online matches yet.")
	if is_instance_valid(status_label):
		status_label.text = "Connecting to match history..."


func _on_history_connected() -> void:
	if is_instance_valid(status_label):
		status_label.text = "History connected."
	_request_history()


func _request_history() -> void:
	if history_client != null and history_client.has_method("request_match_history"):
		history_client.request_match_history()


func _on_match_history(records: Array) -> void:
	if not is_instance_valid(history_list):
		return

	history_list.clear()
	if records.is_empty():
		history_list.add_item("No completed online matches yet.")
		return

	for record in records:
		if record is Dictionary:
			history_list.add_item(_format_record(record))


func _format_record(record: Dictionary) -> String:
	var winner := int(record.get("winner", 0))
	var winner_text := "Draw"
	if winner == 1:
		winner_text = "Black win"
	elif winner == -1:
		winner_text = "White win"

	return "Room %s  %s(%s) vs %s(%s)  %s  %s moves" % [
		str(record.get("room_id", "")),
		str(record.get("black_player", "")),
		str(record.get("black_model", "")),
		str(record.get("white_player", "")),
		str(record.get("white_model", "")),
		winner_text,
		str(record.get("moves", 0)),
	]


func _on_history_error(code: String, message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = "[%s] %s" % [code, message]


func _on_host_pressed() -> void:
	Global.online_entry_action = "host"
	Global.online_spectator = true
	Global.online_create_room = false
	get_tree().change_scene_to_file(setup_scene_path)


func _on_create_pressed() -> void:
	Global.online_entry_action = "create"
	Global.online_spectator = false
	Global.online_create_room = true
	get_tree().change_scene_to_file(setup_scene_path)


func _on_join_pressed() -> void:
	Global.online_entry_action = "join"
	Global.online_spectator = false
	Global.online_create_room = false
	get_tree().change_scene_to_file(setup_scene_path)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/3_dtitle.tscn")
