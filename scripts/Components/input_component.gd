class_name InputComponent extends Node


var move_dir: Vector2 = Vector2.ZERO
var jump_pressed := false
var interaction_pressed := false
var ability_one_pressed := false
var freeflying := false

func update() -> void:
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	jump_pressed = Input.is_action_just_pressed("jump")
	interaction_pressed = Input.is_action_just_pressed("interact")
	ability_one_pressed = Input.is_action_just_pressed("ability_one")
	freeflying = Input.is_action_just_pressed("freefly")
