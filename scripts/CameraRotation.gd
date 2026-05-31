extends Marker3D


@export var rotation_speed: float = 0.2


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate_y(rotation_speed * delta)
