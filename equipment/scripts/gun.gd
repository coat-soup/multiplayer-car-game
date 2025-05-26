extends Equipment

@export var damage := 20.0
@export var fire_rate := 5.0
@export var mag_size := 10
@onready var cur_ammo : int = mag_size
@onready var reload_time := 1.7

var can_fire := true
var reloading := false

const GUN_BULLET = preload("res://cannons/gun_bullet.tscn")
@export var barrel_end: Node3D
const MUZZLE_FLASH = preload("res://vfx/muzzle_flash.tscn")

@onready var anim: AnimationPlayer = $AnimationPlayer


# 0 = primary, 1 = secondary, 2 = middle mouse, 3 = reload
func on_triggered(button : int):
	if button == 0:
		if reloading or !can_fire: return
		
		fire.rpc()
		
		can_fire = false
		await get_tree().create_timer(1.0/fire_rate).timeout
		if cur_ammo > 0:
			can_fire = true
	elif button == 1:
		#TODO : ADS
		pass
	elif button == 3 and !reloading:
		if cur_ammo < mag_size:
			reload.rpc()


@rpc("any_peer", "call_local")
func fire():
	barrel_end.add_child(MUZZLE_FLASH.instantiate())
	
	anim.play("fire")
	
	var bullet = GUN_BULLET.instantiate() as CannonShell
	bullet.damage = damage
	bullet.layer_mask = [1,2,6]
	bullet.ignore_list.append(held_player.get_rid())
	get_tree().get_root().add_child(bullet)
	bullet.global_position = held_player.camera.global_position# - held_player.camera.global_basis.z * 1
	bullet.look_at(held_player.camera.global_position + held_player.camera.global_basis.z * 1)
	bullet.get_child(0).global_position = barrel_end.global_position
	bullet._ready()
	
	cur_ammo -= 1
	if cur_ammo<= 0:
		reload()
		
	update_ui()

@rpc("any_peer", "call_local")
func reload():
	if reloading:
		return
	reloading = true
	can_fire = false
	anim.speed_scale = 1.0/reload_time
	anim.play("reload")
	
	await get_tree().create_timer(reload_time).timeout
	
	reloading = false
	can_fire = true
	anim.speed_scale = 1.0
	cur_ammo = mag_size
	
	update_ui()


func on_held():
	update_ui()

func on_unheld():
	if held_by_auth:
		held_player.ui.hide_ammo_counter()


func update_ui():
	if held_by_auth:
		held_player.ui.update_ammo_counter(cur_ammo, mag_size)
