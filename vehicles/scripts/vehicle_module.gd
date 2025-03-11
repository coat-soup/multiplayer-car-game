extends Node3D

class_name VehicleModule

var module_manager : VehicleModuleManager

var children : Array[Node3D]
var controller : VehicleController

@export var do_steering := false
@export var do_traction := true

@export var steering_wheel : Controllable


func setup():
	if steering_wheel:		
		module_manager.setup_cab_controllable(steering_wheel)
	
	for child in get_children():
		var p_offset = position
		var wheel = child as VehicleWheel3D
		if wheel:
			controller.wheels.append(wheel)
			wheel.position += p_offset
			wheel.use_as_steering = do_steering
			wheel.use_as_traction = do_traction
		print(controller.get_path())
		print(child.get_path())
		child.reparent(controller)
