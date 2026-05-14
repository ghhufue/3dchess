extends Control

@onready var winner_label: Label = get_node_or_null("Label")

func _ready() -> void:
	if is_instance_valid(winner_label):
		winner_label.text = Global.winner_text

