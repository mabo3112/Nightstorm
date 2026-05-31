class_name BaseEnemy extends CharacterBody3D

@export var enemy_type: EnemyType

var multimesh_index: int = -1
var player: Node3D
var is_dying: bool = false

var is_climbing: bool = false
var was_climbing: bool = false
var nudge_cooldown: float = 0.0

var inside_player: bool = false
var hitbox_player: Area3D
#@onready var attack_cooldown: Timer = $AttackCooldown

var attack_cooldown = Timer.new()


func _ready():
	#print("base enemy ready, type: ", type_id)
	multimesh_index = EnemyManager.register_enemy(self,  enemy_type.id)
	#print("got index: ", multimesh_index)
	if multimesh_index == -1:
		queue_free()
		return
	player = get_tree().get_first_node_in_group("player")
	
	var health = get_node_or_null("HealthComponent")
	if health and health.has_signal("died"):
		health.died.connect(die)
		
	attack_cooldown.wait_time = enemy_type.attack_cooldown
	attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	add_child(attack_cooldown)

func _physics_process(delta):
	_move(delta)
	_update_visual()

func _move(delta):
	_check_climb()
	nudge_cooldown -= delta
	
	velocity.x = 0
	velocity.z = 0
	
	# gravity or climbing
	if is_climbing:
		velocity.y = enemy_type.speed * 1  # adjust climb speed
	elif not is_on_floor():
		velocity.y -= 9.8 * delta
	
	var dir = (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	
	if was_climbing and not is_climbing and nudge_cooldown <= 0:
		global_position += dir * 0.5
		nudge_cooldown = 0.5
	was_climbing = is_climbing
	
	var motion = Vector3(dir.x * enemy_type.speed * delta, velocity.y * delta, dir.z * enemy_type.speed * delta)
	var collision = move_and_collide(motion)
	
	if collision:
		var collider = collision.get_collider()
		if collider is Player:
			collider.global_position += collision.get_remainder()
	
	move_and_slide()

#func _move(delta):
	#
	#_check_climb()
	#
	#if is_climbing:
		#velocity.y = enemy_type.speed * 2
	#elif not is_on_floor():
		#velocity.y -= 9.8 * delta
	#
	##var position_before_frame = global_position
	#var dir = (player.global_position - global_position)
	#dir.y = 0
	#dir = dir.normalized()
	#
	#var motion = Vector3(dir.x * enemy_type.speed * delta, velocity.y * delta, dir.z * enemy_type.speed * delta)
	#var collision = move_and_collide(motion)
	#
	#move_and_slide()
	#
	#if collision:
		#var collider = collision.get_collider()
		#if collider is Player:
			## push player by the leftover motion enemy couldnt do
			#collider.global_position += collision.get_remainder()
	##velocity.x = dir.x * speed
	##velocity.z = dir.z * speed
	##move_and_slide()
	#
	#for i in get_slide_collision_count():
		#collision = get_slide_collision(i)
		#var collider = collision.get_collider()
		#if collider is Player:
			#global_position = position_before_frame
		#
	##if player:
		##var dist = global_position.distance_to(player.global_position)
		##if dist < 0.05:
			##var push_dir = (player.global_position - global_position).normalized()
			##push_dir.y = 0
			##
			##player.move_and_collide(push_dir * speed * delta)		

func _update_visual():
	var visual_transform = global_transform
	var dir_to_player = player.global_position - global_position
	dir_to_player.y = 0
	if dir_to_player.length_squared() > 0.01:
		visual_transform.basis = Basis.looking_at(-dir_to_player.normalized(), Vector3.UP)
	EnemyManager.update_enemy_transform(enemy_type.id, multimesh_index, visual_transform)

func _check_climb() -> void:
	var space_state = get_world_3d().direct_space_state
	var dir = (player.global_position - global_position)
	dir.y = 0
	dir = dir.normalized()
	
	var from = global_position + Vector3(0, 0.1, 0)
	var to = from + dir * 2
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	query.collision_mask = 1
	var result = space_state.intersect_ray(query)
	if result:
		is_climbing = true
	else:
		is_climbing = false
	 
	

	


func get_aim_point() -> Vector3:
	return global_position + Vector3(0, enemy_type.height * 1, 0)
	
func _on_hitbox_component_area_entered(area: Area3D) -> void:
	#print("hitbox entered wohoo")
	if area is HitboxComponent:
		inside_player = true
		hitbox_player = area
		
		
		attack_cooldown.start()
		var health = area.owner.get_node_or_null("HealthComponent")
		if health:
			health.damage(enemy_type.damage)
		
		var player_body = area.owner
		if player_body is Player:
			var knockback_dir = global_position.direction_to(player_body.global_position)
			#print("knockback_dir: " +str(knockback_dir))
			knockback_dir.y = 0.04
			knockback_dir *= 30
			#print("knockback after force: " + str(knockback_dir))
			#player_body.apply_knockback(knockback_dir)

func _on_attack_cooldown_timeout() -> void:
	#print("on attack cooldown triggered")
	if inside_player:
		attack_cooldown.start()
		var health = hitbox_player.owner.get_node_or_null("HealthComponent")
		if health:
			health.damage(enemy_type.damage)
				
func _on_hitbox_component_area_exited(area: Area3D) -> void:
	inside_player = false

func die():
	if is_dying:
		return
	is_dying = true
	EnemyManager.unregister_enemy(enemy_type.id, multimesh_index)
	queue_free()
