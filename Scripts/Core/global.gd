extends Node

const OnlineMatchClientScript = preload("res://Scripts/Providers/online_match_client.gd")

var winner_text : String = ""
var bot_name: String = "classic_rule" # classic_rule or reward_driven
var game_mode: String = "human_vs_bot"   # "human_vs_bot" / "bot_vs_bot_step" / "online_model_vs_model"
var black_bot_name: String = "classic_rule"
var white_bot_name: String = "trained"
var black_player_type: String = "human" # "human" / "bot" / "model"
var white_player_type: String = "bot"
var black_player_name: String = "human"
var white_player_name: String = "classic_rule"
var black_engine_kind: String = "" # "python_script" / "executable" / "gomoku_ai_checkpoint"
var white_engine_kind: String = ""
var black_engine_path: String = ""
var white_engine_path: String = ""
var black_engine_args: Array[String] = []
var white_engine_args: Array[String] = []
var trained_model_path: String = ""
var trained_model_label: String = ""
var use_simple_pieces: bool = false

var match_server_url: String = "ws://frp-cup.com:57190/ws"
var online_room_id: String = ""
var online_join_room_id: String = ""
var online_player_id: String = ""
var online_player_name: String = "godot_model"
var online_player_color: int = 0
var online_model_name: String = "trained"
var online_engine_kind: String = ""
var online_engine_path: String = ""
var online_engine_args: Array[String] = []
var online_entry_action: String = "create" # "host" / "create" / "join"
var online_create_room: bool = true
var online_spectator: bool = false
var online_avatar_index: int = 0
var online_opponent_name: String = ""
var online_opponent_avatar_index: int = 0
var online_move_time_limit_sec: int = 30
var online_show_coordinates: bool = true
var online_lobby_connected: bool = false
var online_pending_room_state: Dictionary = {}
var online_pending_model_select: Dictionary = {}
var online_pending_game_start: Dictionary = {}
var online_pending_turn: Dictionary = {}
var online_result: Dictionary = {}

var _online_match_client: Node = null


func get_online_match_client() -> Node:
	if not is_instance_valid(_online_match_client):
		_online_match_client = Node.new()
		_online_match_client.name = "OnlineMatchClient"
		_online_match_client.set_script(OnlineMatchClientScript)
		add_child(_online_match_client)
	return _online_match_client


func clear_online_pending_messages() -> void:
	online_pending_room_state = {}
	online_pending_model_select = {}
	online_pending_game_start = {}
	online_pending_turn = {}
	online_result = {}
