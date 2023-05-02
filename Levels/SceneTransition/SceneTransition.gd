extends Area2D

@export var new_scene: PackedScene

@onready var scene_change_timer: Timer = $SceneChangeTimer

func _on_body_entered(_body:Node2D):
	if not new_scene:
		print("Error: No scene selected for SceneTransition.")
		return

	scene_change_timer.start()
	PlayerStatManager.scene_transitioning = true

func _on_scene_change_timer_timeout():
	get_tree().change_scene_to_packed(new_scene)
	PlayerStatManager.player_stat_refresh()
