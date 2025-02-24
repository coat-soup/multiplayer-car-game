extends VehicleBody3D

class_name VehicleController

@export var steering_power := 0.8
@export var engine_power := 300.0

@export var mass_marker: Node3D

@export var controllable : Controllable

func _ready() -> void:
	center_of_mass_mode = CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = mass_marker.position
	
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not controllable.using_player: return
	if not controllable.is_multiplayer_authority(): return
	
	steering = move_toward(steering, Input.get_axis("right", "left") * steering_power, delta * 2.5)
	engine_force = Input.get_axis("down", "up") * engine_power


@rpc("any_peer", "call_local")
func apply_impulse_rpc(force : Vector3, position : Vector3):
	apply_impulse(force, position)
