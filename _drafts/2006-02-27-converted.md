---
title: "Point Sprite を使ってみる"
date: 2006-02-27
categories: [OpenGL,テクスチャ]
published: true
---

## フランス人帰る

<p>[こだわりのフランス人]({% post_url 2005-12-28-post %})は，交換留学の期間を終えて，フランスに帰っていきました．外見はナイーブな感じでしたが，気さくで付き合いもよく，ほかの学生さんにはとてもいい刺激になったみたいです．彼は日本語がまったく話せない状態で日本に留学に来たわけで，そう思えば度胸のある人だったのかもしれません．ただ，そのために周りの学生さんや私も必然的に彼に合わせてコミュニケーションをとらざるを得ませんでした．みんなかなり四苦八苦していたのですが，それが結果的にいい「異文化コミュニケーション」になったと思います．彼は「日本の大学院に進学したい」と言い残して帰っていきました．</p>

## `Point` `Sprite`

そのフランス人に与えた課題の中で，彼は最初ビルボードにテクスチャを貼るという実装をしていたので，`Point` `Sprite` を使ったらもう少し高速化できるんじゃないかとアドバイスしました（この件に関しては pierrot さんアドバイスありがとうございました）．その後，卒業研究の学生さんのうちの一人が同じ大きさの球を大量に描いていることに気がついたので，その人にもそのうち `Point` `Sprite` を使うようアドバイスしようと思っていました．しかし，結局卒論の締め切りの方が先に来てしまいました．まあでも，その人は大学院に進学するので，その人の今後のためにもここにメモしておこうかと思います．

## ところで `Point` `Sprite` とは，`GL_POINTS` で描かれる「点」にテクスチャをマッピングする機能です．この機能は，OpenGL 2.0 で OpenGL の基本機能に組み込まれました．`GL_POINTS` で描かれる点は，デフォルトでは１画素の大きさですが，[`glPointSize()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glPointSize.xhtml) を使って任意の大きさの正方形にすることができます（アンチエリアシングをかけると丸くなります）．ただ，これにそのままテクスチャを貼ろうとしても，テクスチャ内の１画素の色がこの正方形の全面に適用されてしまい，画像としては貼り付けられません．`Point` `Sprite` を有効にすると，この正方形に期待通りにテクスチャが貼り付けられます．

## したがってこの機能は，パーティクルのようにポリゴンを使うと効率が悪いものを描画する際によく用いられます．また，最近では点の集合で表現された形状のレンダリング (`Point` Based Rendering) に盛んに用いられています．

## 点で図形を描く

それではまず，点で図形を描くプログラムを用意しましょう．ここでは点を噴水のように吹き上げるプログラムを雛形にします．なお，手元の Mac mini (Panther) では `Point` `Sprite` が使えなかったので，今回も Mac OS X 版は用意できませんでした．すみません．Tiger がまともに動く iMac か iBook 欲しいなぁ．

<ul>
<li>[Linux 版](`texture`/sprite0.tar.gz)</li>
<li>[Windows 版](`texture`/sprite0.lzh)</li>
</ul>

## このプログラムをコンパイルして実行すると，こういう噴水のようなアニメーションが表示されます．マウスをドラッグすれば，視点を移動できます．

![点の噴出]({{ site.baseurl }}/assets/images/sprite0.gif)

## ただ，これだと点が小さすぎて見えにくいので，[`glPointSize()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glPointSize.xhtml) を使って点の大きさを指定します．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
/* パーティクルを生成する */
if (particles.size() >= MAX_PARTICLES) {
particles.pop_back();
}
particle p;
particles.push_front(p);

/* パーティクルを描く */

glColor3d(1.0, 1.0, 1.0);
glPointSize(5.0);
glBegin(GL_POINTS);
for (std::deque::iterator ip = particles.begin();
ip != particles.end(); ++ip) {
glVertex3dv(ip->getPosition());
ip->update();
}
glEnd();
}
```

![点の大きさを指定する]({{ site.baseurl }}/assets/images/sprite1.gif)

## 点にテクスチャをマッピングする

それでは，この点にテクスチャをマッピングしてみましょう．マッピングするテクスチャには，次のような球をレンダリングした画像を用います．

![点にマッピングするテクスチャ]({{ site.baseurl }}/assets/images/sprite2.gif)

## まず，プログラムの初期化部分で，テクスチャマッピングの設定を行います．今回はファイルの入出力に `iostream` / `fstream` を使いますので，プログラムの先頭部分に以下の２行を追加してください．

```c
#include <iostream>
#include <fstream>

#include <stdlib.h>

#include <math.h>
```

## 初期化の関数 `init()` で画像ファイルを読み込み，テクスチャとしてマッピングします．

```c
...

