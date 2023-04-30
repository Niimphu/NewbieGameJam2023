extends CPUParticles2D

func _ready():
	emitting = true
	print("asdssdaasddsa")

func _process(_delta):
	if not emitting and not is_queued_for_deletion():
		queue_free()
