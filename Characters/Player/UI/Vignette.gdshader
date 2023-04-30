shader_type canvas_item;

uniform float pulse_ratio = 0.5;
uniform float pulse_offset = 0.3;
uniform float vignette_alpha_offset = -0.2;
uniform float vignette_alpha = 1.0;
uniform vec3 sun_damage_color: source_color = vec3(0.86, 0.47, 0.0);

void fragment()
{
	COLOR = texture(TEXTURE, UV);
	float current_pulse_value = sin(TIME) * pulse_ratio;
	current_pulse_value += pulse_offset;
	
	vec3 color_change = sun_damage_color * current_pulse_value;
	
	float current_alpha_value = vignette_alpha + vignette_alpha_offset;
	
	COLOR = vec4(COLOR.rgb * (sun_damage_color + color_change), COLOR.a * current_alpha_value);
}