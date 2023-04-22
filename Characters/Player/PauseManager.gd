extends Node

var pause_menu: CanvasLayer

func _ready():
	# To allow this node to still process and unpause the game while it is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	pause_menu = get_node_or_null("PauseMenuCanvasLayer")
	assert(pause_menu != null, "[PauseManager] Error: Cannot locate PauseMenuCanvasLayer")
	pause_menu.visible = false

func _process(_delta):
	if Input.is_action_just_pressed("pause_game"):
		var paused: bool = not get_tree().paused
		get_tree().paused = paused
		pause_menu.visible = paused
