extends CharacterBody2D

@export var DECELERATION: float = 20.0
@export var ACCELERATION: float = 30.0
@export var JUMP_VELOCITY: float = -600.0
@export var MAX_WALK_VELOCITY: float = 300.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var sprite: Sprite2D = $Sprite2D
@onready var parasol_cooldown: Timer = $ParasolCooldown
@onready var attack_cooldown: Timer = $AttackCooldown

# The initial x scale of the sprite to be used to flip the sprite and preserve its position
# so that it will stay within the CollisionShape2D.
var sprite_scale_x: float


var current_animation_state: StringName

# This enum represents the different possible states of the Parasol animation
enum PARASOL_STATES {
	CLOSED = -1,
	OPENING = 0,
	OPEN = 1
}

var parasol_state = PARASOL_STATES.CLOSED
#var parasol_gravity_modifier: float = 1 #currently not working??

var is_attacking = false

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")# * parasol_gravity_modifier
var direction = Vector2.ZERO

func _ready():
	update_animation_tree_blend_positions()
	animation_state.start("Start")
	animation_state.travel("Idle")
	sprite_scale_x = sprite.scale.x

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	current_animation_state = animation_state.get_current_node()

	if Input.is_action_just_pressed("toggle_parasol") and current_animation_state == "Idle":
		match parasol_state:
			PARASOL_STATES.CLOSED:
				animation_state.travel("open_parasol")
				parasol_state = PARASOL_STATES.OPEN
			PARASOL_STATES.OPEN:
				animation_state.travel("close_parasol")
				parasol_state = PARASOL_STATES.CLOSED
		
		update_animation_tree_blend_positions()
	elif Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_pressed("attack") and attack_cooldown.is_stopped() and parasol_state == PARASOL_STATES.CLOSED:
		attack_cooldown.start()
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

func update_direction():
	if direction.x < 0:
		sprite.scale.x = -sprite_scale_x
	elif direction.x > 0:
		sprite.scale.x = sprite_scale_x

func _on_attack_cooldown_timeout():
	is_attacking = false
	MAX_WALK_VELOCITY *= 2

func _on_parasol_cooldown_timeout():
	match parasol_state:
		PARASOL_STATES.OPENING:
			parasol_state = PARASOL_STATES.OPEN
		PARASOL_STATES.OPEN:
			parasol_state = PARASOL_STATES.CLOSED

func update_animation_tree_blend_positions():
	animation_tree.set("parameters/Idle/blend_position", parasol_state)
	animation_tree.set("parameters/Run/blend_position", parasol_state)
