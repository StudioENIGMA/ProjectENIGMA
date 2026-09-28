// Darkens everything under the node. Over a few rounded rects it either leaves a bright hole,
// like a spotlight, or just draws a thin breathing outline, a discreet sign they can be tapped.
// The rects are given in the node's own coordinates and may be updated every frame.
shader_type canvas_item;

const int MAX_HOLES = 32;

// Colour laid over what is not lit
uniform vec4 dim_color : source_color = vec4(0.101960786, 0.1254902, 0.2, 0.62);
// Outline of the rects that are not lit
uniform vec4 outline_color : source_color = vec4(0.6392157, 0.9254902, 0.7607843, 0.5);
uniform float outline_width = 1.5;
// Seconds for the outline to fade out and back in
uniform float outline_period = 1.8;
// Fades the whole dim in and out, keeping the holes where they are
uniform float strength : hint_range(0.0, 1.0) = 1.0;
// Softness of the edge of each hole, in pixels
uniform float feather = 1.5;
uniform int hole_count = 0;
// Each rect as x, y, width and height, its corner radius, and 1 when it is lit, 0 otherwise
uniform vec4 holes[MAX_HOLES];
uniform float radii[MAX_HOLES];
uniform float lit_flags[MAX_HOLES];

varying vec2 local_position;

// Signed distance from p to a rounded box centered on the origin
float rounded_box(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + radius;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
}

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	float lit = 0.0;
	float outline = 0.0;
	for (int i = 0; i < MAX_HOLES; i++) {
		if (i >= hole_count) {
			break;
		}
		vec4 hole = holes[i];
		vec2 half_size = hole.zw * 0.5;
		float radius = min(radii[i], min(half_size.x, half_size.y));
		float distance = rounded_box(local_position - (hole.xy + half_size), half_size, radius);
		if (lit_flags[i] > 0.5) {
			lit = max(lit, 1.0 - smoothstep(-feather, feather, distance));
		} else {
			float line = abs(distance + outline_width * 0.5) - outline_width * 0.5;
			outline = max(outline, 1.0 - smoothstep(-0.5, 0.75, line));
		}
	}

	float breath = 0.55 + 0.45 * sin(TIME * 6.2831853 / outline_period);
	vec4 dimmed = vec4(dim_color.rgb, dim_color.a * (1.0 - lit));
	float outline_alpha = outline_color.a * breath * outline * (1.0 - lit);
	vec3 rgb = mix(dimmed.rgb, outline_color.rgb, outline_alpha);
	float alpha = outline_alpha + dimmed.a * (1.0 - outline_alpha);
	COLOR = vec4(rgb, alpha * strength);
}
