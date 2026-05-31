class_name Player extends CharacterBody3D

@export_group("Camera")
@export_range(0.1, 2.0) var mouse_sensitivity := 0.25
@export var look_speed : float = 0.002

# Components
@onready var input_component: InputComponent = %InputComponent
@onready var movement_component: MovementComponent = %MovementComponent
@onready var ability_component: AbilityComponent = %AbilityComponent

@onready var collider: CollisionShape3D = %Collider
@onready var camera_pivot: Node3D = %CameraPivot
@onready var spring_arm_3d: SpringArm3D = %SpringArm3D
@onready var player_camera: Camera3D = %PlayerCamera
@onready var right_hand: Marker3D = %RightHand

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

# UI node because I dont have gameManagerRightNowLol So the common parent right now would be every level. and levels change so I would have to implent
# it in every level so for now I do it here
@onready var health_bar: ProgressBar = $"../UI/Control/HealthBar"

var mouse_captured : bool = true
var current_interactable = null
var freeflying : bool = false

var look_rotation : Vector2



const DEATH_SCREEN = preload("uid://dtpfd4uij38f4")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spring_arm_3d.add_excluded_object(self.get_rid())
	animation_tree.active = true
	add_to_group("player")
	


func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	if Input.is_action_pressed("interact"):
		activate()
	if Input.is_action_just_pressed("ability_one"):
		ability_component.cast(right_hand.global_position)
	# Look around
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.screen_relative)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# READ CONTROLS
	input_component.update()
	
	# READ MOVEMENT COMPONENT
	movement_component.direction = input_component.move_dir
	movement_component.wants_jump = input_component.jump_pressed
	movement_component.basis = camera_pivot.global_transform.basis
	if input_component.freeflying:
		freeflying = !freeflying
		collider.disabled = !collider.disabled
	movement_component.freefly = freeflying
	movement_component.tick(delta)
	
	
	
	
	if is_on_floor():
		if velocity.length() > 0.1:
			state_machine.travel("Running_A")
		else:
			state_machine.travel("Idle")
	else:
		state_machine.travel("Jump_Full_Short")	
	
	# Interaction
	if Input.is_action_pressed("interact"):
		activate()
		
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(-55), deg_to_rad(80))
	look_rotation.y -= rot_input.x * look_speed
	#transform.basis = Basis()
	#rotate_y(look_rotation.y)
	camera_pivot.transform.basis = Basis()
	camera_pivot.rotate_x(-look_rotation.x)
	camera_pivot.rotate_y(look_rotation.y)
	

	
func enable_freefly():
	collider.disabled = true
	freeflying = true

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false
	
func _on_interaction_area_area_entered(area: Area3D) -> void:
	if area is InteractionComponent:
		current_interactable = area
		current_interactable.show_prompt()
		
		
	


func _on_interaction_area_area_exited(area: Area3D) -> void:
	if area == current_interactable and is_instance_valid(current_interactable):
		current_interactable.hide_prompt()
		current_interactable = null
		
func activate():
	if current_interactable:
		current_interactable.interact()


func _on_health_component_health_changed(current: float, maxHealth: float) -> void:
	if health_bar == null:
		return
		
	print("health updated")
	health_bar.value = current
	health_bar.max_value = maxHealth


func _on_health_component_died() -> void:
	var death_screen = DEATH_SCREEN.instantiate()
	get_tree().root.add_child(death_screen)
	release_mouse()
