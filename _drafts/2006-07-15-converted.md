---
title: "キューブマッピングで FBO を使ってみる"
date: 2006-07-15
categories: [OpenGL,テクスチャ]
published: true
---

## 旅費が出た！

以前，[お金が無い！]({{ site.baseurl }}{% post_url 2006-05-02-post %})と嘆いていたのですが，関係各位？のご尽力により，国際会議の旅費に加えて参加費まで大学（への寄付金）から出してもらえることになりました！助かりました．今後は大学の乏しい資金に頼らず，自分で外部資金等を取得するよう努力したいと思います．本当にありがとうございました．

## Framebuffer Object (FBO) を使ってみる

その国際会議も目前に迫ってきているんですが，それがストレスになっているのか，精神的にはあまり安定していません．そういう時はプログラミングに逃避するというものひとつの手なので，以前から試してみなくちゃと思いつつほったらかしにしていた Framebuffer Object (FBO) を試してみました．FBO はフレームバッファを構成する要素の集合体であり，テクスチャやレンダーバッファをカラーバッファや Z バッファとして用いて，それらを組み合わせて構成します．
以前に書いた[レンダリング画像をテクスチャに使う]({{ site.baseurl }}{% post_url 2005-09-23-post %})方法では，ダブルバッファのバックバッファにレンダリングした画像を glTexCopySubImage() を使ってテクスチャにコピーする手法を使っていました．今回はこれを雛形にして，FBO を使って直接テクスチャにレンダリングするように変更してみます．

<ul>
<li>[Linux 版](texture/texture22.tar.gz)</li>
<li>[Windows 版](texture/texture22.lzh)</li>
</ul>

## まず，これに FBO に使う関数の宣言を追加します．ただし，上の雛形の Windows 版に含まれている `glext`.h はバージョンが古く，FBO に関する宣言が含まれていません．最新の <%= a "`glext`.h" %> は [OpenGL® Extension Registry](http://www.opengl.org/registry/) から入手できますので，それと差し替えてください．なお，OpenGL® Extension Registry は最近 <%= a "SGI" %> から <%= a "OpenGL.org" %> に移管されたようです．

```c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#if defined(WIN32)
//#  pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#  include "glut.h"
#  include "glext.h"
PFNGLGENFRAMEBUFFERSEXTPROC glGenFramebuffersEXT;
PFNGLBINDFRAMEBUFFEREXTPROC glBindFramebufferEXT;
PFNGLFRAMEBUFFERTEXTURE2DEXTPROC glFramebufferTexture2DEXT;
PFNGLGENRENDERBUFFERSEXTPROC glGenRenderbuffersEXT;
PFNGLBINDRENDERBUFFEREXTPROC glBindRenderbufferEXT;
PFNGLRENDERBUFFERSTORAGEEXTPROC glRenderbufferStorageEXT;
PFNGLFRAMEBUFFERRENDERBUFFEREXTPROC glFramebufferRenderbufferEXT;
PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC glCheckFramebufferStatusEXT;
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  define GL_GLEXT_PROTOTYPES
#  include <GL/glut.h>
#endif
```

## テクスチャオブジェクトとフレームバッファオブジェクト，およびレンダーバッファの識別子に使う変数を用意しておきます．

```c
...

/*
** ウィンドウサイズ
*/
static GLsizei width, height;

/*
** テクスチャオブジェクト・フレームバッファオブジェクト
*/
static GLuint tex, fb, rb;
```

## Windows では，FBO に使う API のエントリポイントを確保しておきます．例によって今回も FBO が使えるという前提でプログラムを書いているので，もし FBO が使えない環境で実行した場合にはエラーとなってしまいますので注意してください．このあたりのことをもっと楽にやりたければ，[GLEW](http://glew.sourceforge.net/) の導入を検討してください．

```c
/*
** 初期化
*/
static void init(void)
{
int i;

#if defined(WIN32)
glGenFramebuffersEXT =
(PFNGLGENFRAMEBUFFERSEXTPROC)wglGetProcAddress("glGenFramebuffersEXT");
glBindFramebufferEXT =
(PFNGLBINDFRAMEBUFFEREXTPROC)wglGetProcAddress("glBindFramebufferEXT");
glFramebufferTexture2DEXT =
(PFNGLFRAMEBUFFERTEXTURE2DEXTPROC)wglGetProcAddress("glFramebufferTexture2DEXT");
glGenRenderbuffersEXT =
(PFNGLGENRENDERBUFFERSEXTPROC)wglGetProcAddress("glGenRenderbuffersEXT");
glBindRenderbufferEXT =
(PFNGLBINDRENDERBUFFEREXTPROC)wglGetProcAddress("glBindRenderbufferEXT");
glRenderbufferStorageEXT =
(PFNGLRENDERBUFFERSTORAGEEXTPROC)wglGetProcAddress("glRenderbufferStorageEXT");
glFramebufferRenderbufferEXT =
(PFNGLFRAMEBUFFERRENDERBUFFEREXTPROC)wglGetProcAddress("glFramebufferRenderbufferEXT");
glCheckFramebufferStatusEXT =
(PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC)wglGetProcAddress("glCheckFramebufferStatusEXT");
#endif
```

