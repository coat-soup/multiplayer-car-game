extends Node3D

@onready var start_pos : Vector3 = position
@export var end_pos : Vector3

@export var speed : float = 5.0
@export var button : Interactable

var progress : float = 0.0
var direction := 1

func _ready():
	button.interacted.connect(button_pressed)

func button_pressed(source):
	print("Elevatored")
	direction *= -1

func _process(delta: float) -> void:
	position = position.move_toward(start_pos if direction == 1 else start_pos + end_pos, delta * speed)
