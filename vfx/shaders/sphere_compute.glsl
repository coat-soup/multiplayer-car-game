#[compute]
#version 450

layout(set = 0, binding = 0, std430) readonly buffer parameters {
    float r;
    float g;
    float b;
} params;

layout(set = 0, binding = 1, rgba32f) uniform image2D image;

layout(local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

void main() {
    ivec2 uv = ivec2(gl_GlobalInvocationID.xy);
    vec4 color = imageLoad(image, uv);
    vec4 multiplier = vec4(params.r, params.g, params.b, 1.0);

    vec4 output_color = color * multiplier;
    imageStore(image, uv, output_color);
}
