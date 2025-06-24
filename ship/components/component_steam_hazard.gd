extends Node3D
class_name ComponentSteamHazard


@export var proc_chance : float = 1.0
@export var parent_component : ShipComponent
@onready var steam_particles : GPUParticles3D = $Particles
@onready var audio : AudioStreamPlayer3D = $Audio


func _ready() -> void:
	if not parent_component: parent_component = get_parent() as ShipComponent
	parent_component.broken.connect(on_component_broken)
	parent_component.fixed.connect(on_component_fixed)


func on_component_broken():
	if is_multiplayer_authority():
		if randf() < proc_chance:
			do_steam.rpc()


func on_component_fixed():
	steam_particles.emitting = false
	audio.playing = false


@rpc("any_peer", "call_local")
func do_steam():
	steam_particles.emitting = true
	audio.playing = true
