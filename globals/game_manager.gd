extends Node


signal enemy_count_changed(value: int)
signal kills_changed(value: int)
var enemy_count: int = 0
var kills: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	DebugAPI.enable_all_monitors()
	
func enemy_count_change(value: int):
	enemy_count += value
	enemy_count_changed.emit(enemy_count)
	
func kills_change(value: int):
	kills += value 
	kills_changed.emit(kills)
