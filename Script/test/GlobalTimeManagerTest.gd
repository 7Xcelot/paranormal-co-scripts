extends Node
# ทดสอบ GlobalTimeManager
# วิธีใช้: แนบสคริปต์นี้กับ node ไหนก็ได้ใน scene หลัก (เช่น root node ของ node_3d.tscn)
# แล้วกด F5 (Play Project) หรือ F6 (Play Current Scene) — ห้ามกด "File > Run" ในสคริปต์นี้
# เพราะไม่ใช่ EditorScript จะรันแบบนั้นไม่ได้ ต้องรันผ่านเกมจริงเท่านั้น

@export var time_speed_multiplier: float = 20.0  # เร่งเวลา 20 เท่า จะได้ไม่ต้องรอ 885 วิจริง
					# ปรับเป็น 1.0 เมื่อทดสอบเสร็จแล้วอยากรันความเร็วจริง


func _ready():
	if not Engine.has_singleton("GlobalTimeManager") and not _autoload_exists():
		push_error("GlobalTimeManagerTest: ไม่พบ Autoload ชื่อ 'GlobalTimeManager' กรุณาเช็ค Project Settings > Globals > Autoload")
		return
	GlobalTimeManager.second_tick.connect(_on_second_tick)
	GlobalTimeManager.phase_changed.connect(_on_phase_changed)
	GlobalTimeManager.hour_changed.connect(_on_hour_changed)
	GlobalTimeManager.encounter_window_started.connect(_on_encounter_started)
	GlobalTimeManager.encounter_window_ended.connect(_on_encounter_ended)
	GlobalTimeManager.level_time_ended.connect(_on_level_time_ended)

	Engine.time_scale = time_speed_multiplier   # <-- เพิ่มบรรทัดนี้

	print("=== GlobalTimeManager Test เริ่มทำงาน ===")
	print("ความเร็วเวลา: x%s (885 วิจริง จะใช้เวลาประมาณ %.1f วิ)" % [time_speed_multiplier, 885.0 / time_speed_multiplier])
	GlobalTimeManager.start_timer()

# ลบ _process(delta) ทั้งฟังก์ชันทิ้งไปเลย ไม่ต้องมี hack บวก elapsed_time เองแล้ว


func _autoload_exists() -> bool:
	return get_node_or_null("/root/GlobalTimeManager") != null


func _on_second_tick(current_second: int) -> void:
	# แสดงทุก 10 วิ กันสแปม log รกจอ
	if current_second % 10 == 0:
		print("[Tick] วินาทีที่ %d | Phase: %d | Hour: %d" % [
			current_second,
			GlobalTimeManager.current_phase,
			GlobalTimeManager.current_hour
		])


func _on_phase_changed(new_phase: int) -> void:
	print(">>> Phase เปลี่ยนเป็น: %d (วินาทีที่ %d)" % [new_phase, GlobalTimeManager.get_current_second()])


func _on_hour_changed(new_hour: int) -> void:
	print(">>> Hour เปลี่ยนเป็น: %d (วินาทีที่ %d)" % [new_hour, GlobalTimeManager.get_current_second()])


func _on_encounter_started() -> void:
	print(">>> [Encounter Window] เปิด (วินาทีที่ %d)" % GlobalTimeManager.get_current_second())


func _on_encounter_ended() -> void:
	print(">>> [Encounter Window] ปิด (วินาทีที่ %d)" % GlobalTimeManager.get_current_second())


func _on_level_time_ended() -> void:
	print("=== จบด่าน (885 วิ) — Test เสร็จสมบูรณ์ ===")
