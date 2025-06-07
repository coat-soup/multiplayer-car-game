shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : source_color, hint_screen_texture;
uniform int _ColorCount = 32;
uniform float _Spread = 0.05;
uniform int _BayerLevel = 0; // 0 for 2x2, 1 for 4x4, 2 for 8x8

const int bayer2[4] = int[](
    0, 2,
    3, 1
);

const int bayer4[16] = int[](
    0, 8, 2, 10,
    12, 4, 14, 6,
    3, 11, 1, 9,
    15, 7, 13, 5
);

const int bayer8[64] = int[](
    0, 32, 8, 40, 2, 34, 10, 42,
    48, 16, 56, 24, 50, 18, 58, 26,
    12, 44,  4, 36, 14, 46,  6, 38,
    60, 28, 52, 20, 62, 30, 54, 22,
    3, 35, 11, 43,  1, 33,  9, 41,
    51, 19, 59, 27, 49, 17, 57, 25,
    15, 47,  7, 39, 13, 45,  5, 37,
    63, 31, 55, 23, 61, 29, 53, 21
);

// Functions to fetch Bayer matrix values
float get_bayer2(int x, int y) {
    return float(bayer2[(x % 2) + (y % 2) * 2]) / 4.0 - 0.5;
}

float get_bayer4(int x, int y) {
    return float(bayer4[(x % 4) + (y % 4) * 4]) / 16.0 - 0.5;
}

float get_bayer8(int x, int y) {
    return float(bayer8[(x % 8) + (y % 8) * 8]) / 64.0 - 0.5;
}

float get_bayer_value(int x, int y, int level) {
    if (level == 0) {
        return get_bayer2(x, y);
    } else if (level == 1) {
        return get_bayer4(x, y);
    } else {
        return get_bayer8(x, y);
    }
}

// Quantize the color with Bayer dithering
vec3 quantize_dithered(vec3 col, vec2 uv, float steps, float spread, int bayer_level, vec2 viewport_size) {
    vec2 texel_size = vec2(1.0 / viewport_size.x, 1.0 / viewport_size.y);
    int x = int(uv.x / texel_size.x);
    int y = int(uv.y / texel_size.y);

    float dither_value = get_bayer_value(x, y, bayer_level);

    col += spread * dither_value;

    col.r = floor((steps - 1.0) * col.r + 0.5) / (steps - 1.0);
    col.g = floor((steps - 1.0) * col.g + 0.5) / (steps - 1.0);
    col.b = floor((steps - 1.0) * col.b + 0.5) / (steps - 1.0);

    return col;
}

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    vec4 screen = texture(screen_texture, SCREEN_UV);
    vec2 uv = SCREEN_UV;

    vec3 dithered_color = quantize_dithered(screen.rgb, uv, float(_ColorCount), _Spread, _BayerLevel, VIEWPORT_SIZE);

    ALBEDO = dithered_color;
}
