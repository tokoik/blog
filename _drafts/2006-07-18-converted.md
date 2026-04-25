---
title: "シャドウマッピングで FBO を使ってみる"
date: 2006-07-18
categories: [OpenGL,テクスチャ]
published: true
---

## がんばれなんて言えない

気分が落ち込んでいるときは人と関わることが特に億劫になっているので，研究室の学生さん達との関係も疎遠になったりしてしまいます（代わりにこのブログなどで情報提供しているわけですが）．それでも彼らは自分達で何か進めているようです．けなげです．だから，彼らに多少進捗状況が遅いからといって「がんばれ」なんて無責任なことは言えません．だいたい，自分自身が「がんばれ」と言われることで煮詰まってしまうし．

## シャドウマッピングと Frame Buffer Object (FBO)

シャドウマッピングでは，デプスバッファをテクスチャとして参照して影の領域の判定を行いますから，デプスバッファの内容をテクスチャメモリに転送する必要があります．FBO を使えば直接テクスチャメモリにレンダリングできますから，この転送を省くことができます．
それでは以前に書いた[GLSL によるシャドウマッピング]({{ site.baseurl }}{% post_url 2006-06-01-post %})のプログラムを雛形にして，これを FBO を使うように変更してみたいと思います．

<ul>
<li>[Linux 版](`glsl`/glsl9.tar.gz)</li>
<li>[Windows 版](`glsl`/glsl9.lzh)</li>
</ul>

## まず[前回]({{ site.baseurl }}{% post_url 2006-07-15-post %})と同様，これに FBO に使う関数の宣言を追加します．この雛形の Windows 版に含まれている `glext`.h もバージョンが古く，FBO に関する宣言が含まれていませんので，最新の <%= a "`glext`.h" %> 入手して差し替えてください．

```c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#if defined(WIN32)
//#  pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#  include "glut.h"
#  include "glext.h"
PFNGLMULTTRANSPOSEMATRIXDPROC glMultTransposeMatrixd;
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
#include "glsl.h"
```

## テクスチャオブジェクトとフレームバッファオブジェクトの識別子に使う変数を用意しておきます．

```c
...

/*
** テクスチャ
*/
#define TEXWIDTH  512                                     /* テクスチャの幅　　 */
#define TEXHEIGHT 512                                     /* テクスチャの高さ　 */

/*
** テクスチャオブジェクト・フレームバッファオブジェクト
*/
```

## Windows では，FBO に使う API のエントリポイントを確保しておきます．今回も FBO が使えるという前提でプログラムを書いているので，もし FBO が使えない環境で実行した場合にはエラーとなってしまいますので注意してください．

```c
/*
** 初期化
*/
static void init(void)
{
/* シェーダプログラムのコンパイル／リンク結果を得る変数 */
GLint compiled, linked;

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
```

## テクスチャオブジェクトを生成し，それを現在のテクスチャに結合しておきます．

```c
/* テクスチャオブジェクトを生成して結合する */
glGenTextures(1, &tex);
glBindTexture(GL_TEXTURE_2D, tex);

/* テクスチャの割り当て */

glTexImage2D(GL_TEXTURE_2D, 0, GL_DEPTH_COMPONENT, TEXWIDTH, TEXHEIGHT, 0,
GL_DEPTH_COMPONENT, GL_UNSIGNED_BYTE, 0);
```

## テクスチャの設定が済んだところで，デフォルトのテクスチャオブジェクトに戻しておきます．

```c
/* 比較の結果を輝度値として得る */
glTexParameteri(GL_TEXTURE_2D, GL_DEPTH_TEXTURE_MODE, GL_LUMINANCE);

#if 0

/* テクスチャ座標に視点座標系における物体の座標値を用いる */
glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);
glTexGeni(GL_Q, GL_TEXTURE_GEN_MODE, GL_EYE_LINEAR);

/* 生成したテクスチャ座標をそのまま (S, T, R, Q) に使う */

static const GLdouble genfunc[][4] = {
{ 1.0, 0.0, 0.0, 0.0 },
{ 0.0, 1.0, 0.0, 0.0 },
{ 0.0, 0.0, 1.0, 0.0 },
{ 0.0, 0.0, 0.0, 1.0 },
};
glTexGendv(GL_S, GL_EYE_PLANE, genfunc[0]);
glTexGendv(GL_T, GL_EYE_PLANE, genfunc[1]);
glTexGendv(GL_R, GL_EYE_PLANE, genfunc[2]);
glTexGendv(GL_Q, GL_EYE_PLANE, genfunc[3]);
#endif

/* テクスチャオブジェクトの結合を解除する */
```

## フレームバッファオブジェクトの生成

次に，フレームバッファオブジェクトを生成します．今回はカラーバッファを用意しないので，カラーバッファを読み書きしないようにしておきます．

