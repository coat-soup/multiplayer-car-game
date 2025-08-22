extends Node3D
class_name RadarSignature

signal terminated

@export var signature_name : String = "Unidentified Signature"
@export var emission_strength : float = 500.0

enum SignatureType {STATIC, DYNAMIC}
enum SignatureRelation {NEUTRAL, FRIENDLY, HOSTILE}

@export var type : SignatureType = SignatureType.DYNAMIC
@export var relation : SignatureRelation = SignatureRelation.NEUTRAL

@export var health_node : Health


func _ready() -> void:
	if health_node:
		health_node.died.connect(queue_free)


func set_marker_colour(marker : Node3D):
	(marker.get_node("Visual") as CSGSphere3D).material = 	[preload("res://ship/systems/radar/marker_materials/radar_marker_planet.tres"),
															preload("res://ship/systems/radar/marker_materials/radar_marker_friendly.tres"),
															preload("res://ship/systems/radar/marker_materials/radar_marker_enemy.tres")][relation]
	(marker.get_node("Label3D") as Label3D).text = get_parent_node_3d().name


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		terminate()

func terminate():
	print("TERMINATING SIGNAL")
	terminated.emit()
