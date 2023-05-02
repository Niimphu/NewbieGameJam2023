extends RigidBody2D

@export var MAX_X_VELOCITY: float = 65.0
@export var MAX_Y_VELOCITY: float = -1.0

func _integrate_forces(state):
	var linear_velocity_normalized: Vector2 = state.linear_velocity.normalized()

	if MAX_X_VELOCITY >= 0.0:
		if abs(state.linear_velocity.x) > MAX_X_VELOCITY:
			state.linear_velocity.x = linear_velocity_normalized.x * MAX_X_VELOCITY
	
	if MAX_Y_VELOCITY >= 0.0:
		if abs(state.linear_velocity.y) > MAX_Y_VELOCITY:
			state.linear_velocity.y = linear_velocity_normalized.y * MAX_Y_VELOCITY