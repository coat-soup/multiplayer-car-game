extends Node

class_name Health

signal took_damage
signal healed
signal died

@export var max_health : float = 100
@onready var cur_health : float = max_health


@rpc("any_peer", "call_local")
func take_damage(amount: float, source : String):
	if cur_health <= 0:
		return
	
	#print(get_owner().name, " taking ", str(amount), " damage")
	
	cur_health -= min(amount, cur_health)
	took_damage.emit()
	
	if not is_multiplayer_authority(): return
	
	#print("health is now: ", cur_health)
	
	if cur_health <= 0:
		die.rpc()


@rpc("any_peer", "call_local")
func heal(amount: float, source : String):
	healed.emit()
	
	cur_health = min(max_health, cur_health + amount)
	if not is_multiplayer_authority(): return


@rpc("any_peer", "call_local")
func die():
	print("died")
	died.emit()
	if not is_multiplayer_authority(): return
