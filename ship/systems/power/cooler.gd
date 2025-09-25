extends ShipComponent
class_name Cooler

@export var cooling_rate : float = 5.0
@export var particles : Array[GPUParticles3D]
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D


func _ready() -> void:
	super._ready()
	toggle_effects(ship != null)

func on_install_to_ship(ship_manager : ShipManager):
	super.on_install_to_ship(ship_manager)
	ship_manager.cooling_manager.add_cooler_component(self)
	toggle_effects(true)


func on_uninstall_from_ship(ship_manager : ShipManager):
	super.on_uninstall_from_ship(ship_manager)
	ship_manager.cooling_manager.remove_cooler_component(self)
	toggle_effects(false)


func toggle_effects(value : bool):
	for particle in particles:
		particle.emitting = value
	audio.playing = value

func on_break():
	super.on_break()
	toggle_effects(false)

func on_fixed(source_id):
	super.on_fixed(source_id)
	if ship: toggle_effects(true)
