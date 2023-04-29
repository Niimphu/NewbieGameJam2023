extends Node2D

const SHADOW_SHAPE_CAST_DISTANCE: int = 1000

var light_occluders: Array[LightOccluder2D]
var shadow_shape_casts: Array[ShapeCast2D]
var sun_direction_vector: Vector2
var player: CharacterBody2D
var shape_casts_root_node: Node2D
var level_root_node: Node2D

var player_in_sunlight: bool = false

# TODO: Find a way to detect when the scene changes and call refresh_occluder_polygons()

func _ready():
	# We will not actually run this script unless the level contains a "sun" directional light
	set_process(false)
	
	refresh_shadow_detection()

func _process(_delta):
	check_player_in_shadow()
	
func refresh_shadow_detection():
	# Get the angle the sun is facing. Used in the ShapeCast2D calculations
	var sun = get_tree().get_first_node_in_group("sun")
	
	if not sun:
		print("[DirectSunlightManager] No directional light in the \"sun\" group found. Disabling direct sunlight detection for this scene.")
		return
	
	var sun_rotation = sun.global_rotation
	sun_direction_vector = Vector2(-sin(sun_rotation), cos(sun_rotation))
	
	player = get_tree().get_first_node_in_group("player")
	
	level_root_node = get_tree().get_first_node_in_group("level_root_node")
	assert(level_root_node != null, "[DirectSunlightManager] Root Node2D of level is not added to the level_root_node group.")
	
	shape_casts_root_node = get_tree().get_first_node_in_group("shape_casts_root_node")
	
	if not shape_casts_root_node:
		shape_casts_root_node = Node2D.new()
		shape_casts_root_node.name = "ShadowShapeCasts"
		level_root_node.add_child(shape_casts_root_node)
	
	refresh_occluder_polygons()
	delete_all_shadow_shape_casts()
	instantiate_shadow_shape_casts()
	
	if not is_processing():
		set_process(true)
	
# Reinitializes the occluder_polygons array with all
# of the light occluder polygons in the current level
func refresh_occluder_polygons():
	light_occluders.clear()
	
	var shadows_group_nodes = get_tree().get_nodes_in_group("shadows")
	
	for node in shadows_group_nodes:
		if node is LightOccluder2D:
			light_occluders.append(node)

func delete_all_shadow_shape_casts():
	var shape_casts: Array = get_tree().get_nodes_in_group("shadow_shape_casts")
	
	if shape_casts.size() == 0:
		return
	
	for shape_cast in shape_casts:
		shape_cast.queue_free()
	
	shadow_shape_casts.clear()

func instantiate_shadow_shape_casts():
	for light_occluder in light_occluders:
		var shape_cast = ShapeCast2D.new()
		shape_cast.add_to_group("shadow_shape_casts")
		shape_cast.collide_with_areas = true
		shape_cast.collision_mask = 0 # Set all collision mask values to false
		shape_cast.set_collision_mask_value(15, true) # We only want to detect the player
		shape_cast.shape = ConvexPolygonShape2D.new()
		shape_cast.shape.points = light_occluder.occluder.polygon
		shape_cast.global_position = light_occluder.global_position
		shape_cast.target_position = shape_cast.global_position.normalized() + (sun_direction_vector * SHADOW_SHAPE_CAST_DISTANCE)
		shadow_shape_casts.append(shape_cast)
		shape_casts_root_node.add_child(shape_cast)

func check_player_in_shadow():
	player_in_sunlight = true
	
	for shadow_shape_cast in shadow_shape_casts:
		if shadow_shape_cast.is_colliding():
			player_in_sunlight = false
			break
