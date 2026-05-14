extends Node

var winner_text : String = ""
var bot_name: String = "classic_rule" # classic_rule or reward_driven
var game_mode: String = "human_vs_bot"   # "human_vs_bot" / "bot_vs_bot_step" / "online_model_vs_model"
var black_bot_name: String = "classic_rule"
var white_bot_name: String = "trained"
var trained_model_path: String = ""
var trained_model_label: String = ""
var use_simple_pieces: bool = false

var match_server_url: String = "ws://127.0.0.1:9000/ws"
var online_room_id: String = ""
var online_join_room_id: String = ""
var online_player_id: String = ""
var online_player_name: String = "godot_model"
var online_player_color: int = 0
var online_model_name: String = "trained"
var online_create_room: bool = true