## テクスチャオブジェクトを生成し，それを現在のテクスチャに結合しておきます．

```c
/* テクスチャオブジェクトを生成して結合する */
glGenTextures(1, &tex);
glBindTexture(GL_TEXTURE_CUBE_MAP, tex);

for (i = 0; i < 6; ++i) {

/* テクスチャの割り当て */
glTexImage2D(target[i].name, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, 0);
}
```

## キューブマッピングのテクスチャの設定が済んだところで，デフォルトのテクスチャオブジェクトに戻しておきます．

```c
...
/* キューブマッピング用のテクスチャ座標を生成する */
glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);

/* テクスチャオブジェクトの結合を解除する */
glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
```

## フレームバッファオブジェクトとレンダーバッファ

次に，フレームバッファオブジェクトとレンダーバッファの生成を行います．これらの生成はテクスチャオブジェクトと同じような感じです．テクスチャを（後で [`glFramebufferTexture2DEXT()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glFramebufferTexture2DEXT.xhtml) を使って）フレームバッファオブジェクトに結びつけることによって，直接テクスチャにレンダリングできるようになります．一方，レンダーバッファはテクスチャとしては使えませんが，隠面消去を行うなら Z バッファが必要になるので，[`glRenderbufferStorageEXT()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glRenderbufferStorageEXT.xhtml) を使ってデプスバッファ用のレンダーバッファを確保して，[`glFramebufferRenderbufferEXT()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glFramebufferRenderbufferEXT.xhtml) でフレームバッファオブジェクトに結び付けておきます．

```c
/* フレームバッファオブジェクトを生成して結合する */
glGenFramebuffersEXT(1, &fb);
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb);

/* フレームバッファオブジェクトにテクスチャオブジェクトを結合する */

glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
target[0].name, tex, 0);

/* フレームバッファオブジェクトの結合を解除する */

glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

/* レンダーバッファを生成して結合する */

glGenRenderbuffersEXT(1, &rb);
glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, rb);
glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT,
TEXWIDTH, TEXHEIGHT);

/* フレームバッファオブジェクトにレンダーバッファを結合する */

glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
GL_RENDERBUFFER_EXT, rb);

/* レンダーバッファの結合を解除する */

glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0);

/* 初期設定 */

glClearColor(0.3, 0.3, 1.0, 1.0);
glEnable(GL_DEPTH_TEST);
glDisable(GL_CULL_FACE);
```

## キューブマッピングする図形を描画する際には，キューブマッピングのテクスチャオブジェクトを結合しておきます．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
static const GLfloat color[] = { 1.0, 1.0, 1.0, 1.0 };  /* 材質 (色) */

/* 星の描画 */

glCallList(stars);

/* 材質の設定 */

glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, color);

/* キューブマッピングのテクスチャオブジェクトを結合する */
glBindTexture(GL_TEXTURE_CUBE_MAP, tex);

/* テクスチャマッピング開始 */

glEnable(GL_TEXTURE_CUBE_MAP);

/* テクスチャ座標の自動生成を有効にする */

glEnable(GL_TEXTURE_GEN_S);
glEnable(GL_TEXTURE_GEN_T);
glEnable(GL_TEXTURE_GEN_R);

#if 1

/* ティーポットを描く */
glutSolidTeapot(1.8);
#else
/* 球を描く */
glutSolidSphere(1.5, 32, 16);
#endif

/* テクスチャ座標の自動生成を無効にする */

glDisable(GL_TEXTURE_GEN_S);
glDisable(GL_TEXTURE_GEN_T);
glDisable(GL_TEXTURE_GEN_R);

/* テクスチャマッピング終了 */

glDisable(GL_TEXTURE_CUBE_MAP);

/* キューブマッピングのテクスチャオブジェクトの結合を解除する */
glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
}
```

## バックバッファへのレンダリングは行わないので，最初の画面クリアは無効にしておきます．#if 0 〜 #`endif` の間の行は削除して構いません．その代わり，テクスチャのレンダリングを行う際にフレームバッファオブジェクトを結合しておきます．そして，[`glFramebufferTexture2DEXT()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glFramebufferTexture2DEXT.xhtml) を使ってレンダリング先のテクスチャ（キューブマッピングの場合は６枚のうちの１枚）を指定し，ビューポートの設定や画面クリアを行った後，テクスチャのレンダリングを行います．

