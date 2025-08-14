extends Holdable
class_name FireExtinguisher

@export var extinguish_per_second := 1.0
@export var extinguish_range := 6.0

@onready var particles: GPUParticles3D = $Particles
@onready var audio: AudioStreamPlayer3D = $Audio

var doing_thing := false
var fire_manager : FireManager


func _ready() -> void:
	fire_manager = get_tree().get_first_node_in_group("ship").get_node_or_null("FireManager") as FireManager
	super._ready()


func on_triggered(button : int):
	if button == 0:
		doing_thing = true
		toggle_fx.rpc(true)


func on_trigger_ended(button : int):
	if button == 0:
		doing_thing = false
		toggle_fx.rpc(false)


@rpc("any_peer", "call_local")
func toggle_fx(value : bool):
		particles.emitting = value
		audio.playing = value


func _process(delta: float) -> void:
	if held_by_auth and doing_thing and fire_manager:
		var space_state = get_world_3d().direct_space_state

		var query = PhysicsRayQueryParameters3D.create(held_player.camera.global_position, held_player.camera.global_position - held_player.camera.global_basis.z * extinguish_range, Util.layer_mask([1]))
		query.exclude = [held_player.movement_manager]

		var result := space_state.intersect_ray(query)
		if result:
			var fire = fire_manager.fires.get(fire_manager.world_to_grid_pos(result.position)) as Fire
			if fire:
				fire_manager.try_extinguish_at_pos.rpc(fire.grid_pos, extinguish_per_second * delta)
				#fire.add_extinguish.rpc(extinguish_per_second * delta)
