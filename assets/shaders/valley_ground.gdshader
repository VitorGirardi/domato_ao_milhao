shader_type spatial;
render_mode specular_disabled;
uniform vec4 meadow_dark:source_color=vec4(0.39,0.51,0.25,1.0);
uniform vec4 meadow_light:source_color=vec4(0.57,0.65,0.34,1.0);
uniform vec4 earth:source_color=vec4(0.64,0.49,0.31,1.0);
uniform vec4 bank:source_color=vec4(0.56,0.55,0.38,1.0);
uniform int trail_count=0;
uniform vec4 trails[64];
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec2 p=world_pos.xz;
 float broad=noise(p*.075)*.65+noise(p*.23)*.35;
 float small=noise(p*3.7);
 vec3 grass=mix(meadow_dark.rgb,meadow_light.rgb,smoothstep(.12,.88,broad));
 grass*=.96+small*.08;
 float trunk=-27.0+sin(p.y*.07)*smoothstep(42.0,66.0,abs(p.y))*3.0;
 float lane=30.0+sin(p.x*.09)*smoothstep(44.0,75.0,p.x)*3.0;
 float d1=abs(p.x-trunk),d2=abs(p.y-lane);
 float d=min(d1,d2);
 for(int i=0;i<trail_count;i++){
  vec2 a=trails[i].xy,b=trails[i].zw,ab=b-a;
  float t=clamp(dot(p-a,ab)/dot(ab,ab),0.0,1.0);
  d=min(d,length(p-a-ab*t));
 }
 float edge=noise(p*1.8)*.23+noise(p*.4)*.35;
 float road=(1.0-smoothstep(1.5+edge,2.35+edge,d));
 float tracks=exp(-pow((d-.88)*5.0,2.0));
 float verge=noise(p*2.7)*.16;
 vec3 dirt=earth.rgb*(.91+noise(p*6.0)*.12-tracks*.12);
 // Thin grass between worn wheel tracks, with broken earthy edges.
 dirt=mix(dirt,grass,(1.0-smoothstep(.12,.48,d))*(.12+verge));
 vec3 col=mix(grass,dirt,road);
 float river_x=-42.0+sin(p.y*.065)*2.6;
 float shore=1.0-smoothstep(3.1,5.4+noise(p*.7)*.8,abs(p.x-river_x));
 col=mix(col,bank.rgb*(.9+small*.17),shore);
 ALBEDO=col*.73;ROUGHNESS=1.0;
}