/*
** テクスチャ
*/
#define TEXWIDTH  64                       /* テクスチャの幅　　　 */
#define TEXHEIGHT 64                       /* テクスチャの高さ　　 */
static const char texture[] = "ball.raw";  /* テクスチャファイル名 */

/*
** 初期化
*/
static void init(void)
{
/* テクスチャの読み込みに使う配列 */
GLubyte image[TEXHEIGHT][TEXWIDTH][4];

/* テクスチャ画像の読み込み */
std::ifstream file(texture, std::ios::in | std::ios::binary);
if (file) {
file.read((char *)image, sizeof image);
file.close();
}
else {
std::cerr 

/* テクスチャ画像はバイト単位に詰め込まれている */
glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

/* テクスチャを拡大・縮小する方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

/* テクスチャの繰り返し方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);

/* テクスチャ環境 */
glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

/* テクスチャの割り当て */
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, image);

/* 初期設定 */

glClearColor(0.3, 0.3, 1.0, 0.0);
glEnable(GL_DEPTH_TEST);
glDisable(GL_CULL_FACE);

/* 陰影付けを無効にする */

glDisable(GL_LIGHTING);

/* 地面の高さ */

particle::height(HEIGHT);
}
```

## そして，描画時にテクスチャマッピングを有効にします．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
/* パーティクルを生成する */
if (particles.size() >= MAX_PARTICLES) {
particles.pop_back();
}
particle p;
particles.push_front(p);

/* テクスチャマッピング開始 */
glEnable(GL_TEXTURE_2D);

/* パーティクルを描く */

glColor3d(1.0, 1.0, 1.0);
glPointSize(5.0);
glBegin(GL_POINTS);
for (std::deque::iterator ip = particles.begin();
ip != particles.end(); ++ip) {
glVertex3dv(ip->getPosition());
ip->update();
}
glEnd();

/* テクスチャマッピング終了 */
glDisable(GL_TEXTURE_2D);
}
```

## しかし，このままだとテクスチャ中の１画素の色が点（正方形）全体に適用されてしまいます．

![テクスチャ中の１画素の色が四角形全体に適用される]({{ site.baseurl }}/assets/images/sprite3.gif)

## そこで，`Point` `Sprite` を有効にします．まず，この点に対してテクスチャ座標を生成するようにテクスチャ環境を設定します．

```c
...

/*
** 初期化
*/
static void init(void)
{
...

/* テクスチャ環境 */

glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
glTexEnvi(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE);

/* テクスチャの割り当て */

glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, image);
```

## そして図形の描画時に，`GL_POINT_SPRITE` を有効にします．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
/* パーティクルを生成する */
if (particles.size() >= MAX_PARTICLES) {
particles.pop_back();
}
particle p;
particles.push_front(p);

/* テクスチャマッピング開始 */

glEnable(GL_TEXTURE_2D);

/* Point Sprite を有効にする */
glEnable(GL_POINT_SPRITE);

/* パーティクルを描く */

glColor3d(1.0, 1.0, 1.0);
glPointSize(20.0);
glBegin(GL_POINTS);
for (std::deque::iterator ip = particles.begin();
ip != particles.end(); ++ip) {
glVertex3dv(ip->getPosition());
ip->update();
}
glEnd();

/* Point Sprite を無効にする */
glDisable(GL_POINT_SPRITE);

/* テクスチャマッピング終了 */

glDisable(GL_TEXTURE_2D);
}
```

![`Point` `Sprite` を有効にした結果]({{ site.baseurl }}/assets/images/sprite4.gif)

## ただ，これだとテクスチャの全面が点に貼られてしまいます．テクスチャの必要な部分だけを貼り付けるには，テクスチャにアルファチャンネルを付けておいて，アルファテストを有効にします．まず，アルファテストの判別関数を設定します．

```c
...

/*
** 初期化
*/
static void init(void)
{
...

/* テクスチャ環境 */

glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
glTexEnvi(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE);

/* テクスチャの割り当て */

glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, image);

/* アルファテストの判別関数 */
glAlphaFunc(GL_GREATER, 0.5);
```

## そして図形の描画時にアルファテストを有効にします．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
/* パーティクルを生成する */
if (particles.size() >= MAX_PARTICLES) {
particles.pop_back();
}
particle p;
particles.push_front(p);

/* テクスチャマッピング開始 */

glEnable(GL_TEXTURE_2D);

/* Point Sprite を有効にする */

glEnable(GL_POINT_SPRITE);

/* アルファテストを有効にする */
glEnable(GL_ALPHA_TEST);

/* パーティクルを描く */

glColor3d(1.0, 1.0, 1.0);
glPointSize(20.0);
glBegin(GL_POINTS);
for (std::deque::iterator ip = particles.begin();
ip != particles.end(); ++ip) {
glVertex3dv(ip->getPosition());
ip->update();
}
glEnd();

/* アルファテストを無効にする */
glDisable(GL_ALPHA_TEST);

/* Point Sprite を無効にする */

glDisable(GL_POINT_SPRITE);

/* テクスチャマッピング終了 */

glDisable(GL_TEXTURE_2D);
}
```

