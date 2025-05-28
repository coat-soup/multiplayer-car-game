extends Node3D
class_name RadarSignature

@export var signature_name : String = "Unidentified Signature"
@export var marker_mat : Material


func set_marker_colour(marker : Node3D):
	(marker.get_node("Visual") as CSGSphere3D).material = marker_mat
