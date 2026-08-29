#version 120
//
// dropping.vert
//
attribute vec3 point;
uniform float elapsedTime;
uniform mat4 transformMatrix;
 
void main(void)
{
  float z = fract(point.z - elapsedTime);
  gl_Position = transformMatrix * vec4(point.xy, z, 1.0);
}
