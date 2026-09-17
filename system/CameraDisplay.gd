extends Control

@onready var cursor = $BlinkingCursor
@onready var blink_timer = $BlinkingCursor/BlinkTimer

var cursor_offset = Vector2(-20, 0)

func _ready() -> void:
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	_bind_cursor_to_all_buttons(self)

func _bind_cursor_to_all_buttons(current_node: Node) -> void:
	for child in  current_node.get_children():
		if child is Button:
			child.mouse_entered.connect(child.grab_focus())
			child.focus_entered.connect(_on_button_focused.bind(child))
			
		if child.get_child_count() > 0:
			_bind_cursor_to_all_buttons(child)

func _on_button_focused(button: Button) -> void:
	cursor.global_position = button.global_position + cursor_offset
	cursor.visible = true
	blink_timer.start()

func _on_blink_timer_timeout() -> void:
	cursor.visible = not cursor.visible
