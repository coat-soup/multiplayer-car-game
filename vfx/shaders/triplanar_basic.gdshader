shader_type spatial;

uniform sampler2D albedo_texture: source_color, filter_nearest;
uniform sampler2D normal_texture: hint_normal, filter_nearest;

uniform sampler2D albedo_texture_far: source_color;
uniform sampler2D normal_texture_far: hint_normal;
uniform float scale;

uniform sampler2D depth_texture : hint_depth_texture;


varying vec3 world_position;

void vertex()
{
    world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 vertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 adjusted_normal = pow(abs(normal), vec3(8.0));
	vec3 weights = adjusted_normal / (adjusted_normal.x + adjusted_normal.y + adjusted_normal.z) * 3.0;
	
	vec2 uv_x = vertex.zy * scale;
	vec2 uv_y = vertex.xz * scale;
	vec2 uv_z = vertex.xy * scale;
	
	float d = distance(world_position, CAMERA_POSITION_WORLD);
	
	if (d > 50.0) {
		vec3 color_x = texture(albedo_texture_far, uv_x).rgb * weights.x;
		vec3 color_y = texture(albedo_texture_far, uv_y).rgb * weights.y;
		vec3 color_z = texture(albedo_texture_far, uv_z).rgb * weights.z;
		
		ALBEDO = (color_x + color_y + color_z) / 3.0;
		
		vec3 normal_x = texture(normal_texture_far, uv_x).rgb * weights.x;
		vec3 normal_y = texture(normal_texture_far, uv_y).rgb * weights.y;
		vec3 normal_z = texture(normal_texture_far, uv_z).rgb * weights.z;
		
		NORMAL_MAP = (normal_x + normal_y + normal_z) / 3.0;
	}
	else{
		vec3 color_x = texture(albedo_texture, uv_x).rgb * weights.x;
		vec3 color_y = texture(albedo_texture, uv_y).rgb * weights.y;
		vec3 color_z = texture(albedo_texture, uv_z).rgb * weights.z;
		
		ALBEDO = (color_x + color_y + color_z) / 3.0;
		
		vec3 normal_x = texture(normal_texture, uv_x).rgb * weights.x;
		vec3 normal_y = texture(normal_texture, uv_y).rgb * weights.y;
		vec3 normal_z = texture(normal_texture, uv_z).rgb * weights.z;
		
		NORMAL_MAP = (normal_x + normal_y + normal_z) / 3.0;
	}
}