shader_type canvas_item;

uniform float shadow_scale = 0.0;
uniform vec4 shadow_color = vec4(0.25, 0.25, 0.25, 1.0);
uniform bool invincible = false;
uniform float invincibility_speed_scale = 50.0;
uniform float invincibility_color_scale = 1.05;
uniform float invicibility_color_add = 0.3;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	COLOR = mix(COLOR, (COLOR * shadow_color), shadow_scale);
	
	if(invincible)
	{
		float flash_scale = 0.0;
		
		if(shadow_scale >= 1.0)
		{
			flash_scale = 1.0;
		}
		
		COLOR = mix(COLOR, vec4((COLOR.xyz + (invicibility_color_add * flash_scale)) * invincibility_color_scale, COLOR.a), cos(TIME * invincibility_speed_scale));
	}
}