extends Control

@export_file("*.tscn") var configuration_scene_path := "res://Scenes/OfflineConfiguration.tscn"
@export_file("*.tscn") var back_scene_path := "res://Scenes/3_dtitle.tscn"

@onready var human_vs_model_button: Button = get_node_or_null("VBoxContainer/IconButton")
@onready var model_vs_bot_button: Button = get_node_or_null("VBoxContainer/IconButton2")
@onready var human_vs_bot_button: Button = get_node_or_null("VBoxContainer/IconButton3")
@onready var start_button: Button = get_node_or_null("IconButton")
@onready var back_button: Button = get_node_or_null("BackButton")
@onready var panel_controller: Control = get_node_or_null("PanelController")

var selected_mode := ""


func _ready() -> void:
	_connect_button(human_vs_model_button, Callable(self, "_on_human_vs_model_pressed"))
	_connect_button(model_vs_bot_button, Callable(self, "_on_model_vs_bot_pressed"))
	_connect_button(human_vs_bot_button, Callable(self, "_on_human_vs_bot_pressed"))
	_connect_button(start_button, Callable(self, "_on_start_pressed"))
	_connect_button(back_button, Callable(self, "_on_back_pressed"))

	_select_mode("human_vs_model")


func _connect_button(button: Button, callback: Callable) -> void:
	if not is_instance_valid(button):
		return

	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)


func _on_human_vs_model_pressed() -> void:
	_select_mode("human_vs_model")


func _on_model_vs_bot_pressed() -> void:
	_select_mode("model_vs_bot")


func _on_human_vs_bot_pressed() -> void:
	_select_mode("human_vs_bot")


func _select_mode(mode: String) -> void:
	selected_mode = mode

	_set_button_selected(human_vs_model_button, mode == "human_vs_model")
	_set_button_selected(model_vs_bot_button, mode == "model_vs_bot")
	_set_button_selected(human_vs_bot_button, mode == "human_vs_bot")

	if is_instance_valid(panel_controller) and panel_controller.has_method("set_text"):
		panel_controller.set_text(_mode_label(mode))


func _set_button_selected(button: Button, is_selected: bool) -> void:
	if not is_instance_valid(button):
		return

	button.set("selected", is_selected)


func _on_start_pressed() -> void:
	match selected_mode:
		"human_vs_model":
			Global.game_mode = "human_vs_bot"
			Global.black_player_type = "human"
			Global.black_player_name = "human"
			Global.white_player_type = "model"
			Global.white_player_name = "trained"
			Global.bot_name = Global.white_player_name
		"model_vs_bot":
			Global.game_mode = "bot_vs_bot_step"
			Global.black_player_type = "model"
			Global.black_player_name = "trained"
			Global.white_player_type = "bot"
			Global.white_player_name = "classic_rule"
			Global.black_bot_name = Global.black_player_name
			Global.white_bot_name = Global.white_player_name
		"human_vs_bot":
			Global.game_mode = "human_vs_bot"
			Global.black_player_type = "human"
			Global.black_player_name = "human"
			Global.white_player_type = "bot"
			Global.white_player_name = "classic_rule"
			Global.bot_name = Global.white_player_name
		_:
			return

	get_tree().change_scene_to_file(configuration_scene_path)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(back_scene_path)


func _mode_label(mode: String) -> String:
	match mode:
		"human_vs_model":
			return "Human vs Model"
		"model_vs_bot":
			return "Model vs BOT"
		"human_vs_bot":
			return "Human vs Bot"
		_:
			return "Select an offline mode."
