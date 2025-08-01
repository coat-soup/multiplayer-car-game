extends CharacterBody3D
class_name Item

@export var item_data : ItemData
@export var immovable : bool = false

@export var physics_dupe : RigidBody3D
@export var dupe_RT : RemoteTransform3D

@export var local_position : Vector3 # for multiplayer sync
@export var local_rotation : Vector3

@export var on_ship : ShipManager
var snap_point : ItemSnapPoint
var cargo_grid : CargoGrid
var potential_snap_points : Array[ItemSnapPoint]

var held_in_place := false
var tractored := false
var controlling_RT : RemoteTransform3D

var velo_calc : Vector3

@export var snap_point_offset : Vector3

var snap_indicator : Node3D :
	get:
		if not snap_indicator: return create_snap_indicator()
		else: return snap_indicator

@export var cargo_grid_dimensions : Vector3i = Vector3i.ZERO # zero for uncargogridable

var cargo_spot_a : Vector3i
var cargo_spot_b : Vector3i

var phys_delay = true

@onready var ui = get_tree().get_first_node_in_group("ui") as UIManager

var target_angular_velocity : Vector3
var target_linear_velocity : Vector3
var angular_acceleration : float

var item_physics_dupe_manager : ItemPhysicsDupeManager
var impact_audio: AudioStreamPlayer3D


func _ready() -> void:
	impact_audio = AudioStreamPlayer3D.new()
	impact_audio.stream = preload("res://sfx/box_crash.wav")
	impact_audio.max_distance = 15
	add_child(impact_audio)
	
	item_physics_dupe_manager = (get_tree().get_first_node_in_group("network manager") as NetworkManager).level_manager.item_physics_manager
	item_physics_dupe_manager.handle_item_spawn(self)
	
	if not immovable: physics_dupe.body_entered.connect(on_collided)
	
	multiplayer.connected_to_server.connect(on_connect) # for items already in scene
	on_connect() # for items spawned by spawner
	
	await get_tree().create_timer(0.5).timeout
	phys_delay = false


func on_connect():
	#ui.display_chat_message("item connected")
	if not multiplayer.is_server():
		request_initialise_on_load.rpc_id(1)


func _physics_process(_delta: float) -> void:
	if phys_delay or immovable or not dupe_RT: return
	
	velo_calc = physics_dupe.position - local_position
	
	if not held_in_place:
		if on_ship:
			position = physics_dupe.position
			rotation = physics_dupe.rotation
		else:
			dupe_RT.remote_path = get_path()
			global_position = physics_dupe.global_position
			global_rotation = physics_dupe.global_rotation
		
		
		if is_multiplayer_authority():
			if on_ship:
				local_position = physics_dupe.position
				local_rotation = physics_dupe.rotation
			else:
				local_position = item_physics_dupe_manager.ship_manager.movement_manager.to_local(physics_dupe.global_position)
				local_rotation = physics_dupe.rotation
			
		else:
			if on_ship:
				physics_dupe.position = local_position
				physics_dupe.rotation = local_rotation
			else:
				physics_dupe.global_position = item_physics_dupe_manager.ship_manager.movement_manager.to_global(local_position)
				physics_dupe.rotation = local_rotation
	
	
	if tractored:
		#physics_dupe.angular_velocity = physics_dupe.angular_velocity.move_toward(target_angular_velocity, delta * angular_acceleration)
		
		var sp = get_closest_snap_point()
		if sp and is_multiplayer_authority():
			snap_indicator.visible = true
			snap_indicator.global_position = sp.to_global(snap_point_offset)
			snap_indicator.global_rotation = sp.global_rotation
		elif cargo_grid and is_multiplayer_authority():
			snap_indicator.visible = true
			snap_indicator.global_position = cargo_grid.get_snapped_world_position(self)
			snap_indicator.global_rotation = cargo_grid.get_snapped_world_rotation(self)
			if not cargo_grid.can_put_item_there(self): snap_indicator.visible = false
		else: snap_indicator.visible = false


