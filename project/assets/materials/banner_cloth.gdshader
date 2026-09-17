shader_type spatial;
render_mode cull_disabled;
uniform float wind_time = 0.0;
uniform vec4 cloth_color : source_color = vec4(.065,.23,.34,1.0);
uniform vec4 gold_color : source_color = vec4(.82,.66,.34,1.0);
void vertex() {
 float weight=UV.y*UV.y;
 VERTEX.x += (sin(wind_time*2.2+UV.y*5.0)+sin(wind_time*3.4+UV.x*6.0)*.25)*weight*.06;
}
void fragment() {
 float edge=step(UV.x,.065)+step(.935,UV.x)+step(.94,UV.y);
 float stem=step(abs(UV.x-.5),.052)*step(.28,UV.y)*step(UV.y,.72);
 float crown=step(abs(UV.x-.5),.23)*step(.27,UV.y)*step(UV.y,.36);
 float crenels=step(abs(UV.x-.5),.23)*step(.19,UV.y)*step(UV.y,.28)*step(.40,fract(UV.x*9.0));
 float emblem=clamp(edge+stem+crown+crenels,0.0,1.0);
 // Fade woven detail when a thread becomes smaller than a screen pixel.
 float weave_visibility=1.0-smoothstep(.008,.025,max(fwidth(UV.x),fwidth(UV.y)));
 float weave=sin(UV.x*170.0)*sin(UV.y*170.0)*.008*weave_visibility;
 ALBEDO=mix(cloth_color.rgb,gold_color.rgb,emblem)+weave;
 ROUGHNESS=.88;
}
