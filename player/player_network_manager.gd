extends Node

@export var third_person_models : Array[Node3D]
@export var username_label: Label3D

func _enter_tree() -> void:
	set_multiplayer_authority(str(get_owner().name).to_int())

func _ready() -> void:
	if is_multiplayer_authority():
		for m in third_person_models:
			m.visible = false
			
	var steam_user_id = Steam.getSteamID()
	var steam_user_name = Steam.getFriendPersonaName(steam_user_id)
	username_label.text = steam_user_name
