extends Node

@export var texture_rect: TextureRect
@export var color : Color


func _ready():
	var rd := RenderingServer.get_rendering_device()
	
	var shader_file = preload("res://vfx/shaders/sphere_compute.glsl")
	var shader := rd.shader_create_from_spirv(shader_file.get_spirv())
	var pipeline := rd.compute_pipeline_create(shader)
	
	var input_data := PackedFloat32Array([color.r, color.g, color.b]).to_byte_array()
	var storage_buffer := rd.storage_buffer_create(input_data.size(), input_data)
	
	
	
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
	
	
	
	
	# RUNNING THE SHADER:
	
	var parameter_uniform := RDUniform.new()
	parameter_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameter_uniform.binding = 0
	parameter_uniform.add_id(storage_buffer)
	
	var image_uniform := RDUniform.new()
	image_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	image_uniform.binding = 1
	image_uniform.add_id(texture)
	
	
	var uniform_set := rd.uniform_set_create([parameter_uniform, image_uniform], shader, 0)
	var compute_list := rd.compute_list_begin()
	
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	rd.compute_list_dispatch(compute_list, 32, 32, 1)
	rd.compute_list_end()
	
	 
	
	run_compute()
	
	# get modified image and display
	var texture_rd := Texture2DRD.new()
	texture_rd.texture_rd_rid = texture
	texture_rect.texture = texture_rd
	
	rd.free_rid(storage_buffer)


func run_compute() -> void:
	for x in range(32 * 32):
		for y in range(32 * 32):
			for z in range(1 * 1):
				# run shader
				var gl_GlobalInvocationID := Vector3(x,y,z)
