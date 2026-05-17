extends Control

@export_file("*.tscn") var setup_scene_path := "res://Scenes/OnlinePlayerSetup.tscn"

@onready var host_button: Button = get_node_or_null("Actions/HostButton")
@onready var create_button: Button = get_node_or_null("Actions/CreateButton")
@onready var join_button: Button = get_node_or_null("Actions/JoinButton")
@onready var back_button: Button = get_node_or_null("BackButton")



func _ready() -> void:
	_connect_buttons()


func _connect_buttons() -> void:
	if is_instance_valid(host_button) and not host_button.pressed.is_connected(_on_host_pressed):
		host_button.pressed.connect(_on_host_pressed)
	if is_instance_valid(create_button) and not create_button.pressed.is_connected(_on_create_pressed):
		create_button.pressed.connect(_on_create_pressed)
	if is_instance_valid(join_button) and not join_button.pressed.is_connected(_on_join_pressed):
		join_button.pressed.connect(_on_join_pressed)
	if is_instance_valid(back_button) and not back_button.pressed.is_connected(_on_back_pressed):
		back_button.pressed.connect(_on_back_pressed)


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
