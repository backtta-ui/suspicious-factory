shader_type canvas_item;
uniform sampler2D cloth_mask;
uniform bool dye_enabled=false;
uniform vec4 dye:source_color=vec4(1.0);
varying vec4 tint;
void vertex(){tint=COLOR;}
void fragment(){
 vec4 native=texture(TEXTURE,UV);
 vec4 result=native;
 if(dye_enabled){
  float strength=texture(cloth_mask,UV).a;
  float brightness=max(native.r,max(native.g,native.b));
  result.rgb=mix(native.rgb,dye.rgb*clamp(brightness*1.35,.22,1.2),strength);
 }
 COLOR=tint*result;
}
