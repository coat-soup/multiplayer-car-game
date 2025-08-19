extends ShipComponent
class_name Cooler

@export var cooling_rate : float = 5.0
@export var particles : Array[GPUParticles3D]

func _ready() -> void:
	super._ready()
	toggle_particles(ship != null)

func on_install_to_ship(ship_manager : ShipManager):
	super.on_install_to_ship(ship_manager)
	ship_manager.cooling_manager.add_cooler_component(self)
	toggle_particles(true)


func on_uninstall_from_ship(ship_manager : ShipManager):
	super.on_uninstall_from_ship(ship_manager)
	ship_manager.cooling_manager.remove_cooler_component(self)
	toggle_particles(false)


func toggle_particles(value : bool):
	for particle in particles:
		particle.emitting = value

func on_break():
	super.on_break()
	toggle_particles(false)

func on_fixed(source_id):
	super.on_fixed(source_id)
	if ship: toggle_particles(true)
