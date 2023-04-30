extends CharacterBody2D

@export var DECELERATION: float = 30.0
@export var ACCELERATION: float = 40.0
@export var JUMP_VELOCITY: float = -460.0
@export var MAX_WALK_VELOCITY: float = 250.0
@export var ATTACKING_VELOCITY_MOD: float = 0.5
@export var PARASOL_GRAVITY_MODIFIER: float = 0.25
@export var OBJECT_PUSH_FORCE: float = 2000.0
@export var SHADOW_TRANSITION_SCALE: float = 1.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var attack_area2D: Area2D = $AttackArea2D
@onready var regen_delay_timer: Timer = $RegenDelayTimer
@onready var toggle_parasol_cooldown: Timer = $ToggleParasolCooldown

# The initial scale of the sprite to be used to flip the sprite and preserve its position
# so that it will stay within the CollisionShape2D.
@onready var sprite_scale = sprite.get_scale()

var shader_shadow_scale: float = 0.0

# This enum represents the different possible states of the Parasol animation
enum PARASOL_STATES {
	CLOSED = -1,
	OPEN = 1
}

# This enum represents the different possible states of the Parasol Attack animation direction
enum ATTACK_DIRECTION_STATES {
	DOWN = -1,
	FRONT = 0,
	UP = 1
}

# A dictionary of the three attack collision shapes for up, front, an down.
# This is used with the parasol swinging attack to enable and disable specific attack collision shapes.
var attack_collision_shapes: Dictionary

# The currently playing animation from the AnimationTree node
var current_animation_state: StringName
var parasol_state: PARASOL_STATES = PARASOL_STATES.CLOSED
var attack_direction_state: ATTACK_DIRECTION_STATES = ATTACK_DIRECTION_STATES.FRONT
var is_attacking = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")# * parasol_gravity_modifier
var direction = Vector2.ZERO

func _ready():
	update_parasol_animation_blend_positions()
	animation_state.start("Idle")
	
	attack_collision_shapes = {
		up = attack_area2D.get_node("CollisionShape2D_Up"),
		front = attack_area2D.get_node("CollisionShape2D_Front"),
		down = attack_area2D.get_node("CollisionShape2D_Down")
	}

	PlayerStatManager.connect("start_health_regen_timer", _on_start_health_regen_timer)
	regen_delay_timer.connect("timeout", PlayerStatManager._on_regen_delay_timer_timeout)

func _process(delta):
	if DirectSunlightManager.player_in_sunlight:
		if not is_equal_approx(shader_shadow_scale, 0.0):
			shader_shadow_scale = clampf(shader_shadow_scale - (delta * SHADOW_TRANSITION_SCALE), 0.0, 1.0)
	else:
		if not is_equal_approx(shader_shadow_scale, 1.0):
			shader_shadow_scale = clampf(shader_shadow_scale + (delta * SHADOW_TRANSITION_SCALE), 0.0, 1.0)
	
	sprite.material.set_shader_parameter("shadow_scale", shader_shadow_scale)

func _physics_process(delta):
	# Add the gravity.
	apply_gravity(delta)

	current_animation_state = animation_state.get_current_node()

	update_current_attack_direction_state()

	if Input.is_action_just_pressed("toggle_parasol") and current_animation_state != "Attack" and toggle_parasol_cooldown.is_stopped():
		change_parasol_state()
		update_parasol_animation_blend_positions()
		animation_state.travel("ToggleParasol")
		toggle_parasol_cooldown.start()
	elif Input.is_action_just_pressed("jump") and is_on_floor() and (current_animation_state == "Idle" or current_animation_state == "Run"):
		animation_state.travel("Jump")
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_pressed("attack") and attack_cooldown.is_stopped() and parasol_state == PARASOL_STATES.CLOSED:
		player_attack()

	# Get the input direction and handle the movement/deceleration.
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if direction.x:
		velocity.x = clampf(velocity.x + (direction.x * ACCELERATION), -MAX_WALK_VELOCITY, MAX_WALK_VELOCITY)
		velocity.x = velocity.x + (direction.x * ACCELERATION)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, DECELERATION)

	if is_on_wall():
		check_pushable_object()

	#print(current_animation_state)
	
	update_sprite_direction()
	update_animation()
	move_and_slide()

func apply_gravity(delta):
	if not is_on_floor():
		if parasol_state == PARASOL_STATES.OPEN and current_animation_state == "Fall":
			velocity.y += (gravity * PARASOL_GRAVITY_MODIFIER) * delta
		else:
			velocity.y += gravity * delta

func change_parasol_state():
	match parasol_state:
		PARASOL_STATES.CLOSED:
			parasol_state = PARASOL_STATES.OPEN
			PlayerStatManager.parasol_open = true
		PARASOL_STATES.OPEN:
			parasol_state = PARASOL_STATES.CLOSED
			PlayerStatManager.parasol_open = false

func player_attack():
	attack_cooldown.start()
	animation_tree.set("parameters/Attack/blend_position", attack_direction_state)
	animation_state.travel("Attack")
	MAX_WALK_VELOCITY *= ATTACKING_VELOCITY_MOD

	match attack_direction_state:
		ATTACK_DIRECTION_STATES.UP:
			attack_collision_shapes.up.disabled = false
		ATTACK_DIRECTION_STATES.FRONT:
			attack_collision_shapes.front.disabled = false
		ATTACK_DIRECTION_STATES.DOWN:
			attack_collision_shapes.down.disabled = false

func update_animation():
	if velocity.y > 0:
		animation_state.travel("Fall")
	elif is_equal_approx(direction.x, 0.0) and current_animation_state == "Run":
		animation_state.travel("Idle")
	elif direction.x != 0.0 and current_animation_state == "Idle":
		animation_state.travel("Run")
	elif is_on_floor() and current_animation_state == "Fall":
		animation_state.travel("Idle")

func update_sprite_direction():
	if direction.x < 0:
		sprite.scale.x = -sprite_scale.x
		attack_area2D.scale.x = -1
	elif direction.x > 0:
		sprite.scale.x = sprite_scale.x
		attack_area2D.scale.x = 1

func check_pushable_object():
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_class("RigidBody2D"):
			collider.apply_force(collision.get_normal() * -OBJECT_PUSH_FORCE)

func _on_attack_cooldown_timeout():
	is_attacking = false

	for key in attack_collision_shapes:
		attack_collision_shapes[key].disabled = true
	
	MAX_WALK_VELOCITY /= ATTACKING_VELOCITY_MOD

func update_parasol_animation_blend_positions():
	animation_tree.set("parameters/Idle/blend_position", parasol_state)
	animation_tree.set("parameters/Run/blend_position", parasol_state)
	animation_tree.set("parameters/Jump/blend_position", parasol_state)
	animation_tree.set("parameters/Fall/blend_position", parasol_state)
	animation_tree.set("parameters/ToggleParasol/blend_position", parasol_state)

func update_current_attack_direction_state():
	var vertical_attack_strength = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if vertical_attack_strength < 0:
		attack_direction_state = ATTACK_DIRECTION_STATES.UP
	elif vertical_attack_strength > 0:
		attack_direction_state = ATTACK_DIRECTION_STATES.DOWN
	elif is_equal_approx(vertical_attack_strength, 0.0):
		attack_direction_state = ATTACK_DIRECTION_STATES.FRONT

func _on_start_health_regen_timer():
	regen_delay_timer.start()
