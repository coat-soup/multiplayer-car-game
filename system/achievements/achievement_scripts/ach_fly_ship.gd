extends Node

@export var helm : HelmVisuals
const achievement_name : String = "ACH_FLY_SHIP"

func _ready() -> void:
	helm.controller.controllable.control_started.connect(on_controlled)


func on_controlled():
	if helm.controller.controllable.using_player.is_multiplayer_authority():
		AchievementManager.unlock_achievement(achievement_name)
