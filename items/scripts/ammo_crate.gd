extends Item
class_name AmmoCrate

signal ammo_depleted
signal ammo_changed

enum AMMO_TYPE {REPEATER, AUTOCANNON, RAILGUN}
const AMMO_TYPE_NAMES : Array[String] = ["Repeater", "Autocannon", "Railgun"]
@export var ammo_type : AMMO_TYPE

@export var max_ammo : int = 500
@export var cur_ammo : int

@export var interactable : Interactable


func _ready() -> void:
	cur_ammo = max_ammo
	super._ready()
	update_prompt()


@rpc("any_peer", "call_local")
func remove_ammo(amount : int):
	cur_ammo = max(cur_ammo - amount, 0)
	
	ammo_changed.emit()
	
	update_prompt()
	
	if cur_ammo <= 0:
		ammo_depleted.emit()


func update_prompt():
	interactable.prompt_text = "%d/%d %s ammo" % [cur_ammo, max_ammo, get_ammo_type_string()]


func get_ammo_type_string() -> String:
	return AMMO_TYPE_NAMES[ammo_type]
