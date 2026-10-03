class_name GameMode

enum Mode {Normal, Expert}

static var current: Mode = Mode.Normal
static var fail_on_wrong_r: bool = false
static var fail_on_cap_reached: bool = false

static func set_mode(mode: Mode) -> void:
	current = mode
	fail_on_wrong_r = (mode == Mode.Expert)
	fail_on_cap_reached = (mode == Mode.Expert)
