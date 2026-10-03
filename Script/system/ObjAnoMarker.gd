extends Marker3D
class_name ObjAnoMarker

## แนบกับ Marker3D แต่ละจุดในเลเวล เป็นแค่ตัวบอกตำแหน่ง+ชนิด
## ไม่มี logic อะไรเอง รอ ObjAnoSpawner มาอ่านค่าแล้วแทนที่ตอน _ready()

@export var anomaly_key: String = ""          # path ไปยัง node ใน ObjAnoLibrary.tscn เช่น "Disappear/Anomaly_ChairDisappear"
@export var entity_id_override: String = ""   # เว้นว่างได้ จะใช้ชื่อ marker node แทน