また FBO ではテクスチャに直接レンダリングするので，レンダリング結果のテクスチャメモリへのコピーは不要になります．これも #if 0 〜 #`endif` ではさんで無効にするか，削除してしまいます．
最後に，FBO へのレンダリングを解除して，通常のフレームバッファへのレンダリングに戻します．

```c
...

static void display(void)

{
#if 0
/* 画面クリア */
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
#endif

/* 透視変換行列の設定 */

glMatrixMode(GL_PROJECTION);
glLoadIdentity();
gluPerspective(90.0, (double)TEXWIDTH / (double)TEXHEIGHT, 1.0, 10.0);

/* モデルビュー変換行列の設定 */

glMatrixMode(GL_MODELVIEW);
glLoadIdentity();

/* フレームバッファオブジェクトへのレンダリング開始 */
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb);

/* テクスチャの作成 */

for (int i = 0; i #if 0
/* ビューポートをテクスチャのサイズに設定する */
glViewport(target[i].x, target[i].y, TEXWIDTH, TEXHEIGHT);
#endif

  /* レンダリング先のテクスチャを指定する */
  glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
target[i].name, tex, 0);

/* ビューポートをテクスチャのサイズに設定する */

glViewport(0, 0, TEXWIDTH, TEXHEIGHT);

/* 画面クリア */

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

/* 視線の方向を設定して，その向きに見えるものをレンダリング */

glPushMatrix();
gluLookAt(0.0, 0.0, 0.0,
target[i].cx, target[i].cy, target[i].cz,
target[i].ux, target[i].uy, target[i].uz);
glLightfv(GL_LIGHT0, GL_POSITION, lightpos);
glMultMatrixd(trackballRotation());
glCallList(stars);
glPopMatrix();

#if 0
/* レンダリングした結果をテクスチャメモリに移す */
glCopyTexSubImage2D(target[i].name, 0, 0, 0,
target[i].x, target[i].y, TEXWIDTH, TEXHEIGHT);
#endif
}

/* フレームバッファオブジェクトへのレンダリング終了 */
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

/* テクスチャ変換行列の設定 */

glMatrixMode(GL_TEXTURE);
glLoadIdentity();
glScaled(-1.0, -1.0, 1.0);
```

## 任意のサイズのテクスチャを使う

FBO ではテクスチャのサイズが開いたウィンドウのサイズに制限されないので，テクスチャの大きさはシステムの制限の範囲内で自由に設定できます．試しに，大きなテクスチャを使ってみます．

```c
...

/*
** テクスチャ
*/
#define TEXWIDTH  1024                      /* テクスチャの幅　　　　　 */
#define TEXHEIGHT 1024                      /* テクスチャの高さ　　　　 */
```

## テクスチャのサイズに合わせてウィンドウのサイズを制限する必要もなくなりますので，その部分を無効にします．

```c
...

static void resize(int w, int h)

{
#if 0
/* ウィンドウサイズの縮小を制限する */
if (w < TEXWIDTH * 4 || h < TEXHEIGHT * 3) {
if (w < TEXWIDTH * 4) w = TEXWIDTH * 4;
if (h < TEXHEIGHT * 3) h = TEXHEIGHT * 3;
glutReshapeWindow(w, h);
}
#endif

/* ウィンドウサイズの保存 */

width = w;
height = h;

/* トラックボールする範囲 */

trackballRegion(w, h);
}
```

## ウィンドウサイズの初期値も設定しないようにしておきます．

```c
...

/*
** メインプログラム
*/
int main(int argc, char *argv[])
{
glutInit(&argc, argv);
#if 0
glutInitWindowSize(TEXWIDTH * 4, TEXWIDTH * 3);
#endif
glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);
glutCreateWindow(argv[0]);
glutDisplayFunc(display);
glutReshapeFunc(resize);
glutMouseFunc(mouse);
glutMotionFunc(motion);
glutKeyboardFunc(keyboard);
init();
glutMainLoop();
return 0;
```

<ul>
<li>[Linux 版](texture/fbo0.tar.gz)</li>
<li>[Windows 版](texture/fbo0.lzh)</li>
</ul>

## パフォーマンスは向上するか

テクスチャのコピーを行わない分，パフォーマンスは上がるはずですが，このデモではそういう比較はできないので，確かめられません．でも，少なくともテクスチャのサイズに制限がなくなるのはうれしいですね．[前のもの]({{ site.baseurl }}{% post_url 2005-09-23-post %})はかなりテクスチャが粗かったですから．そのうち[シャドウマッピング]({{ site.baseurl }}{% post_url 2006-06-01-post %}) でも試してみようと思います．
