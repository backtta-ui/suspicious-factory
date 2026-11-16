shader_type canvas_item;
uniform vec4 dye: source_color = vec4(0.25,0.36,0.59,1.0);
uniform bool enabled = false;
varying vec4 vertex_tint;
void vertex(){vertex_tint=COLOR;}
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 if(enabled){
  float hi=max(c.r,max(c.g,c.b));float lo=min(c.r,min(c.g,c.b));
  bool cloth=(c.b>c.r*0.9 && c.b>c.g*0.88) || (hi-lo<0.15 && hi>0.25);
  if(cloth){float light=dot(c.rgb,vec3(.2126,.7152,.0722));c.rgb=mix(dye.rgb*.3,dye.rgb*1.35,clamp(light*1.25,0.0,1.0));}
 }
 COLOR=vertex_tint*vec4(c.rgb,c.a*smoothstep(.12,.4,c.a));
}
