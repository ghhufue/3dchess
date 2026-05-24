extends Control

@onready var winner_label: Label = get_node_or_null("Label")
@onready var simple_pieces_check: CheckButton = get_node_or_null("SimplePiecesCheck")

func _ready() -> void:
	if is_instance_valid(winner_label):
		winner_label.text = Global.winner_text

	if is_instance_valid(simple_pieces_check):
		simple_pieces_check.button_pressed = Global.use_simple_pieces
		if not simple_pieces_check.toggled.is_connected(_on_simple_pieces_toggled):
			simple_pieces_check.toggled.connect(_on_simple_pieces_toggled)

func _on_simple_pieces_toggled(on: bool) -> void:
	Global.use_simple_pieces = on

