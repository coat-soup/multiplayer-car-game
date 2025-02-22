extends CharacterBody3D

class_name PlayerMovement

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D

@export var speed = 5.0
@export var jump_velocity = 4.5
@export var sensetivity = 0.005;

#viewbob
const BOB_FREQ = 2.5
const BOB_AMP = 0.05
var t_bob : float = 0.0

signal bob_top
signal bob_bottom

var landing : bool
signal jump_start
signal jump_land

var debug_mode = false



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(_event: InputEvent) -> void:
	if Input.is_key_pressed(KEY_SEMICOLON):
		debug_mode = !debug_mode
		if debug_mode:
			collision_shape_3d.disabled = true
		else:
			collision_shape_3d.disabled = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensetivity)
		camera_pivot.rotate_x(-event.relative.y * sensetivity)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, deg_to_rad(-90), deg_to_rad(90))


func _physics_process(delta: float) -> void:	
	# gravity
	if not is_on_floor() and !debug_mode:
		velocity += get_gravity() * delta
		
	# input
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if debug_mode:
		velocity.y = (int(Input.is_key_pressed(KEY_SPACE)) - int(Input.is_key_pressed(KEY_CTRL))) * speed
	
	# jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if input_dir.y < 0 or input_dir == Vector2.ZERO:
			jump_start.emit()
			velocity.y = jump_velocity
		
		
	elif is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 10)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 10)
		
		if landing:
			landing = false
			if velocity.y < 1:
				jump_land.emit()
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2)
		
		if !landing:
			landing = true

	# viewbob
	t_bob += delta * velocity.length() * float(is_on_floor())
	var b : float = bob_calc(t_bob)
	camera.transform.origin = Vector3(0, b, 0)
	
	# bob signals
	if b/BOB_AMP < 0.05:
		bob_bottom.emit()
	elif b/BOB_AMP > 0.95:
		bob_top.emit()

	move_and_slide()

func bob_calc(time : float) -> float:
	return BOB_AMP * sin(time * BOB_FREQ)
