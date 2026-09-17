shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float phase = 0.0;
uniform float strength : hint_range(0.0, 1.0) = 0.4;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
void vertex() {
 float ripple = sin(VERTEX.y * 17.0 + phase * 9.0 + VERTEX.x * 11.0);
 VERTEX.xz *= 1.0 + ripple * 0.08;
}
void fragment() {
 float flow = sin(UV.x * 19.0 + UV.y * 15.0 - phase * 9.0)
  + sin(UV.x * 31.0 - UV.y * 23.0 + phase * 6.0) * 0.35;
 float flame = smoothstep(-0.7, 0.8, flow);
 vec3 red = vec3(0.65, 0.09, 0.025);
 vec3 orange = vec3(0.98, 0.39, 0.045);
 vec3 core = vec3(1.0, 0.77, 0.22);
 ALBEDO = mix(mix(red, orange, flame), core, strength * flame * 0.62);
 float edge = pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), 0.32);
 ALPHA = opacity * edge * (0.65 + 0.25 * flame);
}
