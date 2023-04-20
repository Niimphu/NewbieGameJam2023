extends Node

signal player_health_changed

const MAX_HEALTH: float = 100
const SUNLIGHT_DAMAGE_PER_SECOND: float = 10
const PASSIVE_HEALING_PER_SECOND: float = 5

var health: float

func _ready():
	health = MAX_HEALTH

func _process(delta):
	if DirectSunlightManager.player_in_sunlight:
		health = clampf(health - (SUNLIGHT_DAMAGE_PER_SECOND * delta), 0.0, MAX_HEALTH)
		emit_signal("player_health_changed")
	elif health < MAX_HEALTH:
		health = clampf(health + (PASSIVE_HEALING_PER_SECOND * delta), 0.0, MAX_HEALTH)
		emit_signal("player_health_changed")
