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

enum {
	CLOSED,
	OPENING,
	OPEN
}

# Get the gravity from the project settings to be synced with RigidBody nodes.
var parasol_state = CLOSED
var parasol_gravity_modifier: float = 1 #currently not working??

var is_attacking = false

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") * parasol_gravity_modifier
var direction = Vector2.ZERO

func _ready():
	animation_tree.active = true
	animation_state.travel("move_closed")

func _physics_process(delta):
	match parasol_state:
		CLOSED:
			parasol_gravity_modifier = 1
			if Input.is_action_just_pressed("toggle_parasol") and parasol_cooldown.is_stopped():
				parasol_cooldown.start()
				parasol_state = OPENING
		OPEN:
			parasol_gravity_modifier = 0.3			
			if Input.is_action_just_pressed("toggle_parasol") and parasol_cooldown.is_stopped():
				parasol_cooldown.start()
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# Get the input direction and handle the movement/deceleration.
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")

	if Input.is_action_pressed("attack") and attack_cooldown.is_stopped() and parasol_state == CLOSED:
		attack_cooldown.start()
		MAX_WALK_VELOCITY *= 0.5

	if direction:
		velocity.x = clamp(velocity.x + (direction.x * ACCELERATION), -MAX_WALK_VELOCITY, MAX_WALK_VELOCITY)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, DECELERATION)

	update_direction()
	update_animation()
	move_and_slide()

func update_animation():
	var state

	if parasol_state == CLOSED:
		state = "closed"
	elif parasol_state == OPEN or parasol_state == OPENING:
		state = "open"
	animation_tree.set("parameters/jump_" + state + "/blend_position", velocity.y)
	animation_tree.set("parameters/move_" + state + "/blend_position", direction.x)
	if abs(direction.y) == abs(direction.x):
		direction.y *= 1.2
	animation_tree.set("parameters/attack/blend_position", direction)

	if Input.is_action_pressed("attack") and is_attacking == false and state == "closed":
		animation_state.travel("attack")
		is_attacking = true
	elif not is_on_floor() && attack_cooldown.is_stopped():
		animation_state.travel("jump_" + state)
	elif  attack_cooldown.is_stopped():
		animation_state.travel("move_" + state)

func update_direction():
	if direction.x < 0:
		sprite.flip_h = true
	elif direction.x > 0:
		sprite.flip_h = false

func _on_attack_cooldown_timeout():
	is_attacking = false
	MAX_WALK_VELOCITY *= 2


func _on_parasol_cooldown_timeout():
	if parasol_state == OPENING:
		parasol_state = OPEN
	elif parasol_state == OPEN:
		parasol_state = CLOSED
