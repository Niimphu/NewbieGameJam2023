extends Panel

var scene_transition_speed_multiplier: float = 1.0

func _process(delta):
	if PlayerStatManager.scene_transitioning:
		if not is_equal_approx(PlayerStatManager.scene_transition_ratio, 1.0):
			PlayerStatManager.scene_transition_ratio = clampf(PlayerStatManager.scene_transition_ratio + (delta * scene_transition_speed_multiplier), 0.0, 1.0)
			material.set_shader_parameter("scene_transition_ratio", PlayerStatManager.scene_transition_ratio)
	else:
		if not is_equal_approx(PlayerStatManager.scene_transition_ratio, 0.0):
			PlayerStatManager.scene_transition_ratio = clampf(PlayerStatManager.scene_transition_ratio - (delta * scene_transition_speed_multiplier), 0.0, 1.0)
			material.set_shader_parameter("scene_transition_ratio", PlayerStatManager.scene_transition_ratio)

