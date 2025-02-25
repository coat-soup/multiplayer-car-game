extends VehicleBody3D

class_name VehicleController

@export var steering_power := 0.8
@export var engine_power := 50.0

var grip := 10.5

@export var mass_marker: Node3D

@export var controllable : Controllable

@export var front_wheel_drift_factor := 1.5
var wheels : Array[VehicleWheel3D]


func _ready() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = mass_marker.position
	
	for child in get_children():
		var wheel = child as VehicleWheel3D
		if wheel:
			wheels.append(wheel)
			if wheel.use_as_traction:
				grip = wheel.wheel_friction_slip
	
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not controllable.using_player: return
	if not controllable.is_multiplayer_authority(): return
	
	steering = move_toward(steering, Input.get_axis("right", "left") * steering_power, delta * 2.5)
	engine_force = Input.get_axis("down", "up") * engine_power
	
	var drift_factor = 1 - clampf((linear_velocity.length() - 20.0) / 50.0, 0, 0.6)
	
	for wheel in wheels:
		var drift = grip
		if Input.is_action_pressed("jump"):
			drift *= 0.1
		else:
			drift *= drift_factor
			if not wheel.use_as_traction:
				drift *= front_wheel_drift_factor
		
		wheel.wheel_friction_slip = min(grip, drift)
		print(drift)
		


@rpc("any_peer", "call_local")
func apply_impulse_rpc(force : Vector3, position : Vector3):
	apply_impulse(force, position)
