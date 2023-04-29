extends RigidBody2D

@export var MAX_VELOCITY: float = 65.0

func _physics_process(_delta):
	if linear_velocity.length() > MAX_VELOCITY:
		linear_velocity = linear_velocity.normalized() * MAX_VELOCITY
