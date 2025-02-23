extends Node3D

@onready var yaw_obj: Node3D = $Yaw
@onready var pitch_obj: Node3D = $Yaw/Pitch
@onready var camera: Camera3D = $Yaw/Pitch/Camera3D

@export var shell : PackedScene

@export var control_manager : Controllable
@export var sensetivity := 0.0001

@export var barrel_end : Node3D

@export_group("Pitch")
@export_range(-360, 360) var p_min := -30
@export_range(-360, 360) var p_max := 40


var ui : UIManager

func _ready() -> void:
	ui = get_tree().get_first_node_in_group("ui") as UIManager


func _unhandled_input(event: InputEvent) -> void:
	if not control_manager.using_player: return
	if not control_manager.is_multiplayer_authority(): return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		yaw_obj.rotate_y(-event.relative.x * sensetivity)
		pitch_obj.rotate_x(-event.relative.y * sensetivity)
		pitch_obj.rotation.x = clamp(pitch_obj.rotation.x, deg_to_rad(p_min), deg_to_rad(p_max))
	
	if event.is_action_pressed("primary_fire"):
		fire_cannon.rpc()

@rpc("any_peer", "call_local")
func fire_cannon():
	var shell_obj = shell.instantiate()
	get_tree().get_root().add_child(shell_obj)
	shell_obj.global_position = barrel_end.global_position
	shell_obj.global_rotation = barrel_end.global_rotation
	shell_obj._ready()
