extends Area3D

@export var prefab_path : String
@export var level_manager : LevelManager

func _ready() -> void:
	body_entered.connect(on_body_entered)

func on_body_entered(body : Node3D):
	if body as PlayerMovement and (body as PlayerMovement).player.is_multiplayer_authority():
		spawn()


func spawn():
	#level_manager.spawn_item_replicated(prefab_path, global_position + global_basis.y)
	#level_manager.spawn_item_synced(prefab_path, global_position + global_basis.y)
	#level_manager.spawn_item_with_callback(prefab_path, global_position + global_basis.y, self, "item_spawned_callback")
	level_manager.spawn_item_synced_with_callback(prefab_path, global_position + global_basis.y, get_path(), "item_spawned_callback")


func item_spawned_callback(item_path : String):
	level_manager.mission_manager.ui.display_chat_message("Received local item reference from spawn")
