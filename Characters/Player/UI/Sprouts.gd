extends Control

@onready var sprouts_label: Label = $SproutsCollected
	
func _process(_delta):
	sprouts_label.text = str(PlayerStatManager.sprouts_collected)
