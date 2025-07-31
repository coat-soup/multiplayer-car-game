extends Equipment
class_name TractorTool

@onready var beam: TractorBeam = $TractorBeam


@onready var audio: AudioStreamPlayer3D = $Audio
@onready var cone: MeshInstance3D = $Cone
@export var color_by_norm_dist_grad : Gradient


func _ready() -> void:
	super._ready()
	beam.tractor_started.connect(on_tractor_started)
	beam.tractor_ended.connect(on_tractor_ended)


func on_triggered(button : int):
	if button != 0: return
	if beam.target:
		beam.stop_grab()
	else:
		beam.start_grab()


func _input(event: InputEvent) -> void:
	super._input(event)
	if not held_by_auth: return
	var scroll_dir = int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_DOWN)) - int(Input.is_mouse_button_pressed(MOUSE_BUTTON_WHEEL_UP))
	if scroll_dir != 0:
		beam.target_distance = clamp(beam.target_distance - scroll_dir * 0.2, 2.0, beam.beam_range)
	if Input.is_action_just_released("secondary_fire"):
		held_player.movement_manager.camera_locked = false


func _process(delta: float) -> void:
	if beam.t_phys:
		audio.pitch_scale = lerp(1.0,1.2, beam.get_normalised_lag_distance())
		#(cone.get_surface_override_material(0) as StandardMaterial3D).albedo_color = color_by_norm_dist_grad.sample(normalised_lag_distance)


func on_tractor_started(item):
	cone.visible = true
	audio.playing = true


func on_tractor_ended(item):
	cone.visible = false
	audio.playing = false


func on_picked_up():
	super.on_picked_up()
	beam.player = held_player


func on_dropped():
	super.on_dropped()
	beam.stop_grab()
	beam.player = null


func on_put_away():
	super.on_put_away()
	beam.stop_grab()
