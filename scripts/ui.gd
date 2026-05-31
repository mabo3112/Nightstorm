extends Control




@onready var fps: Label = %FPS
@onready var gold: Label = %Gold
@onready var enemy_count: Label = %EnemyCount
@onready var kills: Label = %Kills
@onready var health_bar: ProgressBar = $Control/HealthBar

var goldies = 0

func _ready() -> void:
	gold.text = "Gold: " + str(goldies)
	health_bar.value = health_bar.max_value
	
	GameManager.enemy_count_changed.connect(update_enemy_count)
	GameManager.kills_changed.connect(update_kills)
func _process(delta: float) -> void:
	fps.text = "FPS: " + str(Engine.get_frames_per_second())

func update_gold(value) -> void:
	goldies += value
	gold.text = "Gold: " + str(goldies)
	
func update_health(current: float, maxHealth: float) -> void:
	health_bar.max_value = maxHealth
	health_bar.value = current
	
func update_enemy_count(value: int) -> void:
	enemy_count.text = "Enemy Count: " + str(value)
	
func update_kills(value: int) -> void:
	kills.text = "Kills: " + str(value)
	
	
	
	
