extends Control

signal button_pressed


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_play_pressed() -> void:
	button_pressed.emit("play")

func _on_settings_pressed() -> void:
	button_pressed.emit("settings")


func _on_cengiz_pressed() -> void:
	button_pressed.emit("cengiz")


func _on_exit_pressed() -> void:
	button_pressed.emit("exit")
