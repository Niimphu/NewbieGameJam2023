extends CharacterBody2D

@export var DECELERATION: float = 20.0
@export var ACCELERATION: float = 30.0
@export var JUMP_VELOCITY: float = -600.0
@export var MAX_WALK_VELOCITY: float = 400.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = clamp(velocity.x + (direction * ACCELERATION), -MAX_WALK_VELOCITY, MAX_WALK_VELOCITY)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, DECELERATION)

	move_and_slide()
