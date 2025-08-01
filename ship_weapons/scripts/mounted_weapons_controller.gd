extends Node3D
class_name MountedWeaponsController

@export var hardpoints : Array[ComponentSocket]
@export var weapons : Array[ShipWeapon]
@export var controllable : Controllable
@export var ship : ShipManager

var bullet_speed : float = 200 # TODO: Calculate this properl


func _ready():
	for hardpoint in hardpoints:
		hardpoint.ship = ship # null here on turret. is set in turret_controller's ready
		hardpoint.snap_point.item_placed.connect(weapon_attached)
		hardpoint.snap_point.item_removed.connect(weapon_detached)
	for weapon in weapons:
		weapon.weapons_controller = self
	
	controllable.control_started.connect(on_controlled)
	controllable.control_ended.connect(on_uncontrolled)


func _input(event: InputEvent) -> void:
	if not (controllable.using_player or controllable.ai_override): return
	if not controllable.is_multiplayer_authority(): return
	
	if event.is_action_pressed("primary_fire"):
		for weapon in weapons:
			if !weapon.full_auto and weapon.fire_timer <= 0:
				weapon.fire_cannon.rpc()


func _process(_delta: float) -> void:
	if not (controllable.using_player or controllable.ai_override): return
	if not controllable.is_multiplayer_authority(): return
	
	if Input.is_action_pressed("primary_fire"):
		for weapon in weapons:
			if weapon.full_auto and weapon.fire_timer <= 0:
				weapon.fire_cannon.rpc()


func weapon_attached(weapon : Item):
	weapon = weapon as ShipWeapon
	weapons.append(weapon)
	weapon.weapons_controller = self


func weapon_detached(weapon : Item):
	weapon = weapon as ShipWeapon
	var id = weapons.find(weapon)
	if id != -1:
		weapons.remove_at(id)
		weapon.weapons_controller = null


func on_controlled():
	if controllable.using_player and controllable.is_multiplayer_authority():
		ship.movement_manager.ui.setup_mounted_weapons(self)


func on_uncontrolled():
	if controllable.is_multiplayer_authority():
		ship.movement_manager.ui.unsetup_mounted_weapons(self)
