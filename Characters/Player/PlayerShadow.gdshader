shader_type canvas_item;

uniform float shadow_scale = 0.0;
uniform vec4 shadow_color = vec4(0.25, 0.25, 0.25, 1.0);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR = mix(COLOR, (COLOR * shadow_color), shadow_scale);
}