extends Node

class_name Interactable

signal interacted

@export var prompt_text : String


func observe(_source: Node3D) -> String:
	return prompt_text

func interact(source: Node3D):
	interacted.emit(source)
	print(source.name + " interacted with " + get_owner().name)
