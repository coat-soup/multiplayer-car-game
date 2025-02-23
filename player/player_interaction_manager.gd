extends Node

@export var camera : Camera3D
@export var max_distance := 3.0

@onready var player: PlayerMovement = $".."

var ui : UIManager

var target_interactable : Interactable

func _ready() -> void:
	ui = get_tree().get_first_node_in_group("ui") as UIManager
	if not ui:
		pass
		push_warning("Interactor couldn't find UI manager")


func _process(_delta: float) -> void:
	if not player.is_multiplayer_authority(): return
	
	do_raycast()
	if target_interactable and Input.is_action_just_pressed("interact"):
		target_interactable.interact(player)
		
	ui.set_interact_text("" if not target_interactable else target_interactable.observe(player), target_interactable != null)


func do_raycast():
	var space_state = player.get_world_3d().direct_space_state

	var origin = camera.global_position
	var end = origin + -camera.global_basis.z * max_distance
	var query = PhysicsRayQueryParameters3D.create(origin, end, Util.layer_mask([1,2,3]))
	query.exclude = [player]

	var result := space_state.intersect_ray(query)
	
	if result:
		target_interactable = result.collider as Interactable
	else:
		target_interactable = null
