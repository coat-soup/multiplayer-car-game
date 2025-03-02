extends VehicleBody3D

class_name VehicleController

@export_category("Stats")
@export var steering_power := 0.8
@export var engine_power := 150.0
@export var top_speed := 40.0

@export_category("Handling")
@export var front_wheel_drift_factor := 1.4
@export var turn_loss_speed_range := Vector2(0.33, 1.0) ## Will go from 100% at x*top_speed to 0% at y*top_speed
@export var speed_drift_range := Vector2(0.5, 1.5) ## Will go from 0% speed_drift at x*top_speed to 100% at y*top_speed
@export var side_drift_range := Vector2(0.5, 3) ## Will go from 0% side_drift at 90*x degrees to 100% at 90*y degrees

@export_category("References")
@export var mass_marker: Node3D
@export var controllable : Controllable

var grip := 10.5
var wheels : Array[VehicleWheel3D]
var drift_particles : Array[GPUParticles3D] = []

@export var handbrake := false


func _ready() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = mass_marker.position
	
	controllable.control_ended.connect(on_uncontrolled)
	
	for child in get_children():
		var wheel = child as VehicleWheel3D
		if wheel:
			wheels.append(wheel)
			grip = wheel.wheel_friction_slip
			var particles = wheel.get_node_or_null("DriftParticles")
			if particles:
				drift_particles.append(particles as GPUParticles3D)
			else:
				drift_particles.append(null)
	
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var forward_speed = linear_velocity.project(global_basis.z).length()
	
	if not controllable.using_player: return
	if not controllable.is_multiplayer_authority(): return
	
	handbrake = Input.is_action_pressed("jump")
	
	steering = move_toward(steering, Input.get_axis("right", "left") * steering_power * clamp(1 - (forward_speed-top_speed*turn_loss_speed_range.x)/(top_speed*turn_loss_speed_range.y), 0.0, 1.0), delta * 2.5)
	engine_force = Input.get_axis("down", "up") * engine_power * (0 if forward_speed >= top_speed else 1)
	
	var speed_drift = 1 - clampf((forward_speed - top_speed*speed_drift_range.x) / top_speed*speed_drift_range.y, 0, 1)
	var sideways_drift = 1 - clampf((abs(rad_to_deg(linear_velocity.normalized().signed_angle_to(global_basis.z, global_basis.y))) - 90*side_drift_range.x)/90*side_drift_range.y, 0.0, 1.0)
	
	for i in range(wheels.size()):
		var drift = grip
		if handbrake:
			drift = 1
		else:
			drift *= (speed_drift + sideways_drift) / 2
		if wheels[i].use_as_steering:
			drift *= front_wheel_drift_factor
		
		wheels[i].wheel_friction_slip = min(grip, drift)
		
		if drift_particles[i]:
			drift_particles[i].emitting = drift < grip*0.5 and forward_speed > 10 and wheels[i].is_in_contact()


@rpc("any_peer", "call_local")
func apply_impulse_rpc(force : Vector3, pos : Vector3):
	apply_impulse(force, pos)


func on_uncontrolled():
	engine_force = 0
	steering = 0
