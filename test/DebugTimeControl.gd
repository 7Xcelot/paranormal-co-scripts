extends Node
# Autoload: "DebugTimeControl"
# เร่ง/หยุดเวลาทั้งเกมด้วย Engine.time_scale — มีผลกับ _process/_physics_process ทุก node
# ทำงานเฉพาะ debug build เท่านั้น export build จริงจะปิดตัวเองอัตโนมัติ

var _enabled: bool = false

func _ready() -> void:
	_enabled = OS.is_debug_build()
	if not _enabled:
		return
	print("DebugTimeControl: เปิดใช้งาน (debug build เท่านั้น) — กด F1 เพื่อดูปุ่มทั้งหมด")

func _unhandled_key_input(event: InputEvent) -> void:
	if not _enabled or not event is InputEventKey or not event.pressed:
		return

	match event.keycode:
		KEY_F1:
			_print_help()
		KEY_F5:
			_set_speed(1.0)
		KEY_F6:
			_set_speed(5.0)
		KEY_F7:
			_set_speed(20.0)
		KEY_F8:
			_set_speed(60.0)
		KEY_F12:
			_toggle_pause()

func _set_speed(scale: float) -> void:
	Engine.time_scale = scale
	print("DebugTimeControl: game speed = %.0fx" % scale)

func _toggle_pause() -> void:
	if Engine.time_scale > 0.0:
		Engine.time_scale = 0.0
		print("DebugTimeControl: paused")
	else:
		Engine.time_scale = 1.0
		print("DebugTimeControl: resumed (1x)")

func _print_help() -> void:
	print("""
	--- DebugTimeControl ---
	F5  = speed x1  (ปกติ)
	F6  = speed x5
	F7  = speed x20
	F8  = speed x60
	F12 = pause / resume
	""")
