extends Node3D

class_name PlayerMovement

@export var player : Player

@export var camera_pivot: Node3D
@export var camera: Camera3D

@onready var collision_shape_3d: CollisionShape3D = $"../CollisionShape3D"
@onready var floorcast: RayCast3D = $Floorcast

@export var speed = 5.0
@export var jump_velocity = 4.5
@export var sensetivity = 0.005;

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

var on_ship := true
@export var ship_gravity := 9.8
@onready var ship : ShipManager = get_tree().get_first_node_in_group("ship") as ShipManager

func _ready():
	if not player.active or not is_multiplayer_authority(): return
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true


func _input(_event: InputEvent) -> void:
	if not player.active or not is_multiplayer_authority(): return
	if Input.is_key_pressed(KEY_SEMICOLON):
		debug_mode = !debug_mode
		if debug_mode:
			collision_shape_3d.disabled = true
		else:
			collision_shape_3d.disabled = false


func _unhandled_input(event: InputEvent) -> void:
	if not player.active or not is_multiplayer_authority(): return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		player.rotate_y(-event.relative.x * sensetivity)
		camera_pivot.rotate_x(-event.relative.y * sensetivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta: float) -> void:
	if not player.active or not is_multiplayer_authority(): return
	
	player.rotation.z = lerp_angle(player.rotation.z, 0, delta * 10)
	
	# gravity
	if not player.is_on_floor() and !debug_mode and on_ship:
		player.velocity += -ship.global_basis.y * ship_gravity * delta
	
	if on_ship:
		player.up_direction = ship.global_basis.y
	
	# input
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (player.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	
	var adjusted_local_velocity = ship.global_basis.inverse() * player.velocity
	
	# jump
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		jump_start.emit()
		adjusted_local_velocity.y = jump_velocity
		#player.velocity += ship.global_basis.y * jump_velocity
		
	elif player.is_on_floor():
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
				jump_land.emit()
	else:
		adjusted_local_velocity.x = lerp(adjusted_local_velocity.x, direction.x * speed, delta * 2)
		adjusted_local_velocity.z = lerp(adjusted_local_velocity.z, direction.z * speed, delta * 2)
		
		if !landing:
			landing = true
	
	player.velocity = ship.global_basis * adjusted_local_velocity
	
	# viewbob
	t_bob += delta * player.velocity.length() * float(player.is_on_floor())
	var b : float = bob_calc(t_bob)
	camera.transform.origin = Vector3(0, b, 0)
	
	# bob signals
	if b/BOB_AMP < 0.05:
		bob_bottom.emit()
	elif b/BOB_AMP > 0.95:
		bob_top.emit()

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
