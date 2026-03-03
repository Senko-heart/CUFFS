shader_type canvas_item;

uniform vec3 gamma;
uniform vec3 wmin;
uniform vec3 wmax;

void fragment() {
	vec3 adjusted = pow(COLOR.rgb, 1.0 / gamma);
	COLOR.rgb = (wmax - wmin) * adjusted + wmin;
}
