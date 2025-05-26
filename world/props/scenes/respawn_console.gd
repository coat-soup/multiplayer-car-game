extends Node3D

@onready var interactable: Interactable = $Interactable
@onready var respawn_point: Node3D = $RespawnPoint
@onready var screen_mesh: MeshInstance3D = $Cube_003

const RESPAWN_SCREEN_GREEN = preload("res://world/props/textures/respawn_screen_green.tres")


func _ready() -> void:
	interactable.interacted.connect(on_interacted)


func on_interacted(player):
	player = player as Player
	player.respawn_point = respawn_point
	screen_mesh.set_surface_override_material(0, RESPAWN_SCREEN_GREEN)
