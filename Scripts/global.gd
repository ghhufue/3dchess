extends Node

var winner_text : String = ""
var bot_name: String = "classic_rule" # classic_rule or reward_driven
var game_mode: String = "human_vs_bot"   # "human_vs_bot" / "bot_vs_bot_step"
var black_bot_name: String = "classic_rule"
var white_bot_name: String = "trained"
var trained_model_path: String = ""
var trained_model_label: String = ""
var use_simple_pieces: bool = false
