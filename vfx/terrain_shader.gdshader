// This shader is the minimum needed to allow the terrain to function, without any texturing.

shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_burley,specular_schlick_ggx,skip_vertex_transform;

// Private uniforms
uniform float _region_size = 1024.0;
uniform float _region_texel_size = 0.0009765625; // = 1/1024
uniform float _vertex_spacing = 1.0;
uniform float _vertex_density = 1.0; // = 1/_vertex_spacing
uniform int _region_map_size = 32;
uniform int _region_map[1024];
uniform vec2 _region_locations[1024];
uniform sampler2DArray _height_maps : repeat_disable;
uniform usampler2DArray _control_maps : repeat_disable;
uniform sampler2DArray _color_maps : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform sampler2DArray _texture_array_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray _texture_array_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

uniform float _texture_uv_scale_array[32];
uniform float _texture_detile_array[32];
uniform vec4 _texture_color_array[32];
uniform uint _background_mode = 1u;  // NONE = 0, FLAT = 1, NOISE = 2
uniform uint _mouse_layer = 0x80000000u; // Layer 32

// Public uniforms
uniform float vertex_normals_distance : hint_range(0, 1024) = 128.0;

// Varyings & Types
varying flat vec3 v_vertex;	// World coordinate vertex location
varying flat vec3 v_camera_pos;
varying float v_vertex_xz_dist;
varying flat ivec3 v_region;
varying flat vec2 v_uv_offset;
varying flat vec2 v_uv2_offset;
varying vec3 v_normal;
varying float v_region_border_mask;

////////////////////////
// Vertex
////////////////////////

// Takes in UV world space coordinates, returns ivec3 with:
// XY: (0 to _region_size) coordinates within a region
// Z: layer index used for texturearrays, -1 if not in a region
ivec3 get_region_uv(const vec2 uv) {
	ivec2 pos = ivec2(floor(uv * _region_texel_size)) + (_region_map_size / 2);
	int bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
	int layer_index = _region_map[ pos.y * _region_map_size + pos.x ] * bounds - 1;
	return ivec3(ivec2(mod(uv,_region_size)), layer_index);
}

// Takes in UV2 region space coordinates, returns vec3 with:
// XY: (0 to 1) coordinates within a region
// Z: layer index used for texturearrays, -1 if not in a region
vec3 get_region_uv2(const vec2 uv2) {
	// Remove Texel Offset to ensure correct region index.
	ivec2 pos = ivec2(floor(uv2 - vec2(_region_texel_size * 0.5))) + (_region_map_size / 2);
	int bounds = int(uint(pos.x | pos.y) < uint(_region_map_size));
	int layer_index = _region_map[ pos.y * _region_map_size + pos.x ] * bounds - 1;
	return vec3(uv2 - _region_locations[layer_index], float(layer_index));
}

// 1 lookup
float get_height(vec2 uv) {
	highp float height = 0.0;
	vec3 region = get_region_uv2(uv);
	if (region.z >= 0.) {
		height = texture(_height_maps, region).r;
	}
 	return height;
}

void vertex() {
	// Get camera pos in world vertex coords
	v_camera_pos = INV_VIEW_MATRIX[3].xyz;

	// Get vertex of flat plane in world coordinates and set world UV
	v_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	// Camera distance to vertex on flat plane
	v_vertex_xz_dist = length(v_vertex.xz - v_camera_pos.xz);

	// UV coordinates in world space. Values are 0 to _region_size within regions
	UV = round(v_vertex.xz * _vertex_density);

	// UV coordinates in region space + texel offset. Values are 0 to 1 within regions
	UV2 = fma(UV, vec2(_region_texel_size), vec2(0.5 * _region_texel_size));

	// Discard vertices for Holes. 1 lookup
	v_region = get_region_uv(UV);
	uint control = texelFetch(_control_maps, v_region, 0).r;
	bool hole = bool(control >>2u & 0x1u);

	// Show holes to all cameras except mouse camera (on exactly 1 layer)
	if ( !(CAMERA_VISIBLE_LAYERS == _mouse_layer) &&
			(hole || (_background_mode == 0u && (get_region_uv(UV - _region_texel_size) & v_region).z < 0))) {
		VERTEX.x = 0. / 0.;
	} else {
		// Set final vertex height & calculate vertex normals. 3 lookups.
		VERTEX.y = get_height(UV2);
		v_vertex.y = VERTEX.y;
		v_normal = vec3(
			v_vertex.y - get_height(UV2 + vec2(_region_texel_size, 0)),
			_vertex_spacing,
			v_vertex.y - get_height(UV2 + vec2(0, _region_texel_size))
		);
		// Due to a bug caused by the GPUs linear interpolation across edges of region maps,
		// mask region edges and use vertex normals only across region boundaries.
		v_region_border_mask = mod(UV.x + 2.5, _region_size) - fract(UV.x) < 5.0 || mod(UV.y + 2.5, _region_size) - fract(UV.y) < 5.0 ? 1. : 0.;
	}

	// Transform UVs to local to avoid poor precision during varying interpolation.
	v_uv_offset = MODEL_MATRIX[3].xz * _vertex_density;
	UV -= v_uv_offset;
	v_uv2_offset = v_uv_offset * _region_texel_size;
	UV2 -= v_uv2_offset;

	// Convert model space to view space w/ skip_vertex_transform render mode
	VERTEX = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX = (VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	BINORMAL = normalize((MODELVIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
	TANGENT = normalize((MODELVIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);
}

////////////////////////
// Fragment
////////////////////////

// 0 - 3 lookups
vec3 get_normal(vec2 uv, out vec3 tangent, out vec3 binormal) {
	float u, v, height;
	vec3 normal;
	// Use vertex normals within radius of vertex_normals_distance, and along region borders.
	if (v_region_border_mask > 0.5 || v_vertex_xz_dist < vertex_normals_distance) {
		normal = normalize(v_normal);
	} else {
		height = get_height(uv);
		u = height - get_height(uv + vec2(_region_texel_size, 0));
		v = height - get_height(uv + vec2(0, _region_texel_size));
		normal = normalize(vec3(u, _vertex_spacing, v));
	}
	tangent = cross(normal, vec3(0, 0, 1));
	binormal = cross(normal, tangent);
	return normal;
}

void fragment() {
	// Recover UVs
	vec2 uv = UV + v_uv_offset;
	vec2 uv2 = UV2 + v_uv2_offset;

	// Calculate Terrain Normals. 4 lookups
	vec3 w_tangent, w_binormal;
	vec3 w_normal = get_normal(uv2, w_tangent, w_binormal);
	NORMAL = mat3(VIEW_MATRIX) * w_normal;
	TANGENT = mat3(VIEW_MATRIX) * w_tangent;
	BINORMAL = mat3(VIEW_MATRIX) * w_binormal;

	// Apply PBR
	ALBEDO=vec3(.2);

	int t_index = get_region_uv(uv).z;
	float uv_scale = _texture_uv_scale_array[t_index];

	vec3 tex_col = texture(_texture_array_albedo, vec3(uv.r * uv_scale, uv.g * uv_scale, float(t_index))).rgb;
	tex_col *= _texture_color_array[t_index].rgb;

	ALBEDO= tex_col;
	ALBEDO= vec3(float(t_index)/100.0);
}
