extends Node

signal time_changed(current_time: float)
signal time_expired
signal hour_reached(hour: int)

const CYCLE_DURATION: float = 12 * 60
var current_time: float = 0.0
var running: bool = false 
var last_hour: int = 0
var timer: Timer
func start():
	current_time = 0.0
	last_hour = 0
	running = true 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1
	timer.timeout.connect(print_time)
	timer.start()

func print_time() -> void:
	timer.start()
	print("current time: " + str(current_time))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not running: 
		return
	current_time += delta * 5
	time_changed.emit(current_time)
	
	var hour = int(current_time / 60)
	if hour != last_hour and hour <= 12:
		if is_expired():
			time_expired.emit()
		last_hour = hour
		hour_reached.emit(hour)

func add_time(seconds: float):
	current_time = max(0.0, current_time - seconds)
	
func reset_time():
	current_time = 0.0
	
func get_progress() -> float:
	return clamp(current_time / CYCLE_DURATION, 0.0, 1.0)
	
func is_expired() -> bool:
	return current_time >= CYCLE_DURATION
