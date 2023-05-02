extends Area2D

func _on_body_entered(body):
	if body.is_class("CharacterBody2D"):
		PlayerStatManager.health = 100
		PlayerStatManager.sprouts_collected += 1
		queue_free()
