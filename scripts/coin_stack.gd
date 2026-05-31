extends StaticBody3D

signal gold_pickedup


@onready var interaction_component: InteractionComponent = %InteractionComponent

func _ready():
	interaction_component.interacted.connect(interact)
	add_to_group("coin_stacks")

func interact():
	print("Picked up the item")
	gold_pickedup.emit(100)
	queue_free()
	
