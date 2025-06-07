extends Node3D

var current_waypoint : Vector3

@onready var elevator_RT: RemoteTransform3D = $"../CarrierBlockout/Elevators/Elevator4/Platform/RemoteTransform3D"
@onready var elevator: Elevator = $"../CarrierBlockout/Elevators/Elevator4" as Elevator
@onready var carrier_blockout: Node3D = $"../CarrierBlockout"

@export var remote_transforms : Array[RemoteTransform3D]
@export var pad_waypoints : Array[LaunchRailWaypoint]
var ships : Array[ShipManager]
@export var runway_waypoint : LaunchRailWaypoint

@export var cur_pad : int
var state : int = 0 # 0 = idle, 1 = takeoff, 2 = landing

@export var rail_speed : float = 5.0
@export var runway_zone : Area3D

var path : Array[LaunchRailWaypoint]
var cur_path_id := -1
@export var carrier_ship : ShipManager


var launch_yeet := 0.0
var yeeting := false

@export var starting_ships_on_load : Array[Ship]


func _ready():
	for i in remote_transforms:
		ships.append(null)
	
	#await get_tree().process_frame
	runway_zone.body_entered.connect(check_runway)
	
	get_tree().get_first_node_in_group("network manager").host_started.connect(spawn_preloads)


func spawn_preloads():
	if not multiplayer.is_server(): return
	for i in range(len(starting_ships_on_load)):
		var ship = starting_ships_on_load[i].spawn_instance(Vector3.UP * 50, carrier_ship.root) as ShipManager
		
		await get_tree().create_timer(0.1).timeout
		directly_add_ship_to_pad(ship, i)


func check_runway(body):
	#if not is_multiplayer_authority(): return
	print("Checking runway: ", body)
	var ship = body as ShipMovementClone
	if state == 0 and ship and ship != carrier_ship.movement_clone:
		land_and_store(ship.ship_manager)
		print("storing", ship.ship_manager)


func land_and_store(ship : ShipManager):
	#if not is_multiplayer_authority(): return
	print("Storing ship")
	
	if elevator.target_floor != 1:
		elevator.call_to_floor.rpc(1)
	
	
	cur_pad = get_first_available_pad()
	remote_transforms[cur_pad].rotation = Vector3(0,deg_to_rad(180),0)
	remote_transforms[cur_pad].global_position = ship.global_position
	remote_transforms[cur_pad].remote_path = ship.movement_clone.get_path()
	ship.movement_manager.lock_to_rails()
	ship.movement_clone.toggle_collider(false)
	#ship.movement_manager.controllable.reset_synch_auth.rpc()
	ships[cur_pad] = ship
	state = 2
	
	path = runway_waypoint.find_path_to_waypoint(pad_waypoints[cur_pad])
	print(path)
	cur_path_id = 0


func _process(delta: float) -> void:
	if cur_path_id != -1:
		remote_transforms[cur_pad].global_position = remote_transforms[cur_pad].global_position.move_toward(path[cur_path_id].global_position, rail_speed * delta)
		#remote_transforms[cur_pad].look_at(remote_transforms[cur_pad].global_basis.z.move_toward(path[cur_path_id].global_position - remote_transforms[cur_pad].global_position, delta * 2.0))
		
		if path[cur_path_id].reached(remote_transforms[cur_pad].global_position):
			# check finished
			if cur_path_id == len(path) - 1:
				if state == 1:
					await get_tree().create_timer(1.0).timeout
					yeeting = true
				else:
					state = 0
					remote_transforms[cur_pad].rotation = Vector3(0,deg_to_rad(90),0)
				cur_path_id = -1
			
			# next waypoint on same level
			elif path[cur_path_id].elevator_level == path[cur_path_id + 1].elevator_level:
				cur_path_id += 1
			
			# elevator stuff
			else:
				# is on elevator
				if path[cur_path_id].on_elevator:
					path[cur_path_id].on_elevator.call_to_floor.rpc(path[cur_path_id+1].elevator_level)
				# is waiting on elevator
				elif path[cur_path_id + 1].on_elevator:
					path[cur_path_id + 1].on_elevator.call_to_floor.rpc(path[cur_path_id].elevator_level)
		
	if yeeting: # if finished path and launching
		remote_transforms[cur_pad].global_position += launch_yeet * global_basis.z.normalized() * delta
		launch_yeet += 15.0 * delta
		if launch_yeet >= 30.0:
			yeeting = false
			remote_transforms[cur_pad].remote_path = ""
			ships[cur_pad].movement_manager.locked_to_rails = false
			ships[cur_pad].movement_clone.toggle_collider(true)
			#ships[cur_pad].movement_manager.controllable.retry_sync_auth.rpc()
			ships[cur_pad].movement_manager.ship.velocity = global_basis.z * launch_yeet
			#await get_tree().process_frame
			ships[cur_pad].movement_clone.global_position = remote_transforms[cur_pad].global_position + global_basis.z * launch_yeet * delta
			launch_yeet = 0.0
			ships[cur_pad].movement_clone.global_rotation = global_rotation
			ships[cur_pad] = null
			await get_tree().create_timer(2.0).timeout
			state = 0


func launch_ship_from_pad(pad_id):
	#if not is_multiplayer_authority(): return
	var ship = ships[int(pad_id)]
	if state == 0 and ship:
		
		cur_pad = int(pad_id)
		remote_transforms[cur_pad].rotation = Vector3(0,deg_to_rad(180),0)
		remote_transforms[cur_pad].global_position = ship.global_position
		remote_transforms[cur_pad].remote_path = ship.get_path()
		ship.movement_manager.locked_to_rails = true
		state = 1
		
		path = pad_waypoints[cur_pad].find_path_to_waypoint(runway_waypoint)
		cur_path_id = 0
		remote_transforms[cur_pad].rotation = Vector3(0,0,0)


func get_first_available_pad() -> int:
	for i in range(len(ships)):
		if not ships[i]:
			return i
	return -1


func directly_add_ship_to_pad(ship : ShipManager, pad_id : int):
	ships[pad_id] = ship
	ship.movement_clone.toggle_collider(false)
	remote_transforms[pad_id].global_position = pad_waypoints[pad_id].global_position
	remote_transforms[pad_id].remote_path = ship.movement_clone.get_path()
	ship.movement_manager.lock_to_rails()
