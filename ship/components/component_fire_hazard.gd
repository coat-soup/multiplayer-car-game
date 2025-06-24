extends Node3D
class_name ComponentFireHazard

@export var proc_chance : float = 1.0
@export var parent_component : ShipComponent
var fire_manager : FireManager


func _ready() -> void:
	if not parent_component: parent_component = get_parent() as ShipComponent
	parent_component.broken.connect(on_component_broken)
	fire_manager = parent_component.ship.fire_manager


func on_component_broken():
	if fire_manager and is_multiplayer_authority():
		if randf() < proc_chance:
			fire_manager.try_spawn_fire(fire_manager.world_to_grid_pos(global_position))
