extends Node

const CURSOR_CHAR: String = "▶"
const CURSOR_OFFSET: Vector2 = Vector2(-20, 0)
const BLINK_INTERVAL: float = 0.3
const SCAN_INTERVAL: float = 0.5

var _label: Label
var _blink_timer: Timer
var _scan_timer: Timer
var _bound_buttons: Array[Button] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 90
	add_child(layer)

	_label = Label.new()
	_label.text = CURSOR_CHAR
	_label.visible = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_label)

	_blink_timer = Timer.new()
	_blink_timer.wait_time = BLINK_INTERVAL
	_blink_timer.timeout.connect(_on_blink_timer_timeout)
	add_child(_blink_timer)

	_scan_timer = Timer.new()
	_scan_timer.wait_time = SCAN_INTERVAL
	_scan_timer.timeout.connect(_scan_for_buttons)
	add_child(_scan_timer)
	_scan_timer.start()
	_scan_for_buttons()

func _scan_for_buttons() -> void:
	_scan_node(get_tree().root)

func _scan_node(node: Node) -> void:
	if node is Button and node not in _bound_buttons:
		_bound_buttons.append(node)
		if node.focus_mode == Control.FOCUS_NONE:
			node.focus_mode = Control.FOCUS_ALL
		node.mouse_entered.connect(node.grab_focus)
		node.focus_entered.connect(_move_to_button.bind(node))
		node.focus_exited.connect(_on_focus_exited)
	for child in node.get_children():
		_scan_node(child)

func _move_to_button(button: Button) -> void:
	_label.global_position = button.global_position + CURSOR_OFFSET
	_label.visible = true
	_blink_timer.start()

func _on_blink_timer_timeout() -> void:
	_label.visible = not _label.visible

func _on_focus_exited() -> void:
	_label.visible = false
	_blink_timer.stop()
