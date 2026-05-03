---
title: "とっても簡単なマルチテクスチャのサンプル"
date: 2004-02-12
categories: [OpenGL,テクスチャ]
published: true
---

## 拡張機能を使う

Windows 上でマルチテクスチャを使う方法を質問されたので，[OpenGL FAQ の Q23](http://www.opengl.org/resources/faq/technical/extensions.htm) を見ながら，とりあえず[サンプルプログラム](https://github.com/tokoik/multitexture)を作ってみました．うーん，修行が足りんなぁ（恥）．それにしても，GeForce 4600 に同梱されていたドライバでマルチテクスチャ（の一部の機能）が使えんとは思わなんだ．うーん，修行が足りん．

## `wglGetProcAddress()`

マルチテクスチャなどの OpenGL の拡張機能は，Linux の Mesa や Mac OS X だと何も気にせずに使えていた気がしてました．でも Windows では，[`wglGetProcAddress()`](https://learn.microsoft.com/ja-jp/windows/win32/api/wingdi/nf-wingdi-wglgetprocaddress) を使って API のエントリポイント引っぱってこないといけないんですね．そのために，まず [OpenGL SDK](https://www.opengl.org/sdk/) に含まれる [glext.h](https://registry.khronos.org/OpenGL/api/GL/glext.h) を持ってきて `#include` します．

```c
#if defined(__APPLE__) || defined(MACOSX)
#  define GL_SILENCE_DEPRECATION
#  include <GLUT/glut.h>
#  include <OpenGL/glext.h>
#else
#  if defined(_WIN32)
//#    pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#    define _USE_MATH_DEFINES
#    define _CRT_SECURE_NO_WARNINGS
#  endif
#  include <GL/glut.h>
#  include <GL/glext.h>
```

そして使用する拡張機能の API，例えば `glActiveTextureARB()` や `glMultiTexCoord2fARB()` などの関数ポインタを用意し，それぞれに [`wglGetProcAddress()`](https://learn.microsoft.com/ja-jp/windows/win32/api/wingdi/nf-wingdi-wglgetprocaddress) を使って API のエントリポイントを格納してやります．このとき `wglGetProcAddress()` の戻り値が `NULL` なら，その拡張機能がサポートされていないことになります．

```c
#  if defined(_WIN32)

/*
** GL_ARB_multitexture 用の関数ポインタ
*/
PFNGLACTIVETEXTUREARBPROC glActiveTextureARB;
PFNGLMULTITEXCOORD2FARBPROC glMultiTexCoord2fARB;

/*
** GL_ARB_multitexture 用の関数ポインタを取り出す
*/
int initMultiTexture(void) {
  glActiveTextureARB = (PFNGLACTIVETEXTUREARBPROC)wglGetProcAddress("glActiveTextureARB");
  if (!glActiveTextureARB) return 0;

  glMultiTexCoord2fARB = (PFNGLMULTITEXCOORD2FARBPROC)wglGetProcAddress("glMultiTexCoord2fARB");
  if (!glMultiTexCoord2fARB) return 0;

  return 1;
}

#  else
#    define glActiveTextureARB glActiveTexture
#    define glMultiTexCoord2fARB glMultiTexCoord2f
#  endif
#endif
```

Windows の場合は，これを OpenGL の初期化処理 `init()` の時点で実行しておく必要があります．それで，めでたく API がサポートされていれば，これらの拡張機能を使います．

```c
void init(void) {
  FILE* fp;
  static unsigned char texImage[TEXWIDTH * TEXHEIGHT][3];

...

#ifdef _WIN32
  /* GL_ARB_multitexture 用の関数ポインタの初期化 */
  if (!initMultiTexture()) {
    fprintf(stderr, "GL_ARB_multitexture が使用できません\n");
    exit(1);
  }
#endif
}
```

マルチテクスチャの使い方は通常のテクスチャマッピングとあんまり変わりませんが，`glBindTexture()` でテクスチャを指定する前に，`glActiveTextureARB()` を使ってそのテクスチャを割り当てるテクスチャユニットを指定しておきます．また，テクスチャ座標の指定には glTexCoord*() の代わりに glMultiTexCoord*ARB() を用いて，テクスチャ座標とともにテクスチャユニットも指定します．

```c
/* テクスチャネーム */
static GLuint texName0, texName1;

void display(void) {
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  glLoadIdentity();
  gluLookAt(2.0, 3.0, 4.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);

  /* テクスチャ０をアクティブにする */
  glActiveTextureARB(GL_TEXTURE0_ARB);
  glBindTexture(GL_TEXTURE_2D, texName0);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
  glEnable(GL_TEXTURE_2D);

  /* テクスチャ１をアクティブにする */
  glActiveTextureARB(GL_TEXTURE1_ARB);
  glBindTexture(GL_TEXTURE_2D, texName1);
  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  glEnable(GL_TEXTURE_2D);

  /* オブジェクトの描画 */
  glNormal3d(0.0, 0.0, 1.0);
  glBegin(GL_QUADS);
  glMultiTexCoord2fARB(GL_TEXTURE0_ARB, 0.0, 1.0);
  glMultiTexCoord2fARB(GL_TEXTURE1_ARB, 0.0, 1.0);
  glVertex3d(-1.0, -1.0, 0.0);
  glMultiTexCoord2fARB(GL_TEXTURE0_ARB, 1.0, 1.0);
  glMultiTexCoord2fARB(GL_TEXTURE1_ARB, 1.0, 1.0);
  glVertex3d(1.0, -1.0, 0.0);
  glMultiTexCoord2fARB(GL_TEXTURE0_ARB, 1.0, 0.0);
  glMultiTexCoord2fARB(GL_TEXTURE1_ARB, 1.0, 0.0);
  glVertex3d(1.0, 1.0, 0.0);
  glMultiTexCoord2fARB(GL_TEXTURE0_ARB, 0.0, 0.0);
  glMultiTexCoord2fARB(GL_TEXTURE1_ARB, 0.0, 0.0);
  glVertex3d(-1.0, 1.0, 0.0);
  glEnd();

  /* テクスチャ１を結合解除する */
  glDisable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, 0);

  /* テクスチャ０を結合解除する */
  glActiveTextureARB(GL_TEXTURE0_ARB);
  glDisable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, 0);

  glFlush();
}
```

- [マルチテクスチャのサンプル](https://github.com/tokoik/multitexture)

## GLH, GLEW, Glad, GLee, ExtGL

多分，[nvsdk](http://developer.nvidia.com/object/nvsdk_home.html) なんかに入っている GLH (platform-indepenedent C++ OpenGL helper library) ってのを使うのがスジなんでしょうね．拡張機能の利用をサポートするライブラリには，この他に [GLEW](http://glew.sourceforge.net/), [Glad](https://glad.dav1d.de/), [GLee](http://elf-stone.com/glee.php), [ExtGL](http://www.levp.de/3d/index.html)（これは開発をやめてしまったらしい）などがあるようです．Windows で OpenGL の拡張機能を使うときに悩む人は結構いるんでしょうか．

> この記事の内容は {{ page.date | date: "%Y 年 %m 月" }}のものです。マルチテクスチャは 2001 年 8 月にリリースされた OpenGL 1.3 から標準機能 (Core Features) になっています．また GLH は，かつて NVSDK (旧 NVIDIA SDK) に含まれていた，プラットフォームに依存しない C++ OpenGL ヘルパーライブラリ (glh_extensions.h など) です．これは古い NVIDIA のサンプルコードやツールで使用されていましたが，2026 年時点では使われなくなっています (見つけられませんでした)．
