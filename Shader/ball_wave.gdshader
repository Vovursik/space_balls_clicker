shader_type canvas_item;
render_mode unshaded;

uniform float radius : hint_range(10, 500) = 150.0;
uniform float rubber_intensity : hint_range(0.0, 0.5) = 0.2;
uniform float speed : hint_range(0.5, 5.0) = 2.0;
uniform float stretch : hint_range(0.8, 1.5) = 1.1;
uniform vec4 color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec2 center = vec2(0.5);
    vec2 uv = UV - center;
    float t = TIME * speed;
    float dist2 = dot(uv, uv) * 4.0;
    float distortion = sin(dist2 * 10.0 - t * 5.0) * rubber_intensity;
	
    distortion += sin(uv.x * 8.0 + t) * rubber_intensity * 0.3;
	
    vec2 distorted_uv = uv * (1.0 + distortion) * stretch;
    vec2 final_uv = distorted_uv + center;
    float dist_mask = dot(distorted_uv, distorted_uv) * 4.0 * radius;
    vec4 tex_color = texture(TEXTURE, final_uv);
    float edge_light = clamp(1.0 - dist_mask / radius, 0.0, 0.5);
    tex_color.rgb += edge_light;

    COLOR = color;
    COLOR.a *= tex_color.a;

    if (dist_mask > radius) {
        COLOR.a = 0.0;
    }
}