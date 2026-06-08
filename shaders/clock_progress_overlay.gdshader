shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;

uniform float progress: hint_range(0.0, 1.0) = 0.2;
uniform vec4 overlay_color: source_color = vec4(0.929, 0.063, 0.063, 0.2);
uniform float radius: hint_range(0.0, 0.5) = 0.50;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    
    // outside the clock circle — invisible
    if (dist > radius) {
        discard;
    }
    
    // angle from top (12 o'clock position) going clockwise
    float angle = atan(uv.x, -uv.y);  // 0 at top, increases clockwise
    if (angle < 0.0) {
        angle += 6.2831853;  // wrap to 0-TAU
    }
    
    float normalized_angle = angle / 6.2831853;  // 0.0 to 1.0
    
    // only show where angle is less than progress
    if (normalized_angle > progress) {
        discard;
    }
    
    ALBEDO = overlay_color.rgb;
    ALPHA = overlay_color.a;
}
