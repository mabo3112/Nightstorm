extends Area3D

@onready var interaction_component: InteractionComponent = %InteractionComponent

@export_file("*.tscn") var target_scene: String
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interaction_component.interacted.connect(interact)



	
func interact():
	if target_scene:
		get_tree().change_scene_to_file(target_scene)
