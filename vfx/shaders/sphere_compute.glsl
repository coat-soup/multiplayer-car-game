#[compute]
#version 450

layout(set = 0, binding = 0, std430) readonly buffer colour_multiplier {
    float r;
    float g;
    float b;
} col;

layout(set = 0, binding = 1, rgba32f) uniform image2D image;

layout(set = 0, binding = 2, std430) readonly buffer camera_transform {
    vec3 pos;
    vec3 forward;
} cam;

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);

    // Simple depth approximation: distance along camera forward
    vec3 frag_pos = vec3(uv, 0.0); // placeholder, normally you'd have world/view position
    float depth = dot(frag_pos - cam.pos, cam.forward);

    // Fog factor: linear fog with start/end distances
    float fog_start = 10.0;
    float fog_end = 50.0;
    float fog_factor = clamp((depth - fog_start) / (fog_end - fog_start), 0.0, 1.0);

    // Fog color
    vec3 fog_color = vec3(0.5); // gray fog

    // Original color
    vec4 output_color = vec4(fog_color.x, fog_color.y, fog_color.z, fog_factor);

    // Mix with fog
    output_color.rgb = mix(output_color.rgb, fog_color, fog_factor);

    //DEBUG
    output_color = vec4(col.r, col.g, col.b, 1.0) * vec4(sin(cam.pos.x));

    imageStore(image, uv, output_color);
}
