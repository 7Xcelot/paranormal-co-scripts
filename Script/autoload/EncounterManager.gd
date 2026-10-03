extends Node
signal encounter_triggered(encounter)

var _encounters: Array = []
var active_encounter: Encounter = null
var _trigger_time: float = -1.0
var _has_triggered: bool = false

func _ready() -> void:
	GlobalTimeManager.encounter_window_started.connect(_on_window_started)

func register(encounter: Encounter) -> void:
	_encounters.append(encounter)

func _on_window_started() -> void:
	_has_triggered = false
	_trigger_time = randf_range(
		GlobalTimeManager.ENCOUNTER_WINDOW_START,
		GlobalTimeManager.ENCOUNTER_WINDOW_END
	)
	set_process(true)

func _process(_delta: float) -> void:
	if _has_triggered or not GlobalTimeManager.is_encounter_window_active:
		set_process(false)
		return
	if GlobalTimeManager.elapsed_time >= _trigger_time:
		_has_triggered = true
		var pool: Array = _encounters.filter(func(e): return not e.consumed)
		if not pool.is_empty():
			active_encounter = pool.pick_random()
			active_encounter.trigger()
			encounter_triggered.emit(active_encounter)

func _on_encounter_resolved() -> void:
	active_encounter = null
