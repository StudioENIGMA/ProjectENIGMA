shader_type canvas_item;

// Frosted glass: blurs whatever is drawn behind the node and washes it with a tint

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_radius : hint_range(0.0, 64.0) = 24.0;
uniform float blur_lod : hint_range(0.0, 5.0) = 2.5;
uniform vec4 tint : source_color = vec4(1.0, 1.0, 0.972549, 0.55);

const int TAPS = 6;

void fragment() {
	vec2 step_size = SCREEN_PIXEL_SIZE * blur_radius / float(TAPS);
	float sigma = float(TAPS) * 0.5;
	vec3 sum = vec3(0.0);
	float total = 0.0;

	for (int x = -TAPS; x <= TAPS; x++) {
		for (int y = -TAPS; y <= TAPS; y++) {
			float weight = exp(-float(x * x + y * y) / (2.0 * sigma * sigma));
			vec2 uv = clamp(SCREEN_UV + vec2(float(x), float(y)) * step_size, vec2(0.0), vec2(1.0));
			sum += textureLod(screen_texture, uv, blur_lod).rgb * weight;
			total += weight;
		}
	}

	COLOR = vec4(mix(sum / total, tint.rgb, tint.a), 1.0);
}
