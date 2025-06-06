extends Node3D
class_name ShipWeaponsController

@export var weapons : Array[ShipWeapon]
@export var ship : ShipManager
@export var controllable : Controllable


func _ready():
	for weapon in weapons:
		weapon.weapons_controller = self


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
