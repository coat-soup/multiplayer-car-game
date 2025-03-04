extends RigidBody3D

class_name JointVehicleController

@export var steering_power := 0.8
@export var engine_power := 300.0

@export var mass_marker: Node3D

@export var traction_wheels : Array[JoltGeneric6DOFJoint3D]
@export var steering_wheels : Array[JoltGeneric6DOFJoint3D]

var forward_speed := 0.0


func _ready() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = mass_marker.position
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var steering = Input.get_axis("right", "left") * steering_power
	var engine_force = Input.get_axis("down", "up") * engine_power
	
	forward_speed = move_toward(forward_speed, Input.get_axis("down", "up"), delta * 2)
	print(forward_speed)
	accelerate(forward_speed)
	
	steer(Input.get_axis("left", "right"))
	
	for wheel in traction_wheels:
		continue
		wheel.set_param_z(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, engine_force)
		


func accelerate(amount):
	if abs(amount) < 0.1:
		for wheel in traction_wheels:
			wheel.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_MOTOR, false)
	else:
		for wheel in traction_wheels:
			wheel.set_flag_z(JoltGeneric6DOFJoint3D.FLAG_ENABLE_ANGULAR_MOTOR, true)
			wheel.set_param_z(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, amount * engine_power)


func steer(amount):
	var angle = 0.523599 # 30 degrees
	
	if amount < 0.1 and amount > -0.1:
		for wheel in steering_wheels:
			wheel.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, 0)
			wheel.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, 0)

	else:
		if amount > 0:
			for wheel in steering_wheels:
				wheel.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_UPPER, angle * amount)
		else:
			for wheel in steering_wheels:
				wheel.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_LIMIT_LOWER, angle * amount)

		for wheel in steering_wheels:
				wheel.set_param_y(JoltGeneric6DOFJoint3D.PARAM_ANGULAR_MOTOR_TARGET_VELOCITY, amount * 1)
