shader_type canvas_item;

uniform float scene_transition_ratio = 0.0;

void fragment() {
	COLOR = vec4(0.0, 0.0, 0.0, scene_transition_ratio);
}
