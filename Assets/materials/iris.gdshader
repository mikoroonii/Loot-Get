shader_type canvas_item;

uniform float aperture : hint_range(0.0, 1.5) = 1.0;
uniform float aspect_ratio = 1.0;

void fragment() {
    vec2 centered_uv = UV - vec2(0.5);
    centered_uv.x *= aspect_ratio;
    
    float dist = length(centered_uv);
    
    float alpha_mask = step(dist, aperture);
    
    vec4 tex_color = texture(TEXTURE, UV);
    
    COLOR = vec4(tex_color.rgb, tex_color.a * alpha_mask);
}