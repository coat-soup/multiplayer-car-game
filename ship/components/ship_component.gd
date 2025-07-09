extends Node3D

class_name ShipComponent

signal broken
signal fixed

@export var component_name : String = "Component"
@export var health : Health

@export var power_system_name : String = "None"
var power_system : PowerSystem = null

const BROKEN_COMPONENT_PARTICLES = preload("res://vfx/particles/broken_component_particles.tscn")
var broken_particles : Node3D = null
var is_broken := false
@export var ship : ShipManager


func _ready():
	if health:
		health.died.connect(on_break)
		health.healed.connect(on_fixed)
	
	if not ship:
		try_get_ship_grandparent()
	
	try_initialise_power_system()


func try_initialise_power_system():
	if not ship: return
	if power_system_name != "" and power_system_name != "None":
		for system in ship.power_manager.power_systems:
			if system.system_name == power_system_name:
				print("setting ", name, " power system to ", system)
				power_system = system


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


func get_parent_velocity() -> Vector3:
	if ship:
		return ship.movement_manager.velocity_sync
	return Vector3.ZERO


func power_ratio() -> float:
	if power_system == null:
		print("Component", name, " has no power system, returning ratio = 1")
		return 1.0
	else:
		return float(power_system.assigned_capacitors)/float(power_system.max_capacitors)


func try_get_ship_grandparent():
	var parent : Node = self
	while parent != get_tree().root and ship == null:
		ship = parent as ShipManager
		parent = parent.get_parent()
