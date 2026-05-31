class_name MovementComponent extends Node

@export var body: CharacterBody3D
@export var model: Node3D
@export var speed := 8.0
@export var jump_velocity := 12.0
@export var gravity_multiplier := 3.0
@export var fly_speed := 15.0
var freefly := false 
var direction: Vector2 = Vector2.ZERO
var wants_jump := false
var basis: Basis
var move_dir : Vector3 = Vector3.ZERO
@onready var collider: CollisionShape3D = %Collider


func tick(delta: float) -> void:
	if (body == null):
		return
	
	if freefly:
		var input_space := Vector3(-direction.x, 0, -direction.y)
		move_dir = (basis * input_space).normalized()
		body.velocity = move_dir * fly_speed
		body.move_and_slide()
		return

	# Movement relative to camera direction
	move_dir = (basis * Vector3(-direction.x, 0, -direction.y))
	move_dir.y = 0
	move_dir = move_dir.normalized()

	body.velocity.x = move_dir.x * speed 
	body.velocity.z = move_dir.z * speed 
	
	
	# Gravity 
	if (not body.is_on_floor()):
		body.velocity += body.get_gravity() * delta * gravity_multiplier
	
		
	# Jump
	if (wants_jump and body.is_on_floor()):
		body.velocity.y = jump_velocity
	wants_jump = false 
	
	body.move_and_slide()
		
	if model and direction.length_squared() > 0.001:
		model.look_at(model.global_position - move_dir, Vector3.UP)
	
		
# 2. Transform that direction using the full camera basis matrix
# This angles your forward vector up/down/sideways to match your exact gaze


# 3. Apply your flying speed directly to the CharacterBody3D velocity array
# (We don't multiply by delta here because move_and_slide handles delta internally)


# 4. Execute the movement with sliding physics

		
		
		


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
