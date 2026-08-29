#version 120
//
// tornado.vert
//
attribute vec3 point;
uniform float elapsedTime;
uniform mat4 transformMatrix;
 
void main(void)
{
  float z = fract(point.z - elapsedTime);
  float s = z * z;
  float t = z * 6.283185;
  float ct = cos(t);
  float st = sin(t);
  vec2 p = s * mat2(ct, st, -st, ct) * point.xy;
  gl_Position = transformMatrix * vec4(p, z, 1.0);
}
