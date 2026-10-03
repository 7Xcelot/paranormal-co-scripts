extends Node
class_name GameOverThreatTest

@export var game_over_threat: GameOverThreat  # ลาก node GameOverThreat มาใส่ใน Inspector

func _ready() -> void:
	if game_over_threat == null:
		push_error("GameOverThreatTest: ยังไม่ได้ตั้งค่า game_over_threat")
		return

	game_over_threat.target_id = "playerpoint"
	game_over_threat.countdown_duration = 8.0   # ย่อจาก 40s เหลือ 8s เพื่อทดสอบเร็วๆ
	game_over_threat.report_window_duration = 5.0

	game_over_threat.state_changed.connect(_on_state_changed)
	game_over_threat.threat_expired.connect(_on_expired)
	game_over_threat.threat_resolved.connect(_on_resolved)

	print("GameOverThreatTest: เริ่ม countdown 8 วินาที — ลองสลับกล้องไปเลข 6 (เห็น playerpoint) ก่อนหมดเวลา")
	game_over_threat.start()

func _on_state_changed(_threat, new_state) -> void:
	print("GameOverThreat state -> ", GameOverThreat.State.keys()[new_state])

func _on_expired(_threat) -> void:
	print("!! GAME OVER (จำลอง) !! countdown หมดเวลาโดยไม่ได้ pause")

func _on_resolved(_threat) -> void:
	print(">> Threat resolved (report สำเร็จ)")
