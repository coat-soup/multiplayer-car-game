extends Node3D

@export var cam_holder : Node3D
@export var movement_manager : PlayerMovement
@onready var torso_override: BoneAttachment3D = $Armature_001/Skeleton3D/TorsoOverride
@onready var animation_tree: AnimationTree = $AnimationTree

func _process(delta: float) -> void:
	torso_override.rotation = -cam_holder.rotation
	
	var velocity = movement_manager.velocity_sync.length()
	animation_tree.set("parameters/walk_velocity/blend_position", velocity/movement_manager.sprint_speed * int(movement_manager.floorcast.is_colliding()))
