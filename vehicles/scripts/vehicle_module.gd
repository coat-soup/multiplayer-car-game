extends Node3D

class_name VehicleModule

signal broken
signal fixed

var module_manager : VehicleModuleManager

var children : Array[Node3D]
var controller : VehicleController

@export var do_steering := false
@export var do_traction := true

@export var steering_wheel : Controllable

@export var health : Health

const BROKEN_COMPONENT_PARTICLES = preload("res://vfx/broken_component_particles.tscn")
var broken_particles : Node3D = null
var is_broken := false


func setup():
	if health:
		health.died.connect(on_break)
		health.healed.connect(on_fixed)
	
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


func on_break():
	is_broken = true
	broken.emit()
	
	print("creating particles")
	broken_particles = BROKEN_COMPONENT_PARTICLES.instantiate()
	add_child(broken_particles)
	broken_particles.position = Vector3.ZERO


func on_fixed():
	if not is_broken: return
	
	if not health or health.cur_health >= health.max_health/2.0:
			is_broken = false
			fixed.emit()
			
			if broken_particles:
				broken_particles.queue_free()
				broken_particles = null
