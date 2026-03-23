shader_type canvas_item;

uniform vec3 key_color = vec3(0.0, 1.0, 0.0); // Green color to remove
uniform float sensitivity : hint_range(0.0, 1.0) = 0.4;
uniform float smoothness : hint_range(0.0, 1.0) = 0.05;

void fragment() {
    vec4 video_color = texture(TEXTURE, UV);
    
    // Calculate difference between pixel and key color
    float diff = length(max(abs(video_color.rgb - key_color) - sensitivity, 0.0));
    
    // Apply alpha based on difference
    video_color.a = smoothstep(0.0, smoothness, diff);
    
    COLOR = video_color;
}
