extends Control

@export_file("*.tscn") var game_scene_path := "res://Scenes/game.tscn"

@onready var server_url_input: LineEdit = get_node_or_null("Panel/VBox/ServerUrlInput")
@onready var player_name_input: LineEdit = get_node_or_null("Panel/VBox/PlayerNameInput")
@onready var model_name_input: LineEdit = get_node_or_null("Panel/VBox/ModelNameInput")
@onready var room_id_input: LineEdit = get_node_or_null("Panel/VBox/RoomIdInput")
@onready var create_button: Button = get_node_or_null("Panel/VBox/Actions/CreateButton")
@onready var join_button: Button = get_node_or_null("Panel/VBox/Actions/JoinButton")


func _ready() -> void:
	if is_instance_valid(server_url_input):
		server_url_input.text = Global.match_server_url
	if is_instance_valid(player_name_input):
		player_name_input.text = Global.online_player_name
	if is_instance_valid(model_name_input):
		model_name_input.text = Global.online_model_name
	if is_instance_valid(room_id_input):
		room_id_input.text = Global.online_join_room_id

	if is_instance_valid(create_button) and not create_button.pressed.is_connected(_on_create_pressed):
		create_button.pressed.connect(_on_create_pressed)
	if is_instance_valid(join_button) and not join_button.pressed.is_connected(_on_join_pressed):
		join_button.pressed.connect(_on_join_pressed)


func _on_create_pressed() -> void:
	_apply_common_settings()
	Global.online_create_room = true
	Global.online_join_room_id = ""
	get_tree().change_scene_to_file(game_scene_path)


func _on_join_pressed() -> void:
	_apply_common_settings()
	Global.online_create_room = false
	Global.online_join_room_id = room_id_input.text.strip_edges() if is_instance_valid(room_id_input) else ""
	get_tree().change_scene_to_file(game_scene_path)


func _apply_common_settings() -> void:
	Global.game_mode = "online_model_vs_model"
	Global.match_server_url = server_url_input.text.strip_edges() if is_instance_valid(server_url_input) else Global.match_server_url
	Global.online_player_name = player_name_input.text.strip_edges() if is_instance_valid(player_name_input) else Global.online_player_name
	Global.online_model_name = model_name_input.text.strip_edges() if is_instance_valid(model_name_input) else Global.online_model_name
