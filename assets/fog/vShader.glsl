// https://github.com/gideros/gideros/blob/master/2dsg/gfxbackends/gl2/gl2ShaderEngine.cpp
// 
attribute highp vec3 vVertex;
attribute mediump vec2 vTexCoord;
attribute lowp vec4 vColor;

uniform highp mat4 vMatrix;
uniform lowp vec4 fColor;

varying mediump vec2 fTexCoord;
varying lowp vec4 fInColor;
varying float fAbsoluteZ;
varying float fTransformedZ;

void main() {
  vec4 vertex = vec4(vVertex, 1.0);
  gl_Position = vMatrix * vertex;
  fTexCoord = vTexCoord;
  fInColor = vColor * fColor;
  fAbsoluteZ = vertex.z;
  fTransformedZ = gl_Position.z;
}
