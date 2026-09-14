extends Node
class_name EneAnoPath

## วางเป็น child node ใน Level scene หนึ่งตัวต่อ Enemy หนึ่งตัวที่ Level นั้นใช้
## entity_key ต้องตรงกับ key ใน library_scene ของ EneAnoSpawner เช่น "Attack/The_Intruder"

@export var entity_key: String = ""
@export var stage_1: Node3D   # Marker ที่ Cam มองเห็นตอน Stage 1
@export var stage_2: Node3D   # Marker ที่ Cam มองเห็นตอน Stage 2
@export var stage_3: Node3D   # Marker ตอน Stage 3 (อาจเป็น Mission Point)
