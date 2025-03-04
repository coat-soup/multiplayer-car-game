extends Node3D

class_name VehicleFXManager

@onready var controller: VehicleController = $".."
@onready var engine_sound: AudioStreamPlayer3D = $EngineSound
@onready var impact_sound: AudioStreamPlayer3D = $ImpactSounds
@onready var tire_sounds: AudioStreamPlayer3D = $TireSounds
@onready var squeak_sounds: AudioStreamPlayer3D = $SqueakSounds

@onready var drift_sounds: AudioStreamPlayer3D = $DriftSounds

var trail_particles : Array[GPUParticles3D] = []

var prev_vel := Vector3.ZERO
var squeak_cooldown := 0.0
var impact_cooldown := 0.0

var n_tires := 8

func _ready():
	controller.crashed.connect(play_crash_sound)
	
	for i in range(1, n_tires+1):
		var p = $"../Particles".get_node_or_null("TireTrailParticles" + str(i)) as GPUParticles3D
		trail_particles.append(p)


func _process(delta: float) -> void:
	engine_sound.pitch_scale =  0.6 + controller.forward_speed/controller.top_speed
	
	tire_sounds.pitch_scale =  0.8 + (controller.forward_speed/controller.top_speed) * 0.3
	tire_sounds.stream_paused = not controller.exists_wheel_on_ground() or abs(controller.forward_speed) < 0.5
	tire_sounds.volume_db = (controller.forward_speed/controller.top_speed) * 5
	
	drift_sounds.pitch_scale =  0.8 + (controller.forward_speed/controller.top_speed) * 0.3
	
	if controller.is_slipping:
		drift_sounds.volume_db = lerp(drift_sounds.volume_db, drift_sounds.max_db, delta * 10)
	else:
		drift_sounds.volume_db = lerp(drift_sounds.volume_db, -30.0, delta * 2)
		
	for i in range(controller.wheels.size()):
		if i < trail_particles.size() and trail_particles[i]:
			trail_particles[i].emitting = controller.wheels[i].is_in_contact()
			trail_particles[i].amount_ratio = min(1, (controller.forward_speed)/20)


func _physics_process(delta: float) -> void:
	if squeak_cooldown > 0:
		squeak_cooldown -= delta
	if impact_cooldown > 0:
		impact_cooldown -= delta
	
	if squeak_cooldown <= 0 and prev_vel.y - controller.linear_velocity.y < -0.2 and controller.exists_wheel_on_ground():
		play_suspension_squeak()

	prev_vel = controller.linear_velocity


func play_crash_sound():
	if impact_cooldown > 0:
		return
	impact_cooldown = 0.5
	impact_sound.pitch_scale = randf_range(0.8, 1.2)
	impact_sound.play()


func play_suspension_squeak():
	squeak_cooldown = 1
	
	squeak_sounds.pitch_scale = randf_range(1, 1.2)
	squeak_sounds.play()
