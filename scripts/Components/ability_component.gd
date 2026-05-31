class_name AbilityComponent extends Node

const FIREBALL = preload("uid://xchdxof4fno7")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


	
func cast(global_position: Vector3):
	fireballInstantiate(global_position)

func fireballInstantiate(spawn_position: Vector3) -> void:
	print("Alive Enemies:" + str(EnemyManager.alive_enemies()))
	if EnemyManager.alive_enemies() > 0:
		var fireball = FIREBALL.instantiate()
		get_tree().current_scene.add_child(fireball)
		fireball.global_position = spawn_position
	
	
