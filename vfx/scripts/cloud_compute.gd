extends Node

@export var texture_rect: TextureRect
@export var color : Color

@onready var cam : Camera3D = get_viewport().get_camera_3d()
var rd : RenderingDevice
var pipeline : RID
var uniform_set : RID
var color_buffer : RID
var cam_buffer : RID

var timer : float = 0.0

func _ready():
	rd = RenderingServer.get_rendering_device()
	
	var shader_file = preload("res://vfx/shaders/sphere_compute.glsl")
	var shader := rd.shader_create_from_spirv(shader_file.get_spirv())
	pipeline = rd.compute_pipeline_create(shader)
	
	var input_data := PackedFloat32Array([color.r, color.g, color.b]).to_byte_array()
	color_buffer = rd.storage_buffer_create(input_data.size(), input_data)
	var cam_data := get_cam_data(cam)
	cam_buffer = rd.storage_buffer_create(cam_data.size(), cam_data)
	
	var image := preload("res://vfx/textures/test_compute.png").get_image()
	image.convert(Image.FORMAT_RGBAF)
	
	var texture_view := RDTextureView.new()
	var texture_format := RDTextureFormat.new()
	texture_format.width = 1024
	texture_format.height = 1024
	texture_format.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	
	texture_format.usage_bits = (
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT +
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT +
		RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	)
	
	var texture := rd.texture_create(texture_format, texture_view, [image.get_data()])
	
	
	var parameter_uniform := RDUniform.new()
	parameter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameter_uniform.binding = 0
	parameter_uniform.add_id(color_buffer)
	
	var image_uniform := RDUniform.new()
	image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform.binding = 1
	image_uniform.add_id(texture)
	
	var cam_uniform := RDUniform.new()
	cam_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	cam_uniform.binding = 2
	cam_uniform.add_id(cam_buffer)
	
	uniform_set = rd.uniform_set_create([parameter_uniform, image_uniform, cam_uniform], shader, 0)

	
	
	# get modified image and display
	var texture_rd := Texture2DRD.new()
	texture_rd.texture_rd_rid = texture
	texture_rect.texture = texture_rd


func _process(delta: float) -> void:
	if not cam:
		cam = get_viewport().get_camera_3d()
	
	var cam_data = get_cam_data(cam)
	rd.buffer_update(cam_buffer, 0, cam_data.size(), cam_data)
	
	timer += delta / 10.0
	color = lerp(Color.CORNFLOWER_BLUE, Color.ORANGE, (sin(timer)))
	var input_data := PackedFloat32Array([color.r, color.g, color.b]).to_byte_array()
	rd.buffer_update(color_buffer, 0, input_data.size(), input_data)
	
	var compute_list := rd.compute_list_begin()
	
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 32, 32, 1)
	rd.compute_list_end()


func get_cam_data(camera: Camera3D) -> PackedByteArray:
	return PackedFloat32Array(
		[camera.global_position.x, camera.global_position.y, camera.global_position.z,
		camera.global_basis.z.x, camera.global_basis.z.y, camera.global_basis.z.z]
	).to_byte_array()
