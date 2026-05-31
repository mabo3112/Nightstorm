class_name HealthComponent extends Node

signal health_changed(current: float, max: float)
signal died

@export var max_health := 100
var current_health := 0.0

func _ready() -> void:
	current_health = max_health
	#print("max health: " + str(max_health))
	#print("current health: " + str(current_health))
	_emit()
	
func damage(amount: float) -> void:
	current_health = clamp(current_health - amount, 0.0, max_health)
	_emit()
	if (current_health == 0.0):
		died.emit()
		
func heal(amount: float) -> void:
	current_health = clamp(current_health + amount, 0.0, max_health)
	_emit()

func _emit() -> void:
	health_changed.emit(current_health, max_health)
	#print("HP: %d / %d" % [current_health, max_health])
