extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var spawn_marker: Marker3D = $SpawnMarker
@onready var ui: Control = $UI

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TimeManager.start()
	ui.show()

	
