extends ParallaxLayer

@export var CLOUD_SPEED = -30.0

func _process(delta):
	self.motion_offset.x += CLOUD_SPEED*delta
