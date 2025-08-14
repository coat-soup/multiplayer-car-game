extends Node
class_name DoorDupeLinker

@export var door : Door
@onready var anim: AnimationPlayer = $AnimationPlayer

func setup() -> void:
	door.toggled.connect(toggle)
	anim = $AnimationPlayer
	toggle(door.is_open)


func toggle(is_open):
	if is_open: anim.play("open")
	else: anim.play_backwards("open")