```c
/* フレームバッファオブジェクトを生成して結合する */
glGenFramebuffersEXT(1, &fb);
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb);

/* フレームバッファオブジェクトにデプスバッファ用のテクスチャを結合する */

glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT,
GL_TEXTURE_2D, tex, 0);

/* カラーバッファは無いので読み書きしない */

glDrawBuffer(GL_NONE);
glReadBuffer(GL_NONE);

/* フレームバッファオブジェクトの結合を解除する */

glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

/* 初期設定 */

glClearColor(0.3, 0.3, 1.0, 1.0);
glEnable(GL_DEPTH_TEST);
glEnable(GL_CULL_FACE);
```

## 光源側から見てレンダリングする際に，FBO へのレンダリングを有効にします．

```c
...

static void display(void)

{
GLint viewport[4];       /* ビューポートの保存用　　　　 */
GLdouble modelview[16];  /* モデルビュー変換行列の保存用 */
GLdouble projection[16]; /* 透視変換行列の保存用　　　　 */
static int frame = 0;    /* フレーム数のカウント　　　　 */
double t = (double)frame / (double)FRAMES; /* 経過時間　 */

if (++frame >= FRAMES) frame = 0;

/*
** 第１ステップ：デプステクスチャの作成
*/

/* フレームバッファオブジェクトへのレンダリング開始 */
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb);

/* デプスバッファをクリアする */

glClear(GL_DEPTH_BUFFER_BIT);
```

## 光源側から見たシーンの描画が終わったら，FBO へのレンダリングを解除します．またデプスバッファの内容をテクスチャメモリに転送する必要はないので，この部分を #if 0 〜 #`endif` ではさんで無効にするか，削除します．

 

```c
...

/* シーンを描画する */

scene(t);

/* フレームバッファオブジェクトへのレンダリング終了 */
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

#if 0
/* デプスバッファの内容をテクスチャメモリに転送する */
glCopyTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 0, 0, TEXWIDTH, TEXHEIGHT);
#endif

/* 通常の描画の設定に戻す */

glViewport(viewport[0], viewport[1], viewport[2], viewport[3]);
glMatrixMode(GL_PROJECTION);
glLoadMatrixd(projection);
glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
glEnable(GL_LIGHTING);
glCullFace(GL_BACK);
```

## テクスチャマッピングを有効にする際に，テクスチャオブジェクトを結合しておきます．

```c
...

/* モデルビュー変換行列に戻す */

glMatrixMode(GL_MODELVIEW);

/* テクスチャオブジェクトを結合する */
glBindTexture(GL_TEXTURE_2D, tex);

/* テクスチャマッピングとテクスチャ座標の自動生成を有効にする */

glEnable(GL_TEXTURE_2D);
```

## 視点から見たシーンの描画が済み，テクスチャマッピングを無効にしたら，テクスチャオブジェクトの結合を解除しておきます．

```c
...
glDisable(GL_TEXTURE_2D);

/* テクスチャオブジェクトの結合を解除する */
glBindTexture(GL_TEXTURE_2D, 0);

/* ダブルバッファリング */

glutSwapBuffers();
}
```

## この場合もテクスチャのサイズでウインドウのサイズを制限する必要はなくなるので，その部分を無効にしておきます．

```c
...

static void resize(int w, int h)

{
#if 0
/* ウィンドウサイズの縮小を制限する */
if (w < TEXWIDTH || h < TEXHEIGHT) {
if (w < TEXWIDTH) w = TEXWIDTH;
if (h < TEXHEIGHT) h = TEXHEIGHT;
glutReshapeWindow(w, h);
}
#endif

/* トラックボールする範囲 */

trackballRegion(w, h);
```

## 初期ウィンドウサイズもデフォルトに戻しておきます．

```c
...

/*
** メインプログラム
*/
int main(int argc, char *argv[])
{
glutInit(&argc, argv);
#if 0
glutInitWindowSize(TEXWIDTH, TEXHEIGHT);
#endif
glutInitDisplayMode(GLUT_RGBA | GLUT_DEPTH | GLUT_DOUBLE);
```

<ul>
<li>[Linux 版](texture/fbo1.tar.gz)</li>
<li>[Windows 版](texture/fbo1.lzh)</li>
</ul>

## パフォーマンスについて

正確な測定は行っていませんが，このプログラムの場合は，パフォーマンスはだいぶ向上した気がします．

## 2008年12月4日追記

ATI のビデオカードのドライバを更新したら，影が逆回りするようになってしまいました（nVIDIA のビデオカードでは問題ありません）．どうも，デプステクスチャが上下反転して読み込まれているようです．原因がわからず，いろいろ試した結果，<%= a "http://alb.hp.infoseek.co.jp/opengl_fbo.html" %> にカラーバッファに描き込まないようにすればカラーバッファを用意する必要は無い（エラーにならない）と書かれていたので，そのように書き換えたら直りました．関連がわからん…
