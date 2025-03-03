extends Node3D

class_name VehicleSoundManager

@onready var controller: VehicleController = $".."
@onready var engine_sound: AudioStreamPlayer3D = $EngineSound
@onready var impact_sound: AudioStreamPlayer3D = $ImpactSounds
@onready var tire_sounds: AudioStreamPlayer3D = $TireSounds
@onready var squeak_sounds: AudioStreamPlayer3D = $SqueakSounds

var prev_vel := Vector3.ZERO
var squeak_cooldown := 0.0


func _ready():
	controller.crashed.connect(play_crash_sound)


func _process(delta: float) -> void:
	engine_sound.pitch_scale =  0.6 + controller.forward_speed/controller.top_speed
	
	tire_sounds.pitch_scale =  0.9 + (controller.forward_speed/controller.top_speed) * 0.2
	tire_sounds.stream_paused = not exists_wheel_on_ground() or abs(controller.forward_speed) < 0.5
	tire_sounds.volume_db = (controller.forward_speed/controller.top_speed) * 5


func _physics_process(delta: float) -> void:
	if squeak_cooldown > 0:
		squeak_cooldown -= delta
	
	if squeak_cooldown <= 0 and prev_vel.y - controller.linear_velocity.y < -0.2 and exists_wheel_on_ground():
		play_suspension_squeak()

	prev_vel = controller.linear_velocity


func play_crash_sound():
	impact_sound.pitch_scale = randf_range(0.8, 1.2)
	impact_sound.play()


func play_suspension_squeak():
	squeak_cooldown = 1
	
	squeak_sounds.pitch_scale = randf_range(1, 1.2)
	squeak_sounds.play()


func exists_wheel_on_ground() -> bool:
	for wheel in controller.wheels:
		if wheel.is_in_contact():
			return true
	return false
