shader_type canvas_item;

// The value between 0.0 and 1.0 that determines what portion of the health bar is filled in.
uniform float fill_ratio = 1.0;

uniform vec3 health_bar_foreground_color = vec3(0.0, 0.9, 0.0);
uniform vec3 health_bar_background_color = vec3(0.3, 0.3, 0.3);

void fragment() {
	COLOR = texture(TEXTURE, UV);
	
	if(UV.x <= fill_ratio)
	{
		COLOR *= vec4(health_bar_foreground_color, COLOR.a);
	}
	else
	{
		COLOR *= vec4(health_bar_background_color, COLOR.a);
	}
}
