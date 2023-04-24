extends CharacterBody2D

@export var DECELERATION: float = 20.0
@export var ACCELERATION: float = 30.0
@export var JUMP_VELOCITY: float = -600.0
@export var MAX_WALK_VELOCITY: float = 300.0

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback")
@onready var sprite: Sprite2D = $Sprite2D

enum {
	CLOSED,
	OPEN
}

enum {
	MOVE,
	JUMP,
	ATTACK
}
# Get the gravity from the project settings to be synced with RigidBody nodes.
var parasol_state = CLOSED
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var direction = Vector2.ZERO

func _ready():
	animation_tree.active = true

func _physics_process(delta):
	match parasol_state:
		CLOSED:
			print("closed")
		OPEN:
			print("open")
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	if direction:
		velocity.x = clamp(velocity.x + (direction.x * ACCELERATION), -MAX_WALK_VELOCITY, MAX_WALK_VELOCITY)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, DECELERATION)

	move_and_slide()
	update_animation()
	update_direction()

func update_animation():
	animation_tree.set("parameters/Run_closed/blend_position", direction.x)

func update_direction():
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false
