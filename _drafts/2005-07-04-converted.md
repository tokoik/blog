---
title: "第２３回 放物面マッピングと他のテクスチャとの合成"
date: 2005-07-04
categories: [OpenGL,テクスチャ]
published: true
---

## 環境のテクスチャを最下層に置いたとき

[放物面マッピング]({% post_url 2005-06-24-post %})では映り込みのテクスチャを不透明にする必要があったので，そのテクスチャを最下層に置きました．今回は，そのテクスチャと，その上に重ねたテクスチャとの合成を行ってみます．

## テクスチャユニットを指定したテクスチャ座標の設定

[前回]({% post_url 2005-06-24-post %})作成したプログラムでは，もともとあったテクスチャを，テクスチャユニット２ (`GL_TEXTURE2`) に割り当てています．ただし，このテクスチャは，実際には使用していませんでした．

<ul>
<li>[Linux 版](texture/texture18.tar.gz)</li>
<li>[Mac OS X 版](texture/texture18.zip)</li>
<li>[Windows 版](texture/texture18.lzh)</li>
</ul>

## また，`box`.cpp で定義している立方体を描く関数 `box`() では，glTexCoord2dv() を使って各面に貼るテクスチャのテクスチャ座標を設定しています．この関数はデフォルトのテクスチャユニット，すなわちテクスチャユニット０ (`GL_TEXTURE0`) に対してテクスチャ座標を設定することができますが，テクスチャユニット２に割り当てたテクスチャに対してテクスチャ座標を設定することはできません．

## [`glMultiTexCoord2dv()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glMultiTexCoord2dv.xhtml)

特定のテクスチャユニットに対してテクスチャ座標を設定するには，glMultiTexCoord*() という関数群を使います．この関数も Windows の gl.h では宣言されていないので，Windows でこの関数を使用する場合は，[`glMultiTexCoord2dv()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glMultiTexCoord2dv.xhtml) の関数ポインタ変数の宣言を main.cpp に追加する必要があります．

```c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#if defined(WIN32)
//#  pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#  include "glut.h"
#  include "glext.h"
PFNGLACTIVETEXTUREPROC glActiveTexture;
PFNGLMULTITEXCOORD2DVPROC glMultiTexCoord2dv;
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  include <GL/glut.h>
#endif
```

## そしてプログラムの初期化時に，この関数ポインタ変数に関数の実体のエントリポイントを格納しておきます．

```c
...

/* 各テクスチャユニット用にテクスチャオブジェクトを作る */

GLuint texname[3];
glGenTextures(3, texname);

#if defined(WIN32)

glActiveTexture =
(PFNGLACTIVETEXTUREPROC)wglGetProcAddress("glActiveTexture");
glMultiTexCoord2dv =
(PFNGLMULTITEXCOORD2DVPROC)wglGetProcAddress("glMultiTexCoord2dv");
#endif

/* 裏面の放物面テクスチャのマッピングに使うテクスチャユニット */

glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texname[0]);
```

## このほか，シーンを描画する際はテクスチャユニット２によるテクスチャマッピングを有効にしておきます．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
...

#if 1

/* テクスチャマッピング開始 */
glActiveTexture(GL_TEXTURE2);
glEnable(GL_TEXTURE_2D);
#endif

/* トラックボール処理による回転 */

glMultMatrixd(trackballRotation());

/* 箱を描く */

box(1.0, 1.0, 1.0);

#if 1

/* テクスチャマッピング終了 */
glDisable(GL_TEXTURE_2D);
#endif
```

## 一方 `box`.cpp も，テクスチャ座標を glTexCoord2dv() を使って設定している部分を [`glMultiTexCoord2dv()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glMultiTexCoord2dv.xhtml) に置き換えます．Windows の場合は関数ポインタ変数 glTexCoord2dv を外部変数として宣言しておいてください．

```c
#if defined(WIN32)
#  include "glut.h"
#  include "glext.h"
extern PFNGLMULTITEXCOORD2DVPROC glMultiTexCoord2dv;
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  include <GL/glut.h>
#endif

...

/* 四角形６枚で箱を描く */

glBegin(GL_QUADS);
for (j = 0; j < 6; ++j) {
glNormal3dv(normal[j]);
for (i = 0; i < 4; ++i) {
/* テクスチャ座標の指定 */
  glMultiTexCoord2dv(GL_TEXTURE2, texcoord[j][i]);
/* 対応する頂点座標の指定 */
glVertex3dv(vertex[j][i]);
}
}
glEnd();
}
```

![放物面マッピングによる映り込みの合成]({{ site.baseurl }}/assets/images/paraboloid12.jpg)

## もちろん，テクスチャ環境の `GL_MODULATE` を `GL_COMBINE` に置き換えて，線形補間によるテクスチャの合成を行うこともできます．

```c
...

/* テクスチャ環境 */

glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_COMBINE);
glTexEnvi(GL_TEXTURE_ENV, GL_COMBINE_RGB, GL_INTERPOLATE);
static const GLfloat blend[] = { 1.0, 1.0, 1.0, 0.5 };
glTexEnvfv(GL_TEXTURE_ENV, GL_TEXTURE_ENV_COLOR, blend);

/* 初期設定 */

glClearColor(0.3, 0.3, 1.0, 0.0);
glEnable(GL_DEPTH_TEST);
glDisable(GL_CULL_FACE);
```

![放物面マッピングによる映り込みの線形補間による合成]({{ site.baseurl }}/assets/images/paraboloid13.jpg)

<ul>
<li>[Linux 版](texture/texture19.tar.gz)</li>
<li>[Mac OS X 版](texture/texture19.zip)</li>
<li>[Windows 版](texture/texture19.lzh)</li>
</ul>
