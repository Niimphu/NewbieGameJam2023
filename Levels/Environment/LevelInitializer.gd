extends Node2D

func _ready():
	DirectSunlightManager.refresh_shadow_detection()
	DirectSunlightManager.set_process(true)