extends TextureRect

@export var transition_speed_multiplier: float = 1.0

var vignette_alpha: float = 0.0

func _ready():
	material.set_shader_parameter("vignette_alpha", vignette_alpha)

func _process(delta):
	if DirectSunlightManager.player_in_sunlight and not PlayerStatManager.parasol_open and PlayerStatManager.is_alive:
		if not is_equal_approx(vignette_alpha, 1.0):
			vignette_alpha = clampf(vignette_alpha + (delta * transition_speed_multiplier), 0.0, 1.0)
			material.set_shader_parameter("vignette_alpha", vignette_alpha)
	elif not is_equal_approx(vignette_alpha, 0.0):
		vignette_alpha = clampf(vignette_alpha - (delta * transition_speed_multiplier), 0.0, 1.0)
		material.set_shader_parameter("vignette_alpha", vignette_alpha)
