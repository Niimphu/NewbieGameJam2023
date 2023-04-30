extends Sprite2D

signal health_bar_update(fill_ratio: float)

@onready var visibility_timer: Timer = $VisibilityTimer

func _ready():
	connect("health_bar_update", _on_health_bar_update)
	visible = false

func _on_health_bar_update(fill_ratio: float):
	material.set_shader_parameter("fill_ratio", fill_ratio)
	visible = true
	visibility_timer.start()

func _on_visibility_timer_timeout():
	# Hide the health bar after the enemy has not taken damage for a designated amount of time.
	visible = false
