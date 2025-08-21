extends Node3D

@export var cam_holder : Node3D
@export var movement_manager : PlayerMovement

@onready var skeleton: Skeleton3D = $Armature_001/Skeleton3D
@onready var torso_override: BoneAttachment3D = $Armature_001/Skeleton3D/TorsoOverride
@onready var animation_tree: AnimationTree = $AnimationTree

@onready var hand_ik_r: SkeletonIK3D = $Armature_001/Skeleton3D/HandIK_R
@onready var hand_ik_l: SkeletonIK3D = $Armature_001/Skeleton3D/HandIK_L

@onready var equipment_manager : EquipmentManager = movement_manager.player_manager.equipment_manager

var held_item


func _ready() -> void:
	equipment_manager.equipped_item.connect(on_item_equipped)
	equipment_manager.dropped_item.connect(on_item_dropped)
	equipment_manager.swapped_item.connect(on_item_swapped)
	
	hand_ik_r.start()
	hand_ik_l.start()
	
	if not movement_manager.player_manager.is_multiplayer_authority():
		while len(equipment_manager.remote_transforms) == 0:
			await get_tree().process_frame
		for rt in equipment_manager.remote_transforms:
			print("REPARENTING ", rt)
			rt.reparent(torso_override)
			print("rt parent now: ", rt.get_parent_node_3d())


func _process(delta: float) -> void:
	var hip = skeleton.get_bone_global_pose(0)
	torso_override.position = hip.origin + hip.basis.y * 0.2
	torso_override.rotation = -cam_holder.rotation
	
	var velocity = movement_manager.velocity_sync.length()
	animation_tree.set("parameters/walk_velocity/blend_position", velocity/movement_manager.sprint_speed * int(movement_manager.floorcast.is_colliding()))


func on_item_equipped(item : Holdable):
	if equipment_manager.items[equipment_manager.cur_slot] == item:
		held_item = item
		do_item_ik(item)


func on_item_dropped(item : Holdable):
	if item == held_item:
		do_item_ik(null)


func on_item_swapped():
	do_item_ik(equipment_manager.items[equipment_manager.cur_slot])


func do_item_ik(item : Holdable):
	hand_ik_r.active = false
	hand_ik_l.active = false
	
	if item:
		if len(item.hand_positions) > 0:
			hand_ik_r.active = true
			hand_ik_r.target_node = item.hand_positions[0].get_path()
		if len(item.hand_positions) > 1:
			hand_ik_l.active = true
			hand_ik_r.target_node = item.hand_positions[1].get_path()
