extends Node3D

@export var camera_focus_transorm : Node3D
@export var interactable: Interactable

var is_focused : bool = false
var camera_lerp_timer : float = 0.0
var focused_player : Player
var old_cam_pos : Vector3
var old_cam_rot : Vector3

var cam_lerp_time = 0.2


func _ready() -> void:
	interactable.interacted.connect(toggle_focus)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and is_focused:
		toggle_focus(focused_player)


func toggle_focus(source):
	is_focused = !is_focused
	
	camera_lerp_timer = 1.0
	
	if is_focused:
		focused_player = source as Player
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		old_cam_pos = focused_player.camera.position
		old_cam_rot = focused_player.camera.rotation
		focused_player.active = false
		interactable.active = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		focused_player.active = true
		
		await get_tree().create_timer(0.5).timeout
		interactable.active = true


func _process(delta: float) -> void:
	if camera_lerp_timer > 0 and focused_player:
		camera_lerp_timer = max(0, camera_lerp_timer - delta / cam_lerp_time)
		var percent = camera_lerp_timer if !is_focused else 1 - camera_lerp_timer
		focused_player.camera.position = lerp(old_cam_pos, focused_player.camera.get_parent_node_3d().to_local(camera_focus_transorm.global_position), percent)
		focused_player.camera.rotation = lerp(old_cam_rot, (focused_player.camera.get_parent_node_3d().global_basis.inverse() * camera_focus_transorm.global_basis).get_euler(), percent)
