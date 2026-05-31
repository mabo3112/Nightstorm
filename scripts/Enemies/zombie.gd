class_name Zombie extends BaseEnemy
#@onready var health_ui: Node3D = $HealthUI
#
#func _ready():
	#health_ui.queue_free()
	#super._ready()





#@export var movement_speed: float = 10.0
#@export var stats_component: StatsComponent
#
## Navigation through World
#@onready var navigation_agent_3d: NavigationAgent3D = %NavigationAgent3D
#
## Player
#var player: CharacterBody3D = null
#
## Animations
#@onready var animation_tree: AnimationTree = %AnimationTree
#@onready var state_machine = animation_tree.get("parameters/playback")
#
## UI Healthbar 
#@onready var health_component: HealthComponent = %HealthComponent
#@onready var health_bar: ProgressBar = $HealthUI/SubViewport/Control/HealthBar
#
## HitboxComponent
#@onready var hitbox_component: HitboxComponent = %HitboxComponent
#
## Test values because of lack op component 
## TODO components for that lol
#var damage: float = 20
#@onready var attack_cooldown: Timer = %AttackCooldown
#var stillInside: bool = true
#var playerHealthComponent: HealthComponent
#var is_dead: bool = false
#var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
#
#
#var offset: int 
#
#var nav_update_timer: float = 0.0
#const NAV_UPDATE_INTERVAL: float = 0.5
#
#var current_anim: String = ""
#
#func _ready():
	#animation_tree.active = false
	#player = get_tree().get_first_node_in_group("player")
	#nav_update_timer = randf_range(0.0, 0.5)
	##first call to initialize hp 
	#_on_health_component_health_changed(health_component.current_health, health_component.max_health)
	#
#
#func _physics_process(delta: float) -> void:
	#if is_on_floor():
		#if velocity.length_squared() > 0.01:
			#set_anim("Run")
		#else:
			#set_anim("Idle")
	#else:
		#set_anim("jump")	
	  #
	## Apply gravity if the zombie is in the air
	#if not is_on_floor():
		#velocity.y -= gravity * delta
#
	#nav_update_timer += delta
	#if nav_update_timer >= NAV_UPDATE_INTERVAL:
		#nav_update_timer = 0.0
		#if player:
			#navigation_agent_3d.target_position = player.global_position
#
	## Check if the zombie has arrived or if the path is unreachable
	#if navigation_agent_3d.is_navigation_finished():
		#velocity.x = 0
		#velocity.z = 0
		#move_and_slide()
		#return
#
	## Get the next physical position along the path
	#var next_path_position: Vector3 = navigation_agent_3d.get_next_path_position()
	#var current_position: Vector3 = global_position
	#
	## Calculate direction vector (ignore vertical Y axis for horizontal movement)
	#var new_velocity: Vector3 = (next_path_position - current_position).normalized() * movement_speed
	#
	## Keep gravity's effect on the Y axis, update X and Z for pathfinding
	#velocity.x = new_velocity.x
	#velocity.z = new_velocity.z
#
	## Optional: Look at the target direction smoothly
	#var flat_velocity = Vector3(velocity.x, 0, velocity.z)
	#if flat_velocity.length_squared() > 0.01:
		#var target_look = global_position - flat_velocity
		#if global_position.distance_squared_to(target_look) > 0.01:
			#look_at(target_look, Vector3.UP)
#
	#move_and_slide()
#
#func set_anim(anim: String) -> void:
	#if current_anim == anim:
		#return
	#current_anim = anim
	#state_machine.travel(anim)
#
#func _on_health_component_health_changed(current: float, maxHealth: float) -> void:
	#if health_bar == null:
		#return
		#
	#print("health updated")
	#health_bar.value = current
	#health_bar.max_value = maxHealth
	#
#
#
#func _on_health_component_died() -> void:
	#if is_dead:
		#return
	#is_dead = true
	#GameManager.enemy_count_change(-1)
	#queue_free()
#
	#
#
#
#func _on_hitbox_component_area_entered(area: Area3D) -> void:
	#if area is HitboxComponent:
			#attack_cooldown.start()
			#health_component = area.owner.get_node_or_null("HealthComponent")
			#if health_component:
				#health_component.damage(damage)
			#
		#
#
#
#func _on_attack_cooldown_timeout() -> void:
	#if stillInside:
		#attack_cooldown.start()
		#if health_component:
				#health_component.damage(damage)
#
#
#func _on_hitbox_component_area_exited(area: Area3D) -> void:
	#stillInside = false
