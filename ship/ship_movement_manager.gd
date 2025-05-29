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

var directional_input := Vector3.ZERO
@export var rotation_input := Vector3.ZERO

var planets : Array[Planet]

@onready var veldebug: CSGSphere3D = $"../CSGSphere3D"
@export var velocity_sync : Vector3

@onready var ui : UIManager = get_tree().get_first_node_in_group("ui") as UIManager
@onready var velocity_synchroniser: MultiplayerSynchronizer = $"../VelocitySynchroniser"

@export var virtual_joystick_value = Vector2.ZERO
var turn_speed := 0.2
var roll_speed := 0.2
var rotation_accel := 1.0

@export var maneouvre_mode := false
var freelook := false
var camera_recenter_speed := 5.0


func _ready() -> void:
	for i in get_tree().get_nodes_in_group("planet"):
		planets.append(i as Planet)
	controllable.control_started.connect(on_controlled)
	controllable.control_ended.connect(on_uncontrolled)


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("freelook"):
		freelook = true
	elif Input.is_action_just_released("freelook"):
		freelook = false


func _unhandled_input(event: InputEvent) -> void:
	if not controllable or not controllable.using_player: return
	if not controllable.is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if freelook:
			camera_pivot.rotate_y(-event.relative.x * camera_sensetivity)
			camera_pivot.rotation.x += (event.relative.y * camera_sensetivity)
			camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))
			camera_pivot.rotation.z = 0
		else:
			virtual_joystick_value += Vector2(event.relative.x, event.relative.y) * camera_sensetivity
			virtual_joystick_value = virtual_joystick_value.limit_length(1)
			ui.update_virtual_joystick(virtual_joystick_value)


func _process(delta: float) -> void:
	if controllable.is_multiplayer_authority():
		print("SETTING VEL")
		velocity_sync = ship.velocity
		ui.display_chat_message("Setting velocity " + str(velocity_sync))
	else:
		ship.velocity = velocity_sync
		ui.display_chat_message("Receiving synced velocity " + str(ship.velocity))
	
	var directional_input_relative = (ship.global_basis * directional_input).normalized()
	veldebug.global_position = ship.global_position + directional_input_relative * 10
	var v_input = ship.velocity + acceleration * directional_input_relative * delta
	if v_input.length() < max_speed:
		ship.velocity = v_input
	
	var main_planet := planets[0]
	var max_grav := 0.0
	for planet in planets:
		var grav_force = Util.get_gravitational_acceleration(ship.global_position, planet) * delta
		ship.velocity += grav_force
		if grav_force.length() > max_grav:
			main_planet = planet
			max_grav = grav_force.length()
	rotate_ship_in_orbit(delta, main_planet)
	
	
	if not controllable.is_multiplayer_authority(): return
	
	var joystick : Vector2 = virtual_joystick_value if virtual_joystick_value.length() > 0.1 else Vector2.ZERO
	rotation_input = rotation_input.move_toward(Vector3(joystick.x, joystick.y, Input.get_axis("right", "left") * int(controllable.using_player != null)), rotation_accel * delta)
	
	ship.rotate_object_local(Vector3.UP, -rotation_input.x * turn_speed * delta)
	ship.rotate_object_local(Vector3.RIGHT, -rotation_input.y * turn_speed * delta)
	ship.rotate_object_local(Vector3.FORWARD, rotation_input.z * roll_speed * delta)
	
	ship.move_and_slide()
	
	if not controllable.is_multiplayer_authority(): return
	if not controllable or not controllable.using_player: return
	
	if maneouvre_mode:
		directional_input = Vector3(Input.get_axis("right", "left"), Input.get_axis("crouch", "jump"), Input.get_axis("down", "up"))
	else:
		directional_input = Vector3(0,0, Input.get_axis("down", "up"))
	
	if not freelook:
		camera_pivot.rotation = camera_pivot.rotation.lerp(Vector3.ZERO, delta * camera_recenter_speed)


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

	if controllable.is_multiplayer_authority():
		return
		ui.toggle_virtual_joystick(true)

	
func on_uncontrolled():
	if controllable.is_multiplayer_authority():
		ui.toggle_virtual_joystick(false)
