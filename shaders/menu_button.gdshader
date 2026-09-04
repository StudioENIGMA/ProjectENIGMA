shader_type canvas_item;

// Two tone panel used behind the main menu buttons: a teal plate with rounded
// corners, cut by a diagonal band.

uniform vec4 base_color : source_color = vec4(0.161, 0.765, 0.639, 1.0);
uniform vec4 band_color : source_color = vec4(0.267, 0.847, 0.663, 1.0);
uniform float corner_radius : hint_range(0.0, 64.0) = 10.0;
// Horizontal position of the diagonal cut at the top and at the bottom edge.
uniform float band_top : hint_range(0.0, 1.0) = 0.99;
uniform float band_bottom : hint_range(0.0, 1.0) = 0.0;

// Signed distance to a rounded box, negative inside.
float rounded_box(vec2 point, vec2 half_size, float radius) {
	vec2 q = abs(point) - half_size + radius;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 pixel = fwidth(UV);
	vec2 half_size = 0.5 / pixel;
	float radius = min(corner_radius, min(half_size.x, half_size.y));

	float cut = mix(band_top, band_bottom, UV.y);
	float band = smoothstep(cut + pixel.x, cut - pixel.x, UV.x);

	COLOR = mix(base_color, band_color, band);
	COLOR.a *= smoothstep(0.5, -0.5, rounded_box(UV / pixel - half_size, half_size, radius));
}
