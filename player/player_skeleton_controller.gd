extends Node3D

@export var cam_holder : Node3D
@onready var torso_override: BoneAttachment3D = $Armature_001/Skeleton3D/TorsoOverride

func _process(delta: float) -> void:
	torso_override.rotation = -cam_holder.rotation
