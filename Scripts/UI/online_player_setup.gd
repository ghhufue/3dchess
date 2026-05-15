extends Control

@export_file("*.tscn") var online_menu_scene_path := "res://Scenes/OnlineModeSelect.tscn"
@export_file("*.tscn") var game_scene_path := "res://Scenes/game.tscn"
@export var avatars: Array[Texture2D] = []

@onready var left_avatar: TextureButton = get_node_or_null("Players/LocalProfile/VBox/AvatarButton")
@onready var left_avatar_image: TextureRect = get_node_or_null("Players/LocalProfile/VBox/AvatarButton/AvatarImage")
@onready var right_avatar: TextureRect = get_node_or_null("Players/OpponentProfile/VBox/AvatarPreview")
@onready var opponent_profile: Panel = get_node_or_null("Players/OpponentProfile")
@onready var name_input: LineEdit = get_node_or_null("Players/LocalProfile/VBox/NameInput")
@onready var room_input: LineEdit = get_node_or_null("Players/OpponentProfile/VBox/RoomInput")
@onready var mode_label: Label = get_node_or_null("ModeLabel")
@onready var setup_status: Label = get_node_or_null("SetupStatus")
@onready var settings_button: Button = get_node_or_null("SettingsButton")
@onready var settings_panel: Panel = get_node_or_null("SettingsPanel")
@onready var time_limit_input: SpinBox = get_node_or_null("SettingsPanel/VBox/TimeLimitInput")
@onready var coordinates_check: CheckBox = get_node_or_null("SettingsPanel/VBox/CoordinatesCheck")
@onready var close_settings_button: Button = get_node_or_null("SettingsPanel/VBox/CloseSettingsButton")
@onready var start_button: Button = get_node_or_null("StartButton")
@onready var back_button: Button = get_node_or_null("BackButton")

var selected_avatar_index := 0


func _ready() -> void:
	_configure_initial_values()
	_connect_controls()
	_apply_avatar()
	_apply_mode_visibility()


func _configure_initial_values() -> void:
	selected_avatar_index = Global.online_avatar_index
	if is_instance_valid(name_input):
		name_input.text = Global.online_player_name
	if is_instance_valid(room_input):
		room_input.text = Global.online_join_room_id
	if is_instance_valid(time_limit_input):
		time_limit_input.value = Global.online_move_time_limit_sec
	if is_instance_valid(coordinates_check):
		coordinates_check.button_pressed = Global.online_show_coordinates
	if is_instance_valid(settings_panel):
		settings_panel.visible = false
	if is_instance_valid(mode_label):
		mode_label.text = _mode_title()


func _connect_controls() -> void:
	if is_instance_valid(left_avatar) and not left_avatar.pressed.is_connected(_on_avatar_pressed):
		left_avatar.pressed.connect(_on_avatar_pressed)
	if is_instance_valid(settings_button) and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)
	if is_instance_valid(close_settings_button) and not close_settings_button.pressed.is_connected(_on_close_settings_pressed):
		close_settings_button.pressed.connect(_on_close_settings_pressed)
	if is_instance_valid(start_button) and not start_button.pressed.is_connected(_on_start_pressed):
		start_button.pressed.connect(_on_start_pressed)
	if is_instance_valid(back_button) and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


func _apply_mode_visibility() -> void:
	var is_join := Global.online_entry_action == "join"
	if is_instance_valid(room_input):
		room_input.visible = is_join
	if is_instance_valid(opponent_profile):
		opponent_profile.visible = false
	if is_instance_valid(setup_status):
		if Global.online_entry_action == "host":
			setup_status.text = "Host mode watches both players without occupying black or white."
		elif is_join:
			setup_status.text = "Enter the room id to join as a player."
		else:
			setup_status.text = "Create a room and wait for another player."


func _apply_avatar() -> void:
	if avatars.is_empty():
		return
	selected_avatar_index = clampi(selected_avatar_index, 0, avatars.size() - 1)
	var texture := avatars[selected_avatar_index]
	if is_instance_valid(left_avatar_image):
		left_avatar_image.texture = texture
	if is_instance_valid(right_avatar):
		right_avatar.texture = avatars[(selected_avatar_index + 1) % avatars.size()]


func _on_avatar_pressed() -> void:
	if avatars.is_empty():
		return
	selected_avatar_index = (selected_avatar_index + 1) % avatars.size()
	_apply_avatar()


func _on_settings_pressed() -> void:
	if is_instance_valid(settings_panel):
		settings_panel.visible = true


func _on_close_settings_pressed() -> void:
	if is_instance_valid(settings_panel):
		settings_panel.visible = false


func _on_start_pressed() -> void:
	_apply_settings()
	if not _validate():
		return
	get_tree().change_scene_to_file(game_scene_path)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(online_menu_scene_path)


func _apply_settings() -> void:
	Global.online_player_name = name_input.text.strip_edges() if is_instance_valid(name_input) else Global.online_player_name
	Global.online_avatar_index = selected_avatar_index
	Global.online_move_time_limit_sec = int(time_limit_input.value) if is_instance_valid(time_limit_input) else Global.online_move_time_limit_sec
	Global.online_show_coordinates = coordinates_check.button_pressed if is_instance_valid(coordinates_check) else Global.online_show_coordinates

	match Global.online_entry_action:
		"host":
			Global.online_spectator = true
			Global.online_create_room = false
			Global.online_join_room_id = ""
		"create":
			Global.online_spectator = false
			Global.online_create_room = true
			Global.online_join_room_id = ""
		"join":
			Global.online_spectator = false
			Global.online_create_room = false
			Global.online_join_room_id = room_input.text.strip_edges() if is_instance_valid(room_input) else ""


func _validate() -> bool:
	if Global.online_player_name == "":
		_set_status("Enter a player name.")
		return false
	if Global.online_entry_action == "join" and Global.online_join_room_id == "":
		_set_status("Enter a room id.")
		return false
	return true


func _set_status(value: String) -> void:
	if is_instance_valid(setup_status):
		setup_status.text = value


func _mode_title() -> String:
	match Global.online_entry_action:
		"host":
			return "HOST GAME"
		"join":
			return "JOIN ROOM"
		_:
			return "CREATE ROOM"
