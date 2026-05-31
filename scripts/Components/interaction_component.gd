class_name InteractionComponent extends Area3D

signal interacted

@export var prompt_message: String
@onready var prompt_label: Label3D = $PromptLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#collision_layer = 10 # Interaction Layer 10 would be 512 btw because of this funny binary bit thingy that I definitely didnt freak out about on 22.05.26
	collision_mask = 0  
	monitoring = false  
	monitorable = true
	prompt_label.text = prompt_message

func interact():
	interacted.emit()
	
func show_prompt():
	prompt_label.visible = true

func hide_prompt():
	prompt_label.visible = false
