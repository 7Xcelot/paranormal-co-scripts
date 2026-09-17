extends Label

@onready var blink_timer = $BlinkTimer
var cursor_offset = Vector2(-20, 0)

func _ready() -> void:
	visible = false 
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	if owner:
		_bind_cursor_to_all_buttons(owner)

func _bind_cursor_to_all_buttons(current_node: Node) -> void:
	for child in current_node.get_children():
		if child is Button:
			child.mouse_entered.connect(child.grab_focus)
			child.focus_entered.connect(_move_to_button.bind(child))
		if child.get_child_count() > 0:
			_bind_cursor_to_all_buttons(child)

func _move_to_button(button: Button) -> void:
	global_position = button.global_position + cursor_offset
	visible = true
	blink_timer.start()

func _on_blink_timer_timeout() -> void:
	visible = not visible
