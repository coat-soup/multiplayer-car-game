extends Node

@export var marker_holder: Node3D
const RADAR_MARKER = preload("res://ship/systems/radar/radar_marker.tscn")

var signatures : Array[RadarSignature]
var markers : Array[Node3D]

@export var update_interval := 0.05
@export var map_scale := 0.0005
@export var radar_manager : RadarManager

@export var marker_scale = 0.03


func _ready() -> void:
	radar_manager.tracked_signature.connect(add_marker)
	radar_manager.lost_signature.connect(remove_marker)
	
	update_markers()


func add_marker(signature : RadarSignature):
	for i in range(len(radar_manager.tracked_signatures)):
		if len(markers) > i: continue 							# WARNING: Im not sure about the numbering here
		
		var marker = RADAR_MARKER.instantiate() as Node3D
		marker_holder.add_child(marker)
		radar_manager.tracked_signatures[i].set_marker_colour(marker)
		
		markers.append(marker)
		marker.scale = Vector3(marker_scale,marker_scale,marker_scale)
		#print("RECEIVED TRACK ", radar_manager.tracked_signatures[i].signature_name)


func remove_marker(signature, id):
	if id < 0 or id >= len(signatures): return
	markers[id].queue_free()
	markers.remove_at(id)
	
	#print("lost sig", signature)


func update_markers():
	for i in range(len(markers)):
		if not is_instance_valid(radar_manager.tracked_signatures[i]): continue
		markers[i].position = radar_manager.to_local(radar_manager.tracked_signatures[i].global_position) * map_scale
		
		var e_line = markers[i].get_node("ElevationLine") as Sprite3D
		var ns =  abs(markers[i].position.y / 9.0 / map_scale) / 2 * (map_scale / 0.001)
		e_line.visible = true
		e_line.region_rect = Rect2(0,0,0.2,ns)
		e_line.offset.y = (ns if markers[i].position.y > 0 else -ns)/-2
			
	
	#if len(markers) != len(radar_manager.tracked_signatures)
	
	await get_tree().create_timer(update_interval).timeout
	update_markers()
