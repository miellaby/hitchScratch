
fogShader=Shader.new("fog/vShader","fog/fShader",0,
{
{name="vMatrix",type=Shader.CMATRIX,sys=Shader.SYS_WVP,vertex=true},
{name="fColor",type=Shader.CFLOAT4,sys=Shader.SYS_COLOR,vertex=false},
{name="fTexture",type=Shader.CTEXTURE, vertex=false},
{name="fTexInfo",type=Shader.CFLOAT4,sys=Shader.SYS_TEXTUREINFO,vertex=false},
},
{
{name="vVertex",type=Shader.DFLOAT,mult=3,slot=0,offset=0},
{name="vColor",type=Shader.DUBYTE,mult=4,slot=1,offset=0},
{name="vTexCoord",type=Shader.DFLOAT,mult=2,slot=2,offset=0},
});

print('fogShader', fogShader:isValid())
