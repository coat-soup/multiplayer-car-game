extends Node3D

@export var is_open := false

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var interactable: Interactable = $Interactable
@onready var audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

@onready var close_timer : float = 0.0


func _ready() -> void:
	do_anim()
	interactable.interacted.connect(on_interact)


func _physics_process(delta: float) -> void:
	if is_open and close_timer > 0:
		close_timer -= delta
		if close_timer <= 0:
			toggle_door()

func on_interact(source):
	toggle_door.rpc()

@rpc("any_peer", "call_local")
func toggle_door():
	is_open = !is_open
	do_anim()
	
	if is_open:
		close_timer = 5.0


func do_anim():
	audio.play()
	if is_open: anim.play("open")
	else: anim.play_backwards("open")
	
	interactable.prompt_text = ("Close" if is_open else "Open") + " door"
