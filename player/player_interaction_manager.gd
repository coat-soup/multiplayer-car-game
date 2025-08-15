extends Node

@export var camera : Camera3D
@export var max_distance := 3.0

@onready var player: Player = $".."

@export var raycast : RayCast3D

var ui : UIManager

var target_interactable : Interactable
var target_item : Item


func _ready() -> void:
	ui = get_tree().get_first_node_in_group("ui") as UIManager
	if not ui:
		pass
		push_warning("Interactor couldn't find UI manager")


func _process(_delta: float) -> void:
	if not player.is_multiplayer_authority(): return
	if not player.active:
		ui.set_interact_text("")
		return
	
	do_raycast()
	if target_interactable and not target_interactable.active:
		target_interactable = null
	if target_interactable and Input.is_action_just_pressed("interact"):
		target_interactable.interact(player)
		
	ui.set_interact_text("" if (not target_interactable or target_interactable.display_keycode) else target_interactable.observe(player))
	
	do_interact_aabb()


func do_interact_aabb():
	var target = target_interactable if target_interactable else target_item
	
	ui.toggle_interact_panel((target_interactable != null and target_interactable.active) or target_item != null)
	if target:
		var interact_aabb = null
		var shape_size : Vector3
		
		var col : CollisionShape3D
		for child in target.get_children():
			col = child as CollisionShape3D
			if col: break
		
		var box_shape = col.shape as BoxShape3D
		var cylinder_shape = col.shape as CylinderShape3D
		var sphere_shape = col.shape as SphereShape3D
		
		if box_shape: shape_size = box_shape.size
		elif cylinder_shape:
			shape_size = Vector3(cylinder_shape.radius * 2, cylinder_shape.height, cylinder_shape.radius * 2)
			shape_size = shape_size.rotated(Vector3.RIGHT, col.rotation.x).rotated(Vector3.UP, col.rotation.y).rotated(Vector3.FORWARD, col.rotation.z)
		elif sphere_shape: shape_size = Vector3(sphere_shape.radius * 2, sphere_shape.radius * 2, sphere_shape.radius * 2)
		
		interact_aabb = AABBHelper.get_2d_bounds_from_3d_bounds(target, col.position - shape_size / 2, shape_size, player.camera)
		
		if interact_aabb:
			var prompts : String = ""
			if target_interactable and target_interactable.display_keycode:
				var interact_prefix = InputMap.action_get_events("interact")[0].as_text().split(" ")[0]
				prompts += "["+interact_prefix+"] " + target_interactable.observe(player) + "\n"
			if target_item and not target_item.immovable:
				var grab_prefix = InputMap.action_get_events("grab")[0].as_text().split(" ")[0]
				prompts += "["+grab_prefix+"] Grab"
			ui.update_interact_panel(target_item.item_data.item_name if target_item else "", prompts, interact_aabb[0], interact_aabb[1])


func do_raycast():
	var space_state = player.get_world_3d().direct_space_state

	var origin = camera.global_position
	var end = origin + -camera.global_basis.z * max_distance
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.exclude = [player.movement_manager]

	# do interactable
	query.collision_mask = Util.layer_mask([1,2,3])
	var result := space_state.intersect_ray(query)
	if result: target_interactable = result.collider as Interactable
	else: target_interactable = null
	
	# do item
	query.collision_mask = Util.layer_mask([1, 2])
	result = space_state.intersect_ray(query)
	if result: target_item = result.collider as Item
	else: target_item = null