## これで点を１個描くだけで球を描くようになりました．

![アルファテストを有効にした結果]({{ site.baseurl }}/assets/images/sprite5.gif)

## ウィンドウの大きさに合わせて点の大きさを変更する

現状では [`glPointSize()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glPointSize.xhtml) に定数を指定しているので，点の大きさは開いたウィンドウの大きさに関係なく一定になっています．点を形を持った図形として取り扱うなら，これはちょっと不自然です．そこで，ウィンドウの大きさに合わせて点の大きさを変更することにします．まず，点の大きさを決める変数 (`psize`) を用意します．

```c
...

/*
** パーティクル
*/
#include "particle.h"
#include 
#define MAX_PARTICLES 800
static std::deque particles;
static GLfloat psize;
```

## この変数は開いたウィンドウの幅に比例するようにします．

```c
...

static void resize(int w, int h)

{
/* 点の大きさを設定する */
psize = w * 0.1;

/* トラックボールする範囲 */

trackballRegion(w, h);
```

## glPointsize() の引数にこの変数を用います．

```c
...
/*
** シーンの描画
*/
static void scene(void)
{
...

/* パーティクルを描く */

glColor3d(1.0, 1.0, 1.0);
glPointSize(psize);
glBegin(GL_POINTS);
```

![点の大きさをウィンドウの大きさに合わせた結果]({{ site.baseurl }}/assets/images/sprite6.gif)

## 視点からの距離に応じて点の大きさを変更する

このプログラムは透視変換をおこなっているので，点であっても大きさを持っていれば，遠くの点は小さく，近くの点は大きく描かれる必要があります．そこで，点の大きさを視点からの距離に反比例するようにします．まず，次のような３要素の配列変数 `distance` を用意し，0 番目と 1 番目の要素に 0，2 番目の要素に 1 を入れておきます．

```c
...

/*
** パーティクル
*/
#include "particle.h"
#include 
#define MAX_PARTICLES 800
static std::deque particles;
static GLfloat psize;
static GLfloat distance[] = { 0.0, 0.0, 1.0 };
```

## そして [`glPointParameterfv()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glPointParameterfv.xhtml) を使って `GL_POINT_DISTANCE_ATTENUATION` にこの変数を指定します．

```c
...

#if defined(WIN32)

//#  pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#  include "glut.h"
#  include "glext.h"
PFNGLPOINTPARAMETERFVPROC glPointParameterfv;
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  define GL_GLEXT_PROTOTYPES
#  include <GL/glut.h>
#endif

...

/*
** 初期化
*/
static void init(void)
{
#if defined(WIN32)
glPointParameterfv =
(PFNGLPOINTPARAMETERFVPROC)wglGetProcAddress("glPointParameterfv");
#endif

...

/* テクスチャ環境 */

glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
glTexEnvi(GL_POINT_SPRITE, GL_COORD_REPLACE, GL_TRUE);

/* テクスチャの割り当て */

glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, image);

/* アルファテストの判別関数 */

glAlphaFunc(GL_GREATER, 0.5);

/* 距離に対する点の大きさの制御 */
glPointParameterfv(GL_POINT_DISTANCE_ATTENUATION, distance);
```

![点の大きさを視点からの距離に反比例させた結果]({{ site.baseurl }}/assets/images/sprite7.gif)

## [OpenGL 2.0 の仕様書](http://www.opengl.org/documentation/specs/version2.0/glspec20.pdf)によれば，実際に描かれる点の大きさは次式により求められるそうです．`size` は [`glPointSize()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glPointSize.xhtml) で指定した点の大きさです．

![点の大きさの計算式]({{ site.baseurl }}/assets/images/sprite8.gif)

## `GL_POINT_DISTANCE_ATTENUATION` に指定した配列変数の各要素は，この式の a, b, c に相当します．また d は視点からの距離です．したがって，a, b を 0 に，c に 1 を設定すれば，点の大きさが視点からの距離 d に反比例するようになります．

<ul>
<li>[Linux 版](`texture`/sprite1.tar.gz)</li>
<li>[Windows 版](`texture`/sprite1.lzh)</li>
</ul>
