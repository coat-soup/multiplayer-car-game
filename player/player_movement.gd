extends Node3D

class_name PlayerMovement

@export var player : CharacterBody3D
@export var player_manager : Player

@export var camera_pivot: Node3D
@export var camera: Camera3D
@export var camera_shake : CameraShake

@onready var collision_shape_3d: CollisionShape3D = $"CollisionShape3D"
@onready var floorcast: RayCast3D = $Floorcast

@export var walk_speed = 4.0
@export var sprint_speed = 7.0
@export var jump_velocity = 4.5
@export var sensetivity = 0.005;
var camera_locked := false

#viewbob
const BOB_FREQ = 2.5
const BOB_AMP = 0.05
var t_bob : float = 0.0

signal bob_top
signal bob_bottom

var landing : bool
signal jump_start
signal jump_land

var debug_mode = false

var floor_obj : Node3D

var on_ship := false
@export var ship_gravity := 9.8
@onready var ship : ShipManager

const PLAYER_RT = preload("res://player/player_RT.tscn")
var remote_transform : RemoteTransform3D


func _ready():
	ship = player_manager.network_manager.network_manager.ship
	remote_transform = PLAYER_RT.instantiate() as RemoteTransform3D
	ship.add_child(remote_transform)
	
	print(ship)
	
	ship.gravity_bounds.body_entered.connect(check_gravity_entered)
	ship.gravity_bounds.body_exited.connect(check_gravity_left)
	
	if not is_multiplayer_authority(): return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true


func check_gravity_entered(body):
	if body == self:
		on_ship = true
		
		var g_pos = player.global_position
		var g_rot = player.global_rotation
		
		remote_transform.remote_path = player_manager.get_path()
		
		#await get_tree().process_frame
		player.global_position = g_pos
		player.global_rotation = g_rot


func check_gravity_left(body):
	if body == self:
		on_ship = false
		remote_transform.remote_path = ""
		player.rotate_object_local(Vector3.RIGHT, camera_pivot.rotation.x)
		camera_pivot.rotation.x = 0


func pause_ship_rpc():
	remote_transform.update_position = false
	remote_transform.update_rotation = false
func unpause_ship_rpc():
	remote_transform.update_position = true
	remote_transform.update_rotation = true


func _input(_event: InputEvent) -> void:
	if not player_manager.active or not is_multiplayer_authority(): return
	if Input.is_key_pressed(KEY_SEMICOLON):
		debug_mode = !debug_mode
		if debug_mode:
			collision_shape_3d.disabled = true
		else:
			collision_shape_3d.disabled = false


func _unhandled_input(event: InputEvent) -> void:
	if not player_manager.active or not is_multiplayer_authority(): return
	if not camera_locked and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if on_ship:
			player.rotate_y(-event.relative.x * sensetivity)
			camera_pivot.rotate_x(-event.relative.y * sensetivity)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		else:
			player.rotate_object_local(Vector3.RIGHT, -event.relative.y * sensetivity)
			player.rotate_object_local(Vector3.UP, -event.relative.x * sensetivity)


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	
	# gravity
	if not player.is_on_floor() and !debug_mode and on_ship:
		player.velocity += -ship.global_basis.y * ship_gravity * delta
	
	if on_ship: player.up_direction = ship.global_basis.y
	else: player.up_direction = player.global_basis.y
	
	# input
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := ((player.basis if on_ship else player.global_basis) * Vector3(input_dir.x, 0.0 if on_ship else Input.get_axis("crouch", "jump"), input_dir.y)).normalized()
	
	if not player_manager.active: direction = Vector3.ZERO
	
	var adjusted_local_velocity = ship.global_basis.inverse() * player.velocity
	
	var speed = sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	
	if not on_ship:
		#EVA
		player.velocity.x = lerp(player.velocity.x, direction.x * speed, delta * 2)
		player.velocity.z = lerp(player.velocity.z, direction.z * speed, delta * 2)
		player.velocity.y = lerp(player.velocity.y, direction.y * speed, delta * 2)
		if player_manager.active: player.rotate_object_local(Vector3.FORWARD, Input.get_axis("roll_left", "roll_right") * delta * 2)
		#player.velocity = adjusted_local_velocity
	else:
		player.rotation.z = lerp_angle(player.rotation.z, 0, delta * 10)
		player.rotation.x = lerp_angle(player.rotation.x, 0, delta * 10)
		# WALKING MOVEMENT
		if player_manager.active and Input.is_action_just_pressed("jump") and player.is_on_floor() and on_ship: # jump
			jump_start.emit()
			adjusted_local_velocity.y = jump_velocity
			#player.velocity += ship.global_basis.y * jump_velocity
			
		elif floorcast.is_colliding(): #player.is_on_floor(): # isonfloor spazzes out when the ship is rotated
			#handle_floor_attachment()
			
			if direction:
				adjusted_local_velocity.x = direction.x * speed
				adjusted_local_velocity.z = direction.z * speed
			else:
				adjusted_local_velocity.x = lerp(adjusted_local_velocity.x, direction.x * speed, delta * 10)
				adjusted_local_velocity.z = lerp(adjusted_local_velocity.z, direction.z * speed, delta * 10)
			
			if landing:
				landing = false
				if adjusted_local_velocity.y < 1:
					activate_signal.rpc("jump_land")
		else:
			adjusted_local_velocity.x = lerp(adjusted_local_velocity.x, direction.x * speed, delta * 2)
			adjusted_local_velocity.z = lerp(adjusted_local_velocity.z, direction.z * speed, delta * 2)
			
			if !landing:
				landing = true
		
		player.velocity = ship.global_basis * adjusted_local_velocity
		
		# viewbob
		t_bob += delta * player.velocity.length() * float(player.is_on_floor())
		var b : float = bob_calc(t_bob)
		camera.position = Vector3(0, b, 0)
		
		# bob signals
		if b/BOB_AMP < 0.05:
			activate_signal.rpc("bob_bottom")
		elif b/BOB_AMP > 0.95:
			activate_signal.rpc("bob_top")
	
	player.move_and_slide()


static func bob_calc(time : float) -> float:
	return BOB_AMP * sin(time * BOB_FREQ)


@rpc("call_local", "any_peer")
func add_velocity_impulse(vel):
	if is_multiplayer_authority():
		player.velocity += vel
		print("yeeted " + str(vel))
	else:
		print(name + " isnt auth, not yeeting")


func handle_floor_attachment():
	if not multiplayer.has_multiplayer_peer() or multiplayer.multiplayer_peer.get_connection_status() != multiplayer.multiplayer_peer.CONNECTION_CONNECTED:
		return
	if floorcast.is_colliding():
		var vc = floorcast.get_collider()
		while (vc as VehicleController) == null:
			if not vc: return # redundancy because it doesn't work sometimes apparently
			vc = vc.get_parent()
		
		var new_obj = vc as VehicleController
		if floor_obj != new_obj:
			set_parent_to_vehicle.rpc(new_obj.get_path())
			floor_obj = new_obj
	elif floor_obj:
		floor_obj = null
		set_parent_to_vehicle.rpc("")


@rpc("any_peer", "call_local")
func set_parent_to_vehicle(node_name: String):
	player.reparent(get_tree().root.get_node(node_name) if node_name != "" else get_tree().root)


@rpc("any_peer", "call_local")
func activate_signal(sig : String):
	emit_signal(sig)
