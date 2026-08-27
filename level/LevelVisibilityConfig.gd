extends  Resource
class_name LevelVisibilityConfig

## Directed visibility map: which target_ids each camera can see.
## key = camera_id (String, matches CameraManager's camera_lookup keys e.g. "7")
## value = Array[String] of target_ids visible from that camera
@export var visibility_map: Dictionary = {}

func can_see(camera_id: String, target_id: String) -> bool:
	var visible_targets: Array = visibility_map.get(camera_id, [])
	return target_id in visible_targets
