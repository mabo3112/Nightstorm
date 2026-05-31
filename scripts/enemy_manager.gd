extends Node3D

const TOTAL_MAX_ENEMIES = 5000
const ZOMBIE = preload("uid://3xavsmg2bv1t")
const SKELETON = preload("uid://bchq6yfggxiy8")

var multimesh_instances: Dictionary = {}      # id -> MultiMeshInstance3D
var active_enemies: Dictionary = {}

func _ready():
	_setup_type(ZOMBIE)
	_setup_type(SKELETON)

func _setup_type(type: EnemyType) -> void:
	print("setting up type: ", type.id)
	var mm_instance = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.mesh = type.mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = type.max_count
	mm.visible_instance_count = 0
	mm_instance.multimesh = mm
	#mm_instance.position = Vector3(0, 2)
	add_child(mm_instance)

	print("instance count: ", mm.instance_count)
	print("visible count: ", mm.visible_instance_count)

	multimesh_instances[type.id] = mm_instance
	active_enemies[type.id] = []

func can_spawn_type(type_id: String) -> bool:
	var total = 0
	for id in active_enemies:
		total += active_enemies[id].size()
	#print("total alive: ", total, " / ", TOTAL_MAX_ENEMIES)
	if  total >= TOTAL_MAX_ENEMIES:
		return false
		
	#print("registering with type_id: ", type_id, " keys: ", multimesh_instances.keys())
	var mm = multimesh_instances[type_id].multimesh
	return active_enemies[type_id].size() < mm.instance_count

func register_enemy(enemy: BaseEnemy, type_id: String) -> int:
	
	if not can_spawn_type(type_id):
		return -1
	var index = active_enemies[type_id].size()
	active_enemies[type_id].append(enemy)
	var mm = multimesh_instances[type_id].multimesh
	mm.set_instance_transform(index, enemy.global_transform)
	mm.visible_instance_count = active_enemies[type_id].size()
	GameManager.enemy_count_change(1)
	return index

func unregister_enemy(type_id: String, index: int) -> void:
	var enemies = active_enemies[type_id]
	var last_index = enemies.size() - 1
	
	if index != last_index:
		# swap the last enemy into this slot
		var last_enemy = enemies[last_index]
		enemies[index] = last_enemy
		last_enemy.multimesh_index = index
	
	enemies.pop_back()
	var mm = multimesh_instances[type_id].multimesh
	mm.visible_instance_count = enemies.size()
	GameManager.enemy_count_change(-1)
	GameManager.kills_change(1)

func update_enemy_transform(type_id: String, index: int, transform3d: Transform3D) -> void:
	multimesh_instances[type_id].multimesh.set_instance_transform(index, transform3d)

func hide_enemy(type_id: String, index: int) -> void:
	var t = Transform3D(Basis(), Vector3(0, -10000, 0))
	multimesh_instances[type_id].multimesh.set_instance_transform(index, t)
	
func get_nearest_enemy(from: Vector3) -> BaseEnemy:
	var nearest: BaseEnemy = null
	var nearest_dist_sq: float = INF
	
	for type_id in active_enemies:
		for enemy in active_enemies[type_id]:
			if not is_instance_valid(enemy):
				continue
			var dist_sq = from.distance_squared_to(enemy.global_position)
			if dist_sq < nearest_dist_sq:
				nearest_dist_sq = dist_sq
				nearest = enemy
	
	return nearest
	
func alive_enemies() -> int:
	var total = 0
	for type_id in active_enemies:
		total += active_enemies[type_id].size()
	return total
