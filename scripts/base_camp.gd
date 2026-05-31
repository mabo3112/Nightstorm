extends Node3D



@onready var player: CharacterBody3D = $Player
@onready var main_menu_camera: Camera3D = %MainMenuCamera
@onready var player_camera: Camera3D = $Player/CameraPivot/SpringArm3D/PlayerCamera

@onready var ui: Control = $UI

const MAIN_MENU = preload("uid://bojqu2ee3ondh")

var main_menu


var playerCameraPosition
var playerCameraRotation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# deactivate player until game is started
	playerCameraPosition = player_camera.global_position
	playerCameraRotation = player_camera.global_rotation
	player.process_mode = Node.PROCESS_MODE_DISABLED
	main_menu_camera.make_current()
	# add main menu UI
	main_menu = MAIN_MENU.instantiate()
	add_child(main_menu)
	main_menu.button_pressed.connect(buttons_pressed)
	# deactivate player UI for now until game starts
	ui.hide()
	
	# connect every node in "coin_stack" group to update_gold function in the UI 
	for coin_stack in get_tree().get_nodes_in_group("coin_stacks"):
		coin_stack.gold_pickedup.connect($UI.update_gold)

	
func buttons_pressed(button: String) -> void:
	match button: 
			"play":
					start_game()
			"settings":
					open_settings()
			"cengiz":
					print("Cengiz stinkt loool")
			"exit":
					get_tree().quit()
					
func start_game() -> void:
	main_menu.queue_free()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	# small offset so animation doesnt go into the face of the player and stops slightly behind
	var tweenOffset = Vector3(playerCameraPosition.x + 2, playerCameraPosition.y + 2, playerCameraPosition.z)
	tween.tween_property(main_menu_camera, "global_position", tweenOffset , 2.0)
	tween.parallel().tween_property(main_menu_camera, "global_rotation", playerCameraRotation, 2.0)
	tween.tween_callback(start_game_actually)
	
func start_game_actually() -> void:
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player_camera.make_current()
	ui.show()
	
	
func open_settings() -> void:
	print("SETTINGS TODO")
