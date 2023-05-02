extends Node

# Emitted when the player's health changes
signal player_health_changed
# Emitted when the player presses the input for toggling the parasol
signal player_toggle_parasol(state: bool)
# Emitted when the parasol is finished either opening or closing
signal player_parasol_state_changed
signal start_health_regen_timer
signal player_died

const MAX_HEALTH: float = 100
const SUNLIGHT_DAMAGE_PER_SECOND: float = 16
const PASSIVE_HEALING_PER_SECOND: float = 5

var health: float
var is_alive: bool
# Used to determine the animation state of the parasol
var parasol_opening: bool = false

# The current open or closed state of the parasol, used for direct sunlight checks
var parasol_open: bool = false

var can_regenerate_health: bool = true
var is_in_shade: bool = true

func _ready():
	self.connect("player_parasol_state_changed", _on_player_parasol_state_changed)
	health = MAX_HEALTH
	is_alive = true

func _process(delta):
	if health <= 0 and is_alive:
		is_alive = false
		player_died.emit()
		DirectSunlightManager.set_process(false)
		guess_ill_die()
	if DirectSunlightManager.is_processing():
		if DirectSunlightManager.player_in_sunlight and not parasol_open:
			health = clampf(health - (SUNLIGHT_DAMAGE_PER_SECOND * delta), 0.0, MAX_HEALTH)
			can_regenerate_health = false
			is_in_shade = false
			emit_signal("player_health_changed")
		elif not is_in_shade and (not DirectSunlightManager.player_in_sunlight or parasol_open):
			is_in_shade = true
			emit_signal("start_health_regen_timer")
		elif health < MAX_HEALTH and can_regenerate_health:
			health = clampf(health + (PASSIVE_HEALING_PER_SECOND * delta), 0.0, MAX_HEALTH)
			emit_signal("player_health_changed")
	
	if Input.is_action_just_pressed("toggle_parasol"):
		parasol_opening = not parasol_opening
		emit_signal("player_toggle_parasol", parasol_opening)

func _on_player_parasol_state_changed():
	parasol_open = parasol_opening

func _on_regen_delay_timer_timeout():
	can_regenerate_health = true

func guess_ill_die():
	await get_tree().create_timer(3).timeout

	get_tree().reload_current_scene()
	health = MAX_HEALTH
	is_alive = true