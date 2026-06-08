extends Node3D

@onready var minute_hand: Node3D = %MinuteHand

@onready var progress_overlay: MeshInstance3D = %ProgressOverlay
var progress_overlay_material: ShaderMaterial


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	TimeManager.time_changed.connect(_update)
	TimeManager.time_expired.connect(_on_expired)
	progress_overlay_material = progress_overlay.get_active_material(0)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _update(_time: float):
	var progress = TimeManager.get_progress()
	minute_hand.rotation.y = -progress * TAU
	progress_overlay_material.set_shader_parameter("progress", progress)
	

func _on_expired():
	progress_overlay_material.set_shader_parameter("overlay_color", Color(Color.FIREBRICK))
