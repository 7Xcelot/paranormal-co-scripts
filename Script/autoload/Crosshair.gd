extends Node

var _display: Control
const ARM_LENGTH: float = 8.0
const BAR_WIDTH: float = 24.0
const BAR_HEIGHT: float = 3.0
const BAR_GAP: float = 3.0

var _progress: float = 0.0
var _bar_visible: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	_display = Control.new()
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_display.set_anchors_preset(Control.PRESET_FULL_RECT)
	_display.draw.connect(_on_draw)
	layer.add_child(_display)

func _process(_delta: float) -> void:
	_display.queue_redraw()

func set_progress(value: float) -> void:
	_progress = clamp(value, 0.0, 1.0)

func set_bar_enabled(enabled: bool) -> void:
	_bar_visible = enabled
	if not enabled:
		_progress = 0.0

func _on_draw() -> void:
	var pos: Vector2 = _display.get_local_mouse_position()
	_display.draw_line(pos + Vector2(-ARM_LENGTH, 0), pos + Vector2(ARM_LENGTH, 0), Color.WHITE, 2.0)
	_display.draw_line(pos + Vector2(0, -ARM_LENGTH), pos + Vector2(0, ARM_LENGTH), Color.WHITE, 2.0)
	if not _bar_visible or _progress <= 0.0:
		return
	var origin := pos + Vector2(-BAR_WIDTH / 2.0, ARM_LENGTH + BAR_GAP)
	_display.draw_rect(Rect2(origin, Vector2(BAR_WIDTH, BAR_HEIGHT)), Color(1, 1, 1, 0.3))
	_display.draw_rect(Rect2(origin, Vector2(BAR_WIDTH * _progress, BAR_HEIGHT)), Color.WHITE)
