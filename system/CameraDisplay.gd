extends TextureRect
class_name  CameraDisplay

@export var camera_viewport: SubViewport

func _ready() -> void:
	camera_viewport.physics_object_picking = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(_sync_viewport_size)
	_sync_viewport_size()
	
func _sync_viewport_size() -> void:
	if size.x <= 0 or size.y <= 0:
		return
	camera_viewport.size = Vector2i(size)
	
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		var scale_factor: Vector2 = Vector2(camera_viewport.size) / size
		var mapped_event = event.duplicate()
		mapped_event.position = event.position * scale_factor
		camera_viewport.push_input(mapped_event)
