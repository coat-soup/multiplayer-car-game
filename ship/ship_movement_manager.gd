extends Node3D
class_name ShipMovementManager

@export var ship_manager : ShipManager
var ship : CharacterBody3D
@export var controllable : Controllable

var camera_sensetivity := 0.005
@export var camera_pivot : Node3D

@export var acceleration := 10.0
@export var max_speed := 200.0

@export var mass := 400.0

var input_dir := Vector3.ZERO

var planets : Array[Planet]

@onready var veldebug: CSGSphere3D = $"../CSGSphere3D"
@export var velocity_sync : Vector3

@onready var ui : UIManager = get_tree().get_first_node_in_group("ui") as UIManager
@onready var velocity_synchroniser: MultiplayerSynchronizer = $"../VelocitySynchroniser"


func _ready() -> void:
	for i in get_tree().get_nodes_in_group("planet"):
		planets.append(i as Planet)
	controllable.control_started.connect(on_controlled)


func _unhandled_input(event: InputEvent) -> void:
	if not controllable or not controllable.using_player: return
	if not controllable.is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * camera_sensetivity)
		camera_pivot.rotation.x += (event.relative.y * camera_sensetivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(60))
		camera_pivot.rotation.z = 0


func _process(delta: float) -> void:
	if controllable.is_multiplayer_authority():
		print("SETTING VEL")
		velocity_sync = ship.velocity
		ui.display_chat_message("Setting velocity " + str(velocity_sync))
	else:
		ship.velocity = velocity_sync
		ui.display_chat_message("Receiving synced velocity " + str(ship.velocity))
	
	var input_dir_relative = (ship.global_basis * input_dir).normalized()
	veldebug.global_position = ship.global_position + input_dir_relative * 10
	var v_input = ship.velocity + acceleration * input_dir_relative * delta
	if v_input.length() < max_speed:
		ship.velocity = v_input
	
	for planet in planets:
		ship.velocity += Util.get_gravitational_acceleration(ship.global_position, planet) * delta
		rotate_ship_in_orbit(delta, planet)
	
	if not controllable.is_multiplayer_authority(): return
	ship.move_and_slide()
	
	if not controllable.is_multiplayer_authority(): return
	if not controllable or not controllable.using_player: return
	input_dir = Vector3(Input.get_axis("right", "left"), Input.get_axis("crouch", "jump"), Input.get_axis("down", "up"))


func rotate_ship_in_orbit(delta: float, planet : Planet):
	# 1. Compute orbital parameters
		var to_planet = ship.position - planet.position
		var radius = to_planet.length()
		var speed = ship.velocity.length()
		var arc_length = speed * delta
		var angle_delta = arc_length / radius  # in radians

		# 2. Compute rotation axis (orbit axis) using angular momentum direction
		var orbit_axis = to_planet.cross(ship.velocity).normalized()
		if orbit_axis != Vector3.ZERO:
			ship.rotate(orbit_axis, angle_delta)


func on_controlled():
	velocity_synchroniser.set_multiplayer_authority(str(controllable.using_player.name).to_int(), false)
