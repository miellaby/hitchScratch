varying mediump vec2 fTexCoord;
varying lowp vec4 fInColor;
varying float fAbsoluteZ;
varying float fTransformedZ;
mediump vec4 fogColor = vec4(0.4, 0.8, 1, 1);

void main() {
  mediump vec4 frag=fInColor;
  mediump float fog;
  fog = fAbsoluteZ < -10.0 ? 0.0 :fAbsoluteZ > 20.0 ? 1.0 : ((fAbsoluteZ - (-10.0)) / (20 - (-10.0)));
  fog *= (1.0 - (fTransformedZ < 1500 ? 0.0 : fTransformedZ > 2000 ? 1.0 : (fTransformedZ - 1500.0) / (2000.0 - 1500.0)));
  frag = mix(fogColor, frag, fog);
  gl_FragColor = frag;
}