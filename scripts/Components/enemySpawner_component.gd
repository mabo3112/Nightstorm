class_name EnemySpawnerComponent extends Node3D


const ZOMBIE = preload("uid://ca1lq2ki71scg")
const SKELETON = preload("uid://bc40w5u1yyk31")
const ENEMIES: Array[PackedScene] = [ZOMBIE, SKELETON]

@export var MIN_DISTANCE: float 
@export var MAX_DISTANCE: float
@export var spawn_interval: float
@export var type_change_value: int = 0

@onready var enemies_container: Node3D = get_tree().current_scene.get_node("Enemies")

var type_change: int = 0
var selected_scene: PackedScene 
var player: Player

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = spawn_interval
	timer.timeout.connect(spawn_enemy)
	timer.start()

	
func get_player() -> Player:
	player = get_tree().get_first_node_in_group("player")
	return player
	
func get_spawn_position() -> Vector3:
	player = get_player()
	if not player:
		return Vector3.ZERO
	
	var angle = randf() * TAU
	var distance = randf_range(MIN_DISTANCE, MAX_DISTANCE)
	var offset = Vector3(cos(angle) * distance, 0, sin(angle) * distance)
	var flat_position = player.global_position + offset 
	
	# raycast down to figure out terrain height
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		flat_position + Vector3(0, 100, 0),
		flat_position + Vector3(0, -100, 0)
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position + Vector3(0, 0, 0)
	else:
		return Vector3.ZERO
	
	
	
func spawn_enemy() -> void:
	if type_change >= 0:
		selected_scene = ENEMIES.pick_random()
		type_change = -type_change_value
	type_change += 1
			
	var enemy = selected_scene.instantiate()
	var type_id = enemy.enemy_type.id 
			
	if not EnemyManager.can_spawn_type(type_id):
		enemy.queue_free()
		return
	
	var spawn_pos = get_spawn_position()
	
	if spawn_pos == Vector3.ZERO:
		enemy.queue_free()
		return
		
	enemy.position = spawn_pos
	enemies_container.add_child(enemy)
		

	
	
	
	
	
