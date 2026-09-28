// Ages whatever a node draws itself (not its children) like an old sheet of paper:
// darkened, uneven edges, a few blotches, a coffee ring and a fine grain.
// The stains are laid out in the node's own coordinates, so they stay put when it moves.
shader_type canvas_item;

// Size of the drawing, in pixels, the stains are laid out on
uniform vec2 page_size = vec2(320.0, 240.0);
// Colour the paper turns towards where it is most aged, multiplied over it
uniform vec4 stain_color : source_color = vec4(0.62, 0.43, 0.24, 1.0);
// How strongly the edges, the blotches and the coffee ring age the paper
uniform float edge_strength : hint_range(0.0, 1.0) = 0.42;
uniform float blotch_strength : hint_range(0.0, 1.0) = 0.22;
uniform float ring_strength : hint_range(0.0, 1.0) = 0.3;
// Changes where the blotches fall
uniform float seed = 7.0;

varying vec2 local_position;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
		u.y
	);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 5; octave++) {
		value += amplitude * noise(p);
		p *= 2.03;
		amplitude *= 0.5;
	}
	return value;
}

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 p = local_position;

	// Edges browned unevenly, as if handled for years
	float edge_distance = min(min(p.x, page_size.x - p.x), min(p.y, page_size.y - p.y));
	float ragged = (fbm(p * 0.07 + seed) - 0.5) * 16.0;
	float edges = 1.0 - smoothstep(0.0, 22.0, edge_distance + ragged);

	// Soft blotches spread over the page
	float blotches = smoothstep(0.52, 0.78, fbm(p * 0.022 + seed * 3.1));

	// The dried rim of a cup put down near the bottom corner
	vec2 ring_center = vec2(page_size.x * 0.82, page_size.y * 0.86);
	float ring_radius = 34.0 + (fbm(p * 0.12) - 0.5) * 6.0;
	float ring_distance = abs(length(p - ring_center) - ring_radius);
	float ring = (1.0 - smoothstep(0.0, 2.5, ring_distance)) * smoothstep(0.35, 0.6, fbm(p * 0.05));
	ring += (1.0 - smoothstep(0.0, ring_radius, length(p - ring_center))) * 0.25;

	float grain = (noise(p * 0.8) - 0.5) * 0.08;
	float age = clamp(
		edges * edge_strength + blotches * blotch_strength + ring * ring_strength + grain,
		0.0,
		1.0
	);
	COLOR.rgb = mix(COLOR.rgb, COLOR.rgb * stain_color.rgb, age);
}
