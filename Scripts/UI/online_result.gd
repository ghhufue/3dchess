extends Control

@export_file("*.tscn") var main_menu_scene_path := "res://Scenes/MainMenu.tscn"

@onready var title_label: Label = get_node_or_null("TitleLabel")
@onready var room_label: Label = get_node_or_null("RoomLabel")
@onready var black_name_label: Label = get_node_or_null("ResultPanel/BlackName")
@onready var black_status_label: Label = get_node_or_null("ResultPanel/BlackStatus")
@onready var white_name_label: Label = get_node_or_null("ResultPanel/WhiteName")
@onready var white_status_label: Label = get_node_or_null("ResultPanel/WhiteStatus")
@onready var local_summary_label: Label = get_node_or_null("LocalSummary")
@onready var home_button: Button = get_node_or_null("HomeButton")

const BLACK := 1
const WHITE := -1
const EMPTY := 0


func _ready() -> void:
	_apply_result()
	if is_instance_valid(home_button) and not home_button.pressed.is_connected(_on_home_pressed):
		home_button.pressed.connect(_on_home_pressed)


func _apply_result() -> void:
	var result := Global.online_result
	var winner := int(result.get("winner", EMPTY))
	var local_color := int(result.get("local_color", Global.online_player_color))
	var black_name := str(result.get("black_player", "Black"))
	var white_name := str(result.get("white_player", "White"))
	var black_model := str(result.get("black_model", ""))
	var white_model := str(result.get("white_model", ""))

	if is_instance_valid(title_label):
		title_label.text = _title_for(winner, local_color)
	if is_instance_valid(room_label):
		room_label.text = "ROOM %s" % str(result.get("room_id", Global.online_room_id))

	if is_instance_valid(black_name_label):
		black_name_label.text = "BLACK  %s%s" % [black_name, _model_suffix(black_model)]
	if is_instance_valid(white_name_label):
		white_name_label.text = "WHITE  %s%s" % [white_name, _model_suffix(white_model)]

	if is_instance_valid(black_status_label):
		black_status_label.text = _status_for_color(BLACK, winner)
	if is_instance_valid(white_status_label):
		white_status_label.text = _status_for_color(WHITE, winner)

	if is_instance_valid(local_summary_label):
		local_summary_label.text = _local_summary(local_color, winner)


func _title_for(winner: int, local_color: int) -> String:
	if winner == EMPTY:
		return "DRAW"
	if winner == local_color:
		return "YOU WIN"
	return "YOU LOSE"


func _status_for_color(color: int, winner: int) -> String:
	if winner == EMPTY:
		return "DRAW"
	return "WIN" if color == winner else "LOSE"


func _local_summary(local_color: int, winner: int) -> String:
	var color_name := "BLACK" if local_color == BLACK else "WHITE"
	if winner == EMPTY:
		return "You played %s. The match ended in a draw." % color_name
	return "You played %s. %s won." % [color_name, "BLACK" if winner == BLACK else "WHITE"]


func _model_suffix(model_name: String) -> String:
	if model_name.strip_edges() == "":
		return ""
	return "  [%s]" % model_name


func _on_home_pressed() -> void:
	get_tree().change_scene_to_file(main_menu_scene_path)
