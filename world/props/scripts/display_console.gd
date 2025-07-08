extends Node3D
class_name DisplayConsole

@export var camera_focus_transorm : Node3D
@export var interactable: Interactable

var is_focused : bool = false
var camera_lerp_timer : float = 0.0
var focused_player : Player
var old_cam_pos : Vector3
var old_cam_rot : Vector3

var cam_lerp_time = 0.2

@onready var sub_viewport: SubViewport = $"Sprite3D/SubViewport"
@onready var sprite_3d: Sprite3D = $"Sprite3D"


func _ready() -> void:
	interactable.interacted.connect(toggle_focus)


func _process(delta: float) -> void:
	if camera_lerp_timer > 0 and focused_player:
		camera_lerp_timer = max(0, camera_lerp_timer - delta / cam_lerp_time)
		var percent = camera_lerp_timer if !is_focused else 1 - camera_lerp_timer
		focused_player.camera.position = lerp(old_cam_pos, focused_player.camera.get_parent_node_3d().to_local(camera_focus_transorm.global_position), percent)
		focused_player.camera.rotation = lerp(old_cam_rot, (focused_player.camera.get_parent_node_3d().global_basis.inverse() * camera_focus_transorm.global_basis).get_euler(), percent)


func _input(event: InputEvent) -> void:
	if is_focused:
		if event is InputEventMouse:
			event.position = get_converted_mouse_pos(get_viewport().get_mouse_position())
		
		sub_viewport.push_input(event)
	
	if event.is_action_pressed("interact") and is_focused:
		toggle_focus(focused_player)


func get_converted_mouse_pos(mouse_screen_pos: Vector2) -> Vector2:
	var from = focused_player.camera.project_ray_origin(mouse_screen_pos)
	var to = from + focused_player.camera.project_ray_normal(mouse_screen_pos) * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to, Util.layer_mask([1]))
	query.exclude = [focused_player]
	var result = space_state.intersect_ray(query)
	
	if result:
		var hit_pos = result.position
		var local_hit = sprite_3d.to_local(hit_pos)
		
		var screen_size : Vector2 = sprite_3d.pixel_size * 1 * sub_viewport.size
		
		# Convert to UV space (0–1 range)
		var u = (local_hit.x / screen_size.x) + 0.5
		var v = (-local_hit.y / screen_size.y) + 0.5  # flip Y axis if needed
		
		if u >= 0.0 and u <= 1.0 and v >= 0.0 and v <= 1.0:
			var viewport_size = sub_viewport.size
			return Vector2(u * viewport_size.x, v * viewport_size.y)
	
	return Vector2.ONE * -1000


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
