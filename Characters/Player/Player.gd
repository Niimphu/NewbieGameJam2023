extends CharacterBody2D

@export var DECELERATION: float = 20.0
@export var ACCELERATION: float = 30.0
@export var JUMP_VELOCITY: float = -600.0
@export var MAX_WALK_VELOCITY: float = 300.0
@export var PARASOL_GRAVITY_MODIFIER: float = 0.3

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var sprite: Sprite2D = $Sprite2D
@onready var attack_cooldown: Timer = $AttackCooldown

# The initial x scale of the sprite to be used to flip the sprite and preserve its position
# so that it will stay within the CollisionShape2D.
var sprite_scale_x: float

# The currently playing animation from the AnimationTree node
var current_animation_state: StringName

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

var parasol_state: PARASOL_STATES = PARASOL_STATES.CLOSED
var attack_direction_state: ATTACK_DIRECTION_STATES = ATTACK_DIRECTION_STATES.FRONT

var is_attacking = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")# * parasol_gravity_modifier
var direction = Vector2.ZERO

func _ready():
	update_parasol_animation_blend_positions()
	animation_state.start("Idle")
	sprite_scale_x = sprite.scale.x

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		if parasol_state == PARASOL_STATES.OPEN and current_animation_state == "Fall":
			velocity.y += (gravity * PARASOL_GRAVITY_MODIFIER) * delta
		else:
			velocity.y += gravity * delta

	current_animation_state = animation_state.get_current_node()

	update_current_attack_direction_state()

	if Input.is_action_just_pressed("toggle_parasol") and current_animation_state == "Idle":
		match parasol_state:
			PARASOL_STATES.CLOSED:
				animation_state.travel("open_parasol")
				parasol_state = PARASOL_STATES.OPEN
			PARASOL_STATES.OPEN:
				animation_state.travel("close_parasol")
				parasol_state = PARASOL_STATES.CLOSED
		
		update_parasol_animation_blend_positions()
	elif Input.is_action_just_pressed("jump") and is_on_floor() and (current_animation_state == "Idle" or current_animation_state == "Run"):
		animation_state.travel("Jump")
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_pressed("attack") and attack_cooldown.is_stopped() and parasol_state == PARASOL_STATES.CLOSED:
		attack_cooldown.start()
		animation_tree.set("parameters/Attack/blend_position", attack_direction_state)
		animation_state.travel("Attack")
		MAX_WALK_VELOCITY *= 0.5

	# Get the input direction and handle the movement/deceleration.
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if direction.x:
		velocity.x = clamp(velocity.x + (direction.x * ACCELERATION), -MAX_WALK_VELOCITY, MAX_WALK_VELOCITY)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, DECELERATION)

	update_direction()
	update_animation()
	move_and_slide()

func update_animation():
	if is_equal_approx(direction.x, 0.0) and current_animation_state == "Run":
		animation_state.travel("Idle")
	elif direction.x != 0.0 and current_animation_state == "Idle":
		animation_state.travel("Run")
	elif current_animation_state == "Jump" and velocity.y > 0:
		animation_state.travel("Fall")
	elif current_animation_state == "Fall" and is_equal_approx(velocity.y, 0.0):
		animation_state.travel("Idle")

func update_direction():
	if direction.x < 0:
		sprite.scale.x = -sprite_scale_x
	elif direction.x > 0:
		sprite.scale.x = sprite_scale_x

func _on_attack_cooldown_timeout():
	is_attacking = false
	MAX_WALK_VELOCITY *= 2

func update_parasol_animation_blend_positions():
	animation_tree.set("parameters/Idle/blend_position", parasol_state)
	animation_tree.set("parameters/Run/blend_position", parasol_state)
	animation_tree.set("parameters/Jump/blend_position", parasol_state)
	animation_tree.set("parameters/Fall/blend_position", parasol_state)

func update_current_attack_direction_state():
	if Input.is_action_pressed("attack_modifier_down"):
		attack_direction_state = ATTACK_DIRECTION_STATES.DOWN
	elif Input.is_action_pressed("attack_modifier_up"):
		attack_direction_state = ATTACK_DIRECTION_STATES.UP
	else:
		attack_direction_state = ATTACK_DIRECTION_STATES.FRONT