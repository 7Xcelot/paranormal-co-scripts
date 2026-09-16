extends Node
class_name HunterPath

## วางเป็น Node เดียวใน Level scene (Hunter มีแค่ 1 ตัวต่อ Level ไม่ต้องมี Container หลายตัวแบบ EneAnoPath)

@export var staring_points: Array[Marker3D] = []

@export var hunting_final_point: Marker3D
@export var hunting_path_1: Array[Marker3D] = []
@export var hunting_path_2: Array[Marker3D] = []
@export var hunting_path_3: Array[Marker3D] = []

func get_random_hunting_path() -> Array[Marker3D]:
	var paths: Array = [hunting_path_1, hunting_path_2, hunting_path_3]
	return paths.pick_random()
