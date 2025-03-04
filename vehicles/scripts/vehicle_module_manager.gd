extends Node3D

class_name VehicleModuleManager

@export var camera : Camera3D
@export var synchronizer : MultiplayerSynchronizer

@onready var controller := get_parent() as VehicleController

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	
	for m in get_children():
		m = m as VehicleModule
		if m:
			m.module_manager = self
			m.controller = controller
			m.setup()


func setup_cab_controllable(controllable : Controllable):
	controllable.camera = camera
	controllable.synchronizer = synchronizer
	controllable.root_owner = controller
	controller.controllable = controllable
	controllable.control_ended.connect(controller.on_uncontrolled)
