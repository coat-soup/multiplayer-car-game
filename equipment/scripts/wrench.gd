extends Equipment

@export var heal_amount := 30.0
@export var cooldown := 0.9
@export var repair_range := 5.0
@export var anim : AnimationPlayer

const WRENCH_BONK_PARTICLES = preload("res://vfx/particles/wrench_bonk_particles.tscn")
@onready var audio: AudioStreamPlayer = $Audio

var on_cooldown := false
@onready var ui = get_tree().get_first_node_in_group("ui") as UIManager


func on_triggered(button : int):
	if on_cooldown or button != 0: return
	anim.play("wrench_swing")
	print("wrenching")
	
	var health : Health = raycast_health(true)
	if health:
		print("Trying repair on:" + health.name)
		#ui.display_prompt("Health: " + str(min(health.max_health, health.cur_health + heal_amount)), 0.5)
		health.heal.rpc(heal_amount, held_player.name.to_int())
		
		audio.pitch_scale = randf_range(0.9,1.1)
		audio.play()
	else: print("Didn't hit health")
	
	on_cooldown = true
	await get_tree().create_timer(cooldown).timeout
	on_cooldown = false


func _process(_delta: float) -> void:
	if not held_by_auth: return
	var health = raycast_health()
	if health:
		var component = health.get_parent().get_parent() as ShipComponent
		var component_name = (component.component_name + "\n") if component else ""
		ui.display_prompt(component_name + "Health:" + str(round(health.cur_health)), 0.1)


func raycast_health(do_particles := false) -> Health:
	var space_state = get_world_3d().direct_space_state

	var query = PhysicsRayQueryParameters3D.create(held_player.camera.global_position, held_player.camera.global_position - held_player.camera.global_basis.z * repair_range, Util.layer_mask([4]))
	query.exclude = [held_player]

	var result := space_state.intersect_ray(query)
	if result:
		if do_particles: Util.spawn_particles_for_time(result.position, WRENCH_BONK_PARTICLES, get_tree().root, 1.0)
		return result.collider.get_node_or_null("Health") as Health
	else:
		return null
