extends Area3D


var speed: float = 40
var damage: float = 100

var target_enemy: BaseEnemy = null
var turn_speed: float = 30.0

@onready var despawn_timer: Timer = $DespawnTimer
@onready var player: Player 
@export var hit_radius_sq: float = 20.0 
@export var despawn_time: float
func _ready() -> void:
	despawn_timer.wait_time = despawn_time
	despawn_timer.start()
	player = get_tree().get_first_node_in_group("player")
	target_enemy = EnemyManager.get_nearest_enemy(player.global_position)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if target_enemy != null and is_instance_valid(target_enemy):
			var target_pos = target_enemy.get_aim_point()
			var desired_dir = (target_pos - global_position).normalized()
			var current_dir = -global_transform.basis.z
			var new_dir = current_dir.lerp(desired_dir, turn_speed * delta).normalized()
			look_at(global_position + new_dir, Vector3.UP)
		
	global_position += -global_transform.basis.z * speed * delta 
		
	

	
func _on_area_entered(area: Area3D) -> void:
	if area is HitboxComponent:
		#print("owner: ", area.owner)
		#print("owner children: ", area.owner.get_children())
		var health = area.owner.get_node_or_null("HealthComponent")
		#print("health found: ", health)
		if health:
			health.damage(damage)
		queue_free()
	
		
	


func _on_body_entered(body: Node3D) -> void:
	print("fireball collided with worldasdasdasd")
	queue_free()


func _on_despawn_timer_timeout() -> void:
	print("Fireball living too long -> despawning now.")
	queue_free()
