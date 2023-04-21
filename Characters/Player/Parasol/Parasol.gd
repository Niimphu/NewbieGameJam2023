extends AnimatedSprite2D

func _ready():
	PlayerStatManager.connect("player_toggle_parasol", _on_player_toggle_parasol)
	
func _on_player_toggle_parasol(parasol_toggled_on: bool):
	if parasol_toggled_on:
		play()
	else:
		play_backwards()

func _on_animation_finished():
	PlayerStatManager.emit_signal("player_parasol_state_changed")
