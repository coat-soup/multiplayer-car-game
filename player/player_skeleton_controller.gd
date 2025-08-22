extends Node3D
class_name PlayerSkeletonController

@export var cam_holder : Node3D
@export var movement_manager : PlayerMovement

@onready var skeleton: Skeleton3D = $Armature_001/Skeleton3D
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var torso_ik: LookAtModifier3D = $Armature_001/Skeleton3D/TorsoIK
@export var right_arm_ik : Array[LookAtModifier3D]
@export var left_arm_ik : Array[LookAtModifier3D]

@onready var hand_target_r: Marker3D = $HandTarget_R
@onready var hand_target_l: Marker3D = $HandTarget_L

@onready var equipment_manager : EquipmentManager = movement_manager.player_manager.equipment_manager

var held_item


func _ready() -> void:
	equipment_manager.equipped_item.connect(on_item_equipped)
	equipment_manager.dropped_item.connect(on_item_dropped)
	equipment_manager.swapped_item.connect(on_item_swapped)
	
	torso_ik.position = skeleton.get_bone_pose_position(0)
	
	if not movement_manager.player_manager.is_multiplayer_authority():
		while len(equipment_manager.remote_transforms) == 0:
			await get_tree().process_frame
		for rt in equipment_manager.remote_transforms:
			rt.reparent(torso_ik)
	
	if movement_manager.player_manager.is_multiplayer_authority(): visible = false


func _process(delta: float) -> void:
	if movement_manager.player_manager.is_multiplayer_authority():
		torso_ik.active = false
	
	
	torso_ik.rotation = -cam_holder.rotation 
	
	var velocity = movement_manager.velocity_sync.length()
	animation_tree.set("parameters/walk_velocity/blend_position", velocity/movement_manager.sprint_speed * int(movement_manager.floorcast.is_colliding()))
	
	if held_item:
		if len(held_item.hand_positions) > 0: hand_target_r.global_position = held_item.hand_positions[0].global_position
		if len(held_item.hand_positions) > 1: hand_target_l.global_position = held_item.hand_positions[1].global_position


func setup(shirt_colour : Color):
	($Armature_001/Skeleton3D/Cube_011 as GeometryInstance3D).set_instance_shader_parameter("custom_colour", shirt_colour)
	print("setting shirt color to ", shirt_colour)


func on_item_equipped(item : Holdable):
	if equipment_manager.items[equipment_manager.cur_slot] == item:
		held_item = item
		do_item_ik()


func on_item_dropped(item : Holdable):
	if item == held_item:
		held_item = null
		do_item_ik()


func on_item_swapped():
	held_item = equipment_manager.items[equipment_manager.cur_slot]
	print("SWAPPING ITEM TO ", held_item)
	do_item_ik()


func do_item_ik():
	for ik in right_arm_ik: ik.active = held_item and len(held_item.hand_positions) > 0
	for ik in left_arm_ik: ik.active = held_item and len(held_item.hand_positions) > 1
