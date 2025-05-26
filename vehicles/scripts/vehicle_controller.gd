extends VehicleBody3D

class_name VehicleController

signal crashed
signal suspension_impacted

var camera_sensetivity := 0.005
@export var camera_pivot : Node3D

@export_category("Stats")
@export var steering_power := 0.8
@export var engine_power := 150.0
@export var top_speed := 40.0
@export var air_control := Vector2(500.0, 0.0)

@export_category("Handling")
@export var front_wheel_drift_factor := 1.4
@export var turn_loss_speed_range := Vector2(0.33, 2.0) ## Will go from 100% at x*top_speed to 0% at y*top_speed
@export var speed_drift_range := Vector2(0.5, 1.5) ## Will go from 0% speed_drift at x*top_speed to 100% at y*top_speed
@export var side_drift_range := Vector2(5, 90) ## Will go from 0% side_drift at x degrees to 100% at y degrees

@export_category("References")
@export var mass_marker: Node3D
@export var controllable : Controllable

var grip := 10.5
var wheels : Array[VehicleWheel3D]
var drift_particles : Array[GPUParticles3D] = []

var engines : Array[EngineModule]

@export var handbrake := false
var forward_speed : float

var is_slipping := false

func _ready() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = mass_marker.position
	
	if controllable:
		controllable.control_ended.connect(on_uncontrolled)
	
	for child in get_children():
		var wheel = child as VehicleWheel3D
		if wheel:
			wheels.append(wheel)
			grip = wheel.wheel_friction_slip
			drift_particles.append(wheel.get_node_or_null("DriftParticles") as GPUParticles3D)
			
	for p in drift_particles:
		if p:
			p.reparent(p.get_parent().get_parent())
	
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if not controllable or not controllable.using_player: return
	if not controllable.is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * camera_sensetivity)
		camera_pivot.rotation.x += (event.relative.y * camera_sensetivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-30), deg_to_rad(60))
		camera_pivot.rotation.z = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	forward_speed = linear_velocity.project(global_basis.z).length()
	
	if not controllable or not controllable.using_player: return
	if not controllable.is_multiplayer_authority(): return
	
	handbrake = Input.is_action_pressed("jump")
	
	if not exists_wheel_on_ground():
		do_air_control(delta)
	
	steering = move_toward(steering, Input.get_axis("right", "left") * steering_power * (clamp(1 - (forward_speed-top_speed*turn_loss_speed_range.x)/(top_speed*turn_loss_speed_range.y), 0.0, 1.0) if not handbrake else 1), delta * 2.5)
	engine_force = Input.get_axis("down", "up") * engine_power * (0 if forward_speed >= top_speed else 1)
	
	var speed_drift = 1 - clampf((forward_speed - top_speed*speed_drift_range.x) / top_speed*speed_drift_range.y, 0, 1)
	var sideways_drift = 1 - clampf((abs(rad_to_deg(linear_velocity.normalized().signed_angle_to(global_basis.z, global_basis.y))) - side_drift_range.x)/((side_drift_range.y*(0.1 + 1 - linear_velocity.length()/top_speed))-side_drift_range.x), 00, 1.0)
	
	for i in range(wheels.size()):
		var drift = grip
		if handbrake:
			drift = 0.0
		elif forward_speed > 5:
			drift *= (speed_drift + sideways_drift) / 2
		if wheels[i].use_as_steering:
			drift *= front_wheel_drift_factor
		
		wheels[i].wheel_friction_slip = min(grip, drift)
		
		if i < drift_particles.size() and drift_particles[i]:
			is_slipping = drift < grip*0.5 and linear_velocity.length() > 10 and wheels[i].is_in_contact()
			drift_particles[i].emitting = is_slipping
			
	try_drift_cheese(delta)


func update_engine_stats():
	var n = len(engines)
	engine_power = 0
	top_speed = 0
	for e in engines:
		engine_power += e.get_power()
		top_speed += e.get_speed()
	top_speed /= n
	engine_power *= (2 * n) / (n + 1) # 1 engine = 100% power, 2 engines = 133% power, 3 engines = 150%, 4 engines = 160%, etc


func _physics_process(delta: float) -> void:
	if not controllable: return
	if controllable.is_multiplayer_authority(): return
	
	var collision = KinematicCollision3D.new()
	if test_move(transform, linear_velocity * delta, collision):
		if linear_velocity.length() > 10:
			crashed.emit()
	


@rpc("any_peer", "call_local")
func apply_impulse_rpc(force : Vector3, pos : Vector3):
	apply_impulse(force, pos)


func on_uncontrolled():
	camera_pivot.rotation = Vector3.ZERO
	engine_force = 0
	steering = 0


func try_drift_cheese(delta : float):
	if handbrake:
		apply_torque(global_basis.y * Input.get_axis("right", "left") * delta * linear_velocity.length() * 2000)
		if linear_velocity.length() < top_speed:
			#apply_force(global_basis.z * engine_force * delta * 100)
			print(engine_force)


func do_air_control(delta):
	var rot_input := Vector2(Input.get_axis("right", "left"),  Input.get_axis("down", "up")) * air_control
	print("doing air control with ", rot_input)
	apply_torque(global_basis.y * rot_input.x * delta * 100)
	apply_torque(global_basis.x * rot_input.y * delta * 100)


func exists_wheel_on_ground() -> bool:
	for wheel in wheels:
		if wheel.is_in_contact():
			return true
	return false
