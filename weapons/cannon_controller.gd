extends Node3D

@onready var yaw_obj: Node3D = $Yaw
@onready var pitch_obj: Node3D = $Yaw/Pitch
@onready var camera: Camera3D = $Yaw/Pitch/Camera3D

@export var sensetivity := 0.0001

@export_group("Pitch")
@export_range(-360, 360) var p_min := -30
@export_range(-360, 360) var p_max := 40

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority(): return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_obj.rotate_y(-event.relative.x * sensetivity)
		pitch_obj.rotate_x(-event.relative.y * sensetivity)
		pitch_obj.rotation.x = clamp(pitch_obj.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		take_control()

func _ready():
	take_control()

func take_control():
	camera.current = true
