BlurEffect={}
-- Vertex Shader
BlurEffect.VS_GL=[[
attribute highp vec3 vVertex;
attribute mediump vec2 vTexCoord;
uniform highp mat4 vMatrix;
varying mediump vec2 fTexCoord;
 
void main() {
  vec4 vertex = vec4(vVertex,1.0);
  gl_Position = vMatrix*vertex;
  fTexCoord=vTexCoord;
}
]]
 
 -- Fragment Shader
BlurEffect.FS_GL=[[
uniform lowp vec4 fColor;
uniform lowp sampler2D fTexture;
varying mediump vec2 fTexCoord;
uniform mediump vec4 fTexSize;
 
void main() {
 mediump vec4 frag=vec4(0.0,0.0,0.0,0.0); 
 mediump vec2 centerDir=normalize((fTexSize.xy/2.0-fTexCoord)/fTexSize.xy)*fTexSize.zw;
 for (int k=0;k<=5;k++)
	frag=frag+texture2D(fTexture, fTexCoord-centerDir*float(k));
 frag=frag/6.0;
 if (frag.a<=0.0) discard;
 gl_FragColor = frag;
}
]]
 
BlurEffect.Shader=Shader.new(BlurEffect.VS_GL,BlurEffect.FS_GL,Shader.FLAG_FROM_CODE,
{
{name="vMatrix",type=Shader.CMATRIX,sys=Shader.SYS_WVP,vertex=true},
{name="fColor",type=Shader.CFLOAT4,sys=Shader.SYS_COLOR,vertex=false},
{name="fTexture",type=Shader.CTEXTURE,vertex=false},
{name="fTexSize",type=Shader.CFLOAT4,sys=Shader.SYS_TEXTUREINFO,vertex=false},
},
{
{name="vVertex",type=Shader.DFLOAT,mult=3,slot=0,offset=0},
{name="vColor",type=Shader.DUBYTE,mult=4,slot=1,offset=0},
{name="vTexCoord",type=Shader.DFLOAT,mult=2,slot=2,offset=0},
});
 
local identity=Matrix.new()
function BlurEffect.blur(spr)
	local sm=spr:getMatrix()
	spr:setMatrix(identity)
	local spx,spy,spw,sph=spr:getBounds(spr)
	if spw>=spr._blur_tgt:getWidth() or sph>=spr._blur_tgt:getHeight() then
		spr._blur_tgt=RenderTarget.new(spw,sph,true)
		local p=spr._blur_spr:getParent()
		spr._blur_spr:removeFromParent()
		spr._blur_spr:removeEventListener(Event.ENTER_FRAME,BlurEffect.blur,spr)
		spr._blur_spr=Bitmap.new(spr._blur_tgt)
		p:addChild(spr._blur_spr)
		spr._blur_spr._orig_spr=spr
		spr._blur_spr:setShader(BlurEffect.Shader)
		spr._blur_spr:addEventListener(Event.ENTER_FRAME,BlurEffect.blur,spr)
	end
	spr._blur_spr:setMatrix(sm)
    spr._blur_tgt:clear(0xFFFFFF,0)
	spr._blur_tgt:draw(spr)
	spr:setMatrix(sm)
end
 
function BlurEffect.apply(sprite)
	local spx,spy,spw,sph=sprite:getBounds(sprite)
	sprite._blur_tgt=RenderTarget.new(spw,sph,true)
	local p = sprite:getParent()
	sprite:removeFromParent()
	sprite._blur_spr=Bitmap.new(sprite._blur_tgt)
	p:addChild(sprite._blur_spr)
	sprite._blur_spr._orig_spr=sprite
	sprite._blur_spr:setShader(BlurEffect.Shader)
	sprite._blur_spr:addEventListener(Event.ENTER_FRAME,BlurEffect.blur,sprite)
	return sprite._blur_spr
end