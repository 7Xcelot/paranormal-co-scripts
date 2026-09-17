extends Label

var default_prompt = "[ ▲ / ▼ ] : Navigate  |  [ Enter ] : Select"

func _ready() -> void:
	text = default_prompt
	if owner:
		_listen_to_all_buttons(owner)

func _listen_to_all_buttons(current_node: Node) -> void:
	for child in current_node.get_children():
		if child is Button or child is Range:
			child.focus_entered.connect(_update_prompt.bind(child))
		if child.get_child_count() > 0:
			_listen_to_all_buttons(child)

func _update_prompt(element: Control) -> void:
	if element.has_meta("prompt"):
		text = element.get_meta("prompt")
	else:
		text = default_prompt
