extends Node3D
class_name RadarManager

signal tracked_signature
signal lost_signature(sig, id)

## eg. 1.0 = at 500m, emission must be >500 to passively scan
@export var passive_emission_per_meter : float = 1.0

## eg. 0.66 = if tracked at 500 emission, must be >750m to lose track
@export var untrack_emission_per_meter : float = 0.67

var tracked_signatures : Array[RadarSignature]

@export var passive_scan_interval : float = 3.0
@export var self_sig : RadarSignature


func _ready() -> void:
	await get_tree().create_timer(passive_scan_interval).timeout
	passive_scan()
	lost_signature.connect(on_lost_signature)


func passive_scan():
	for signature in get_tree().get_nodes_in_group("radar signature"):
		signature = signature as RadarSignature
		if signature == self_sig: continue
		
		var tracked_id : int = tracked_signatures.find(signature)
		var strength : float = get_relative_signature_strenth(signature)
		
		#print("looking at signal: ", signature.signature_name, " strength ", strength, " tracked: ", tracked_id)
		
		if tracked_id == -1 and strength >= passive_emission_per_meter:
			tracked_signatures.append(signature)
			tracked_signature.emit(signature)
			signature.terminated.connect(on_signature_terminated.bind(signature))
			#print("TRACKING ", signature.signature_name)
		
		elif tracked_id != -1 and strength <= untrack_emission_per_meter:
			lose_signature(signature, tracked_id)
	
	
	await get_tree().create_timer(passive_scan_interval).timeout
	passive_scan()


func get_relative_signature_strenth(signature : RadarSignature) -> float:
	return signature.emission_strength / signature.global_position.distance_to(global_position)


func on_signature_terminated(sig : RadarSignature):
	lose_signature(sig)


func on_lost_signature(sig : RadarSignature, _id : int):
	sig.terminated.disconnect(on_signature_terminated)


func lose_signature(sig : RadarSignature, id = -1):
	if id == -1: id = tracked_signatures.find(sig)
	if sig == null: sig = tracked_signatures[id]
	
	tracked_signatures.remove_at(id)
	lost_signature.emit(sig, id)
