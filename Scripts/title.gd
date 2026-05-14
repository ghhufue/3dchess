extends Control

@onready var file_dialog := $FileDialog
@onready var model_label := $ModelLabel
@onready var simple_pieces_check := $SimplePiecesCheck

func _ready() -> void:
	print("Label:", $Label)
	print("ButtonPC:", $ButtonPC)
	print("ButtonPC2:", $ButtonPC2)
	print("ButtonPC3:", $ButtonPC3)
	print("ButtonSelectModel:", $ButtonSelectModel)
	print("ModelLabel:", $ModelLabel)
	print("FileDialog:", $FileDialog)
	$Label.text = Global.winner_text
	$ButtonPC.pressed.connect(_on_classic_pressed)
	$ButtonPC2.pressed.connect(_on_trained_pressed)
	$ButtonPC3.pressed.connect(_on_bot_vs_bot_pressed)
	$ButtonSelectModel.pressed.connect(_on_select_model_pressed)

	simple_pieces_check.button_pressed = Global.use_simple_pieces
	simple_pieces_check.toggled.connect(_on_simple_pieces_toggled)

	# 配置 FileDialog
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = ["*.pt ; PyTorch Model"]
	file_dialog.file_selected.connect(_on_file_selected)

	file_dialog.current_dir = ""

	if Global.trained_model_path != "":
		model_label.text = "select: " + Global.trained_model_label
	else:
		model_label.text = "no model selected"

func _on_simple_pieces_toggled(on: bool) -> void:
	Global.use_simple_pieces = on

func _on_select_model_pressed() -> void:
	file_dialog.popup_centered_ratio(0.6)

func _on_file_selected(path: String) -> void:
	Global.trained_model_path = path
	# 取文件名作为 label
	Global.trained_model_label = path.get_file()
	model_label.text = "select: " + Global.trained_model_label
	print("selected model:", path)

func _on_classic_pressed() -> void:
	Global.game_mode = "human_vs_bot"
	Global.bot_name = "reward_driven" # reward_driven or classic_rule
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_trained_pressed() -> void:
	Global.game_mode = "human_vs_bot"
	Global.bot_name = "trained"
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func _on_bot_vs_bot_pressed() -> void:
	Global.game_mode = "bot_vs_bot_step"
	Global.black_bot_name = "reward_driven"
	Global.white_bot_name = "trained"
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
