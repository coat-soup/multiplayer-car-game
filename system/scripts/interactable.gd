extends Node

class_name Interactable

signal interacted

@export var prompt_text : String

var active := true


func observe(_source: Node3D) -> String:
	return prompt_text if active else ""


func interact(source: Node3D):
	if not active:
		return
	
	interacted.emit(source)


@rpc("any_peer", "call_local")
func toggle_active(value: bool):
	active = value
