shader_type spatial;
render_mode diffuse_burley;
float hash(vec2 p) {return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p);f=f*f*(3.0-2.0*f);
 return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
varying vec3 world;
void vertex(){ world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment(){
 float footprint=max(length(dFdx(world.xz)),length(dFdy(world.xz)));
 float fine_visibility=1.0-smoothstep(.025,.085,footprint);
 float n=noise(world.xz*.65)*.6+noise(world.xz*3.7)*.25+mix(.5,noise(world.xz*13.0),fine_visibility)*.15;
 float center=sin(world.x*.13)*.40;
 float edge=abs(world.z-center);
 float road=1.0-smoothstep(2.0+n*.7,2.75+n*.5,edge);
 float patches=noise(world.xz*.19);
 vec3 grass=mix(vec3(.105,.205,.115),vec3(.29,.385,.16),n*.7+patches*.3);
 vec3 dirt=mix(vec3(.295,.22,.14),vec3(.50,.40,.265),n);
 float ruts=1.0-smoothstep(.045,.095,abs(abs(world.z-center)-1.2));
 float grit=noise(world.xz*24.0);
 vec2 stones=world.xz*4.5;
 vec2 cell=floor(stones);vec2 local=fract(stones);
 vec2 offset=vec2(hash(cell),hash(cell+vec2(53,21)))*.38+.31;
 float pebble=1.0-smoothstep(.05,.10,length((local-offset)*vec2(1.0,1.4)));
 float pebble_mask=step(.57,hash(cell+13.0))*pebble;
 dirt*=1.0-ruts*.18;
 dirt=mix(dirt,vec3(.52,.47,.35),pebble_mask*.48*fine_visibility);
 dirt*=.94+mix(.5,grit,fine_visibility)*.09;
 float tread=(1.0-smoothstep(.04,.12,abs(fract(world.x*4.0)-.5)))*ruts;
 dirt*=1.0-tread*.12*fine_visibility;
 // Contact staining around the keep and rampart feet anchors them to the valley.
 float castle_foot=(1.0-smoothstep(-3.2,-2.4,world.x))*(1.0-smoothstep(5.1,6.4,abs(world.z)));
 grass=mix(grass,vec3(.18,.245,.115),castle_foot*.4);
 ALBEDO=mix(grass,dirt,road);
 AO=1.0-castle_foot*.18;
 ROUGHNESS=.97;
}
