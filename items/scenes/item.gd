extends Node3D
class_name Item

@export var physics_dupe : RigidBody3D
@export var dupe_RT : RemoteTransform3D

@export var local_position : Vector3 # for multiplayer sync
@export var local_rotation : Vector3

@export var on_ship : ShipManager
var snap_point : ItemSnapPoint
var potential_snap_points : Array[ItemSnapPoint]

var held_in_place := false

var velo_calc : Vector3

@onready var impact_audio: AudioStreamPlayer3D = $ImpactAudio

var snap_indicator : Node3D


func _ready() -> void:
	physics_dupe.body_entered.connect(on_collided)
	
	if not snap_indicator:
		snap_indicator = duplicate()
		(snap_indicator as Item).snap_indicator = snap_indicator
		snap_indicator.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(snap_indicator)
		recursive_set_texture(snap_indicator)
		snap_indicator.visible = false


static func recursive_set_texture(node : Node):
	var mesh = node as MeshInstance3D
	if mesh:
		mesh.set_surface_override_material(0, preload("res://items/item_snap_indicator_mat.tres"))
	for child in node.get_children():
		recursive_set_texture(child)


func on_collided(_body):
	print("collided with force ", velo_calc)
	if velo_calc.length() >= 0.05:
		impact_audio.pitch_scale = randf_range(0.9,1.1)
		impact_audio.play()


func _physics_process(_delta: float) -> void:
	velo_calc = physics_dupe.position - local_position
	if is_multiplayer_authority():
		local_position = physics_dupe.position
		local_rotation = physics_dupe.rotation
	if on_ship and not held_in_place:
		position = local_position
		rotation = local_rotation
	
	if !held_in_place:
		var sp = get_closest_snap_point()
		if sp and is_multiplayer_authority():
			snap_indicator.visible = true
			snap_indicator.global_position = sp.global_position
			snap_indicator.global_rotation = sp.global_rotation
		else: snap_indicator.visible = false


@rpc("any_peer", "call_local")
func set_auth(id):
	set_multiplayer_authority(id)
	physics_dupe.set_multiplayer_authority(id)


@rpc("any_peer", "call_local")
func on_physics_let_go():
	var sp = get_closest_snap_point()
	if sp:
		snap_point = sp
		snap_point.set_item.rpc(get_path())
		
		physics_dupe.freeze = true
		held_in_place = true
		
		global_position = snap_point.global_position
		physics_dupe.position = position
		global_rotation = snap_point.global_rotation
		physics_dupe.rotation = rotation
		
		snap_indicator.visible = false


@rpc("any_peer", "call_local")
func on_physics_picked_up():
	if snap_point:
		snap_point.set_item.rpc("")
		physics_dupe.freeze = false
		held_in_place = false


func get_closest_snap_point() -> ItemSnapPoint:
	var closest := -1
	
	for i in range(len(potential_snap_points)):
		if closest == -1 or global_position.distance_to(potential_snap_points[i].global_position) < potential_snap_points[closest].global_position.distance_to(potential_snap_points[i].global_position):
			closest = i
	
	return potential_snap_points[closest] if closest != -1 else null
