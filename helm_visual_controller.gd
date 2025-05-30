extends Node3D

@export var controller : ShipMovementManager
@onready var throttle: MeshInstance3D = $ThrottleSlide/Throttle
@onready var grips: MeshInstance3D = $Grips


func _process(_delta: float) -> void:
	grips.rotation = Vector3(controller.virtual_joystick_value.x, controller.rotation_input.z, controller.virtual_joystick_value.y)
	throttle.position.x = controller.directional_input.z/5.0
