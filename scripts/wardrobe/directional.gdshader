shader_type canvas_item;
uniform int component = 0; // body=0, front hair=1, rear hair=2, headwear=3
uniform int direction = 0;
uniform vec4 head_rect;
uniform float hat_seat = -999.0;
uniform bool hood = false;
uniform bool dye_enabled = false;
uniform int palette = 0; // blue/purple, red, dark-neutral, ivory
uniform vec4 dye: source_color = vec4(.25,.36,.59,1.0);
varying vec2 p;
varying vec4 tint;
void vertex(){p=VERTEX;tint=COLOR;}
void fragment(){
 vec4 c=texture(TEXTURE,UV);
 float cx=head_rect.x+head_rect.z*.5;
 float eye=head_rect.y+head_rect.w*.48;
 bool face_zone=p.y>eye && p.y<head_rect.y+head_rect.w*1.08;
 bool front_face=(direction==0 && abs(p.x-cx)<head_rect.z*.36) || (direction==2 && p.x<cx+head_rect.z*.06) || (direction==3 && p.x>cx-head_rect.z*.06);
 if(component==1 || component==2){
  if(p.y<hat_seat)c.a=0.0;
  if(component==1 && direction!=1 && face_zone && front_face)c.a=0.0;
  if(component==1 && p.y>head_rect.y+head_rect.w*1.10)c.a=0.0;
 }
 if(component==3 && hood && direction!=1 && face_zone && front_face)c.a=0.0;
 if(dye_enabled && p.y>head_rect.y+head_rect.w*.98 && p.y< -3.5){
  float hi=max(c.r,max(c.g,c.b));float lo=min(c.r,min(c.g,c.b));
  bool cloth=(palette==0 && c.b>c.r*.90 && c.b>c.g*.90 && hi-lo>.065) || (palette==1 && c.r>c.g*1.4 && c.r>c.b*1.4 && abs(c.g-c.b)<.10) || (palette==2 && hi-lo<.13 && hi<.65 && hi>.08) || (palette==3 && hi-lo<.18 && hi>.25);
  if(cloth){float light=dot(c.rgb,vec3(.2126,.7152,.0722));c.rgb=mix(dye.rgb*.22,dye.rgb*1.25,clamp(light*1.5,0.0,1.0));}
 }
 COLOR=tint*vec4(c.rgb,c.a*smoothstep(.35,.70,c.a));
}
