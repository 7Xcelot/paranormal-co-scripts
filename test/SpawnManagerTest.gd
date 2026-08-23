extends Node
# ทดสอบ SpawnManager ด้วยข้อมูลจำลอง (mock) ก่อนที่ ObjAno.gd/EneAno.gd จะเขียนเสร็จจริง
# วิธีใช้: แนบกับ node ไหนก็ได้ใน scene ทดสอบ แล้วกด F5/F6

func _ready():
	print("=== SpawnManager Test เริ่มทำงาน ===")

	# จำลอง whitelist ของ Level 1 ตาม Enemy_List.md
	var mock_whitelist: Array[String] = ["The Krasue", "The Shadow", "The Spirit", "The Petra", "The Intruder"]
	SpawnManager.load_level_config(1, mock_whitelist, 3) # capacity มั่ว 3 ไว้ก่อน

	# --- ทดสอบ Obj.Ano cap 6 ---
	print("\n--- ทดสอบ Obj.Ano Cap ---")
	SpawnManager.obj_ano_sleep_changed.connect(func(sleeping): print("Obj.Ano sleep state: ", sleeping))

	for i in range(7):
		if SpawnManager.can_spawn_obj_ano():
			SpawnManager.register_obj_ano_spawned()
			print("Spawn Obj.Ano ตัวที่ %d สำเร็จ (active: %d)" % [i + 1, SpawnManager.active_obj_ano_count])
		else:
			print("Spawn Obj.Ano ตัวที่ %d ล้มเหลว (เต็ม cap แล้ว)" % [i + 1])

	print("Report 1 ตัว...")
	SpawnManager.register_obj_ano_reported()
	print("Active Obj.Ano ตอนนี้: ", SpawnManager.active_obj_ano_count)

	# --- ทดสอบ Ene.Ano selection ไม่ซ้ำ + capacity ---
	print("\n--- ทดสอบ Ene.Ano Spawn Selection (capacity 3, whitelist 5 ตัว) ---")
	for i in range(5):
		var chosen := SpawnManager.request_ene_ano_spawn()
		if chosen == "":
			print("Spawn Ene.Ano ครั้งที่ %d: ล้มเหลว (เต็ม capacity หรือ whitelist หมด)" % [i + 1])
		else:
			print("Spawn Ene.Ano ครั้งที่ %d: ได้ '%s' (active: %s)" % [i + 1, chosen, SpawnManager.active_ene_ano_ids])

	print("\nDespawn 'The Krasue'...")
	SpawnManager.register_ene_ano_despawned("The Krasue")
	print("Active Ene.Ano ตอนนี้: ", SpawnManager.active_ene_ano_ids)

	var chosen_again := SpawnManager.request_ene_ano_spawn()
	print("Spawn อีกครั้งหลัง despawn: ได้ '%s'" % chosen_again)

	print("\n=== Test จบ ===")