@rpc("any_peer", "call_local")
func request_initialise_on_load():
	if not multiplayer.is_server(): return
	
	#if not on_ship:
	#ui.display_chat_message("ATTEMPING SEND - cg " + str( cargo_grid) + " held " + str(held_in_place))
	
	if cargo_grid and held_in_place:
		#ui.display_chat_message("SENDING CARGO")
		initialise_on_load.rpc_id(multiplayer.get_remote_sender_id(), cargo_grid.get_path(), cargo_spot_a, cargo_spot_b, cargo_grid.global_rotation - physics_dupe.global_rotation)
	else:
		initialise_on_load.rpc_id(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_local")
func initialise_on_load(path_to_cargo_grid : String = "", a : Vector3i = Vector3i.ZERO, b : Vector3i = Vector3i.ZERO, local_rot : Vector3 = Vector3.ZERO):
	cargo_grid = get_tree().root.get_node_or_null(path_to_cargo_grid) as CargoGrid
	if cargo_grid:
		cargo_grid.place_item_crude_at_points_crude(self, a, b, local_rot)
		#ui.display_chat_message("CARGIN GRIDDING")
	if not on_ship:
		#ui.display_chat_message("SETTING RT FOR OFF SHIP")
		dupe_RT.remote_path = ""


func create_snap_indicator() -> Node3D:
	snap_indicator = duplicate()
	(snap_indicator as Item).snap_indicator = snap_indicator
	snap_indicator.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(snap_indicator)
	recursive_set_texture(snap_indicator)
	snap_indicator.visible = false
	return snap_indicator


static func recursive_set_texture(node : Node):
	var mesh = node as MeshInstance3D
	if mesh and mesh.get_surface_override_material_count() > 0:
		mesh.set_surface_override_material(0, preload("res://items/item_snap_indicator_mat.tres"))
	for child in node.get_children():
		recursive_set_texture(child)


func on_collided(_body):
	if velo_calc.length() >= 0.05:
		impact_audio.pitch_scale = randf_range(0.9,1.1)
		impact_audio.play()


@rpc("any_peer", "call_local")
func set_auth(id):
	set_multiplayer_authority(id)
	physics_dupe.set_multiplayer_authority(id)


@rpc("any_peer", "call_local")
func on_physics_picked_up():
	print("picked up")
	tractored = true
	
	if snap_point and held_in_place:
		snap_point.set_item.rpc("")
		physics_dupe.freeze = false
		held_in_place = false
		snap_point = null
		print("picking up from snap point")
		
	elif cargo_grid and held_in_place:
		cargo_grid.remove_item(self)
		physics_dupe.freeze = false
		held_in_place = false


@rpc("any_peer", "call_local")
func on_physics_let_go():
	tractored = false
	
	var sp = get_closest_snap_point()
	if sp:
		snap_point = sp
		snap_point.set_item.rpc(get_path())
		
	elif cargo_grid:
		if is_multiplayer_authority():
			cargo_grid.try_place_item(self)


func move_item(world_pos : Vector3):
	if on_ship: physics_dupe.position = on_ship.to_local(world_pos)
	else: physics_dupe.global_position = world_pos


func get_closest_snap_point() -> ItemSnapPoint:
	var closest := -1
	
	for i in range(len(potential_snap_points)):
		if closest == -1 or global_position.distance_to(potential_snap_points[i].global_position) < potential_snap_points[closest].global_position.distance_to(potential_snap_points[i].global_position):
			closest = i
	
	return potential_snap_points[closest] if closest != -1 else null


@rpc("any_peer", "call_local")
func set_target_angular_velocity(vel : Vector3, accel):
	target_angular_velocity = vel
	angular_acceleration = accel


@rpc("any_peer", "call_local")
func set_linear_velocity(vel : Vector3):
	physics_dupe.linear_velocity = vel
