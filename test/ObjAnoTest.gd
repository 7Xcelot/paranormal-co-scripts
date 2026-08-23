# ObjAnoTest.gd — แนบกับ node ชั่วคราวใน scene (หรือ autoload ชั่วคราวก็ได้)
extends Node

@export var target: ObjAno  # ลาก E1 มาใส่ใน Inspector

func _ready():
	target.state_changed.connect(_on_state_changed)
	target.anomaly_triggered.connect(func(id): print("[VISUAL] %s → ผิดปกติ!" % id))
	target.anomaly_reverted.connect(func(id): print("[VISUAL] %s → กลับปกติ" % id))

func _on_state_changed(new_state):
	print("[%.1fs] %s → %s" % [GlobalTimeManager.elapsed_time, target.entity_id, ObjAno.State.keys()[new_state]])

func _input(event):
	# กด R เพื่อจำลองการ report ด้วยมือ ระหว่างเทส
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		var success = target.try_report()
		print("ลอง report ด้วยมือ → %s" % ("สำเร็จ" if success else "ล้มเหลว (ไม่ได้อยู่ Anomaly Stage)"))
