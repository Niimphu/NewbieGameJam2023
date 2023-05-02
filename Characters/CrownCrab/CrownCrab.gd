extends CharacterBody2D

# I can't make this an export variable because it is used in the export_range for the MAX_WANDER_DURATION_SECONDS
# and Godot doesn't like an export being used inside of an export.
const MIN_WANDER_DURATION_SECONDS: float = 1.0

@export_group("Enemy Properties")

@export var TAKE_DAMAGE_FORCE: Vector2 = Vector2(50.0, -150)
@export var MAX_HEALTH: int = 3

@export_subgroup("Movement")

## The speed at which the enemy slows down after it stops wandering.
@export var DECELERATION: float = 10.0

## The speed at which the enemy speeds up when it begins wandering.
@export var ACCELERATION: float = 30.0

## The maximum velocity the enemy can accelerate to while wandering.
@export var MAX_WANDER_VELOCITY: float = 100.0

@export_subgroup("Wander Behavior")

## The percentage chance (between 0% and 100%) that the enemy will begin wandering when a wander check is performed.
@export_range(0, 100) var WANDER_CHANCE_PECENTAGE: int = 80

## The distance threshold (in pixels) when the enemy will decide to turn back and head toward its home location when it wanders next.
@export var MAX_WANDER_DISTANCE: float = 200.0

## The number of seconds between each wander check. Wander checks are only performed while the enemy is not currently wandering.
@export var WANDER_CHECK_SECONDS: float = 2.0

## The maximum number of seconds that the enemy can wander before it stops wandering.
@export_range(MIN_WANDER_DURATION_SECONDS, 10) var MAX_WANDER_DURATION_SECONDS: float = 5.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var enemy_health_bar: Sprite2D = $EnemyHealthBar
@onready var hit_particles: CPUParticles2D = $HitParticles

var death_particle_explosion_scene = preload("res://Characters/CrownCrab/CrownCrabDeathParticleExplosion.tscn")
var home_position: Vector2
var is_wandering: bool = false
var current_wander_check_seconds: float
var current_wander_duration_seconds: float
var wander_direction: int
var is_invincible: bool = false
var health: int = MAX_HEALTH

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	# Set the enemy's home position to the position it spawned on.
	home_position = global_position
	
	# Setting the initial wander direction randomly so that all enemies in the level don't initially wander in the same direction.
	randomize()
	var random_directions = [-1, 1]
	wander_direction = random_directions[randi() % random_directions.size()]

func _process(delta):
	# If the enemy is currently wandering we want to let the current wander duration to run out before doing anything else
	if current_wander_duration_seconds > 0:
		current_wander_duration_seconds = clampf(current_wander_duration_seconds - delta, 0.0, MAX_WANDER_DURATION_SECONDS)
		return
	else:
		is_wandering = false

	if is_invincible:
		return
	
	# We give the enemy a chance of wandering each time the current wander check seconds variable reaches 0
	if current_wander_check_seconds > 0:
		current_wander_check_seconds = clampf(current_wander_check_seconds - delta, 0.0, WANDER_CHECK_SECONDS)
		return
	
	# We roll the dice and see if the enemy is going to wander this time or if it will be lazy and just stand around
	is_wandering = (randi_range(0, 100) <= WANDER_CHANCE_PECENTAGE)
	current_wander_check_seconds = WANDER_CHECK_SECONDS
	
	if not is_wandering:
		# The enemy decided to be lazy and stand around.

		return
	
	# The enemy decided to wander so we need to generate a random number of seconds for it to wander before it decides to stop.
	current_wander_duration_seconds = randf_range(MIN_WANDER_DURATION_SECONDS, MAX_WANDER_DURATION_SECONDS)
	
	# If the enemy is too far away from home we need to make it wander back toward home,
	# otherwise we just make it wander the opposite direction that it was wandering before.
	if home_position.distance_to(global_position) > MAX_WANDER_DISTANCE:
		wander_direction = roundi(Vector2(global_position.x, 0).direction_to(Vector2(home_position.x, 0)).x)
	else:
		wander_direction = -wander_direction

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	if is_wandering:
		velocity.x = clampf(velocity.x + (wander_direction * ACCELERATION), -MAX_WANDER_VELOCITY, MAX_WANDER_VELOCITY)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, DECELERATION)

	if velocity:
		animated_sprite.play()
	else:
		animated_sprite.pause()

	move_and_slide()
	update_rotation()
	
func update_rotation():
	if is_on_floor():
		var normal: Vector2 = get_floor_normal() #match angle of sprite to angle of floor
		animated_sprite.rotation = normal.angle() + 1.571 #this is 90 degrees in rads

func _on_hit_detection_area_2d_area_entered(area:Area2D):
	if is_invincible:
		return

	health -= 1

	if health == 0:
		var death_particle_explosion = death_particle_explosion_scene.instantiate()
		get_tree().get_first_node_in_group("level_root_node").add_child(death_particle_explosion)
		death_particle_explosion.global_position = global_position
		visible = false
		queue_free()
		return

	is_wandering = false
	is_invincible = true
	invincibility_timer.start()
	var knockback_direction = -sign(global_position.direction_to(area.global_position).x)
	velocity = Vector2(knockback_direction * TAKE_DAMAGE_FORCE.x, TAKE_DAMAGE_FORCE.y)
	hit_particles.emitting = true
	enemy_health_bar.emit_signal("health_bar_update", float(health) / MAX_HEALTH)

func _on_invincibility_timer_timeout():
	is_invincible = false
