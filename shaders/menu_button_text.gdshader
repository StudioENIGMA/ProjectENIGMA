shader_type canvas_item;

// Label tint for the main menu buttons: the same diagonal cut used by the plate
// behind them, dark over the light band and brighter over the base plate.

uniform vec4 base_color : source_color = vec4(0.588, 0.078, 0.22, 1.0);
uniform vec4 band_color : source_color = vec4(0.404, 0.055, 0.204, 1.0);
// Label size in pixels, kept up to date by menu_button_label.gd. Glyph UVs point
// into the font atlas, so the cut is placed from the local vertex position.
uniform vec2 rect_size = vec2(1.0, 1.0);
// Horizontal position of the diagonal cut at the top and at the bottom edge.
uniform float band_top : hint_range(0.0, 1.0) = 0.99;
uniform float band_bottom : hint_range(0.0, 1.0) = 0.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

void fragment() {
	vec2 uv = local_position / rect_size;
	float aa = fwidth(uv.x);
	float cut = mix(band_top, band_bottom, uv.y);
	float band = smoothstep(cut + aa, cut - aa, uv.x);

	COLOR.rgb = mix(base_color.rgb, band_color.rgb, band);
}
