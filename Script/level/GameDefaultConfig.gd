class_name GameDefualtConfig

const DEFAULTS := {
	"ene_ano_wake": 120,
	"hunter_wake": 210,
	"cooldown_mult": 1.0,
}

const COOLDOWN := {
	"obj_ano": {1: 12.0, 2: 30.0, 3: 40.0, 5: 30.0, "default": 12.0},
	"ene_ano": {3: 40.0, 5: 30.0, "default": 40.0},
	"hunter": {5: 31.5, "default": 45.0}, # 31.5 = 45 x 0.7
}

const LEVEL_OVERRIDES := {
	# 2: {"ene_ano_wake": 100.0},
	# 3: {"ene_ano_wake": 100.0, "cooldown_mult": 0.8}
}

static var _level_id: int = 0

static func load_level(level_id: int) -> void:
	_level_id = level_id
	for key in LEVEL_OVERRIDES.get(level_id, {}):
		if not DEFAULTS.has(key):
			push_warning("GameDefualtConfig: ด่าน %d ใช้ key ที่ไม่มีใน Defaults: '%s'" % [level_id, key])

static func reset() -> void:
	_level_id = 0

static func get_value(key: String) -> float:
	if not DEFAULTS.has(key):
		push_error("GameDefualtConfig: ไม่รู้จัก key '%s'" % key)
		return 0.0
	var overrides: Dictionary = LEVEL_OVERRIDES.get(_level_id, {})
	return overrides.get(key, DEFAULTS[key])

static func cooldown_for(system: String, phase: int) -> float:
	var table: Dictionary = COOLDOWN[system]
	var base: float = table.get(phase, table["default"])
	return base * get_value("cooldown_mult")
