extends Equipment

@export var damage := 20.0
@export var fire_rate := 5.0
var can_fire := true

const GUN_BULLET = preload("res://cannons/gun_bullet.tscn")
@onready var barrel_end: Node3D = $BarrelEnd
const MUZZLE_FLASH = preload("res://vfx/muzzle_flash.tscn")


func on_triggered():
	if !can_fire: return
	
	fire.rpc()
	
	can_fire = false
	await get_tree().create_timer(1.0/fire_rate).timeout
	can_fire = true


@rpc("any_peer", "call_local")
func fire():
	barrel_end.add_child(MUZZLE_FLASH.instantiate())
	
	var bullet = GUN_BULLET.instantiate() as CannonShell
	bullet.damage = damage
	bullet.layer_mask = [1,2,6]
	bullet.ignore_list.append(held_player.get_rid())
	get_tree().get_root().add_child(bullet)
	bullet.position = held_player.camera.global_position# - held_player.camera.global_basis.z * 1
	bullet.global_basis.z = -held_player.camera.global_basis.z
	bullet._ready()
