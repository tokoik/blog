---
title: "第１８回 テクスチャオブジェクト"
date: 2005-06-14
categories: [OpenGL,テクスチャ]
published: true
---

## 独立したテクスチャが使いたい

テクスチャが１枚しかなくても，テクスチャを分割して使うことで，異なる場所や物体に異なるテクスチャを貼り付けることができます．それでも，やはり独立したテクスチャが使えたほうが何かと便利です．たとえば[キューブマッピング]({% post_url 2005-01-21-post %})はテクスチャに使う画像の全体を使用しますから，その一部を切り分けて他に流用するようなことができません．この場合は独立したテクスチャが必要になります．

## テクスチャオブジェクト

OpenGL において独立した複数のテクスチャを取り扱う機能のことを，<`em`>テクスチャオブジェクトと呼びます．複数のテクスチャメモリを動的に割り当てたり開放したりする機能のほか，テクスチャに優先度を与えて処理速度を最適化する機能も用意されています．

## 部屋の中にティーポットを置いてみる

それでは，通常のテクスチャマッピングにキューブマッピングを組み合わせてみましょう．まず，[前回]({% post_url 2005-06-11-post %})作ったプログラムを雛形にして，箱の中にティーポットを置いて眺めてみることにします．

<ul>
<li>[Linux 版](`texture`/texture12.tar.gz)</li>
<li>[Mac OS X 版](`texture`/texture12.zip)</li>
<li>[Windows 版](`texture`/texture12.lzh)</li>
</ul>

## 視点はこの箱の中心にありますから，それより少し前（奥）の方に，ティーポットを配置します．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
static const GLfloat color[] = { 1.0, 1.0, 1.0, 1.0 };  /* 材質 (色) */

/* 材質の設定 */

glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, color);

/* 視点より少し奥にティーポットを描く */
glPushMatrix();
glTranslated(0.0, 0.0, -5.0);
glutSolidTeapot(1.0);
glPopMatrix();
```

![部屋の中のティーポット]({{ '/assets/images/texobj1.jpg' | relative_url }})

## ティーポットにキューブマッピングしてみる

このティーポットにキューブマッピングを施します．Windows の VC++ 6.0 に含まれている gl.h にはキューブマッピングに必要な記号定数が定義されていないので，<%= a "SGI" %> の [OpenGL® Sample Implementation](http://oss.sgi.com/projects/ogl-sample/) にある <%= a "`glext`.h" %> を #`include` するようにしてください．

```c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#if defined(WIN32)
//#  pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#  include "glut.h"
#  include "glext.h"
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  include <GL/glut.h>
#endif
```

## テクスチャオブジェクトを作る

キューブマッピングテクスチャはその側の箱と独立したものにするために，テクスチャオブジェクトを一つ作ります．テクスチャオブジェクトには，それを識別するためにテクスチャ名（実際には番号）を割り当てます．それを格納しておく変数を用意します．今回はテクスチャオブジェクトを一つしか使わないので，テクスチャ名を格納する配列変数 `texname` の要素数は 1 にしています．

```c
...

/*
** テクスチャ
*/
#define TEXWIDTH  1024                     /* テクスチャの幅　　　 */
#define TEXHEIGHT 128                      /* テクスチャの高さ　　 */
static const char texture1[] = "dice.raw"; /* テクスチャファイル名 */
static GLuint texname[1];                  /* テクスチャ名（番号） */
```

## そして，テクスチャ名を生成して，この配列変数に格納します．

```c
...

/*
** 初期化
*/
static void init(void)
{
/* テクスチャの読み込みに使う配列 */
GLubyte texture[TEXHEIGHT * TEXWIDTH * 4];
FILE *fp;

#if 0

/* テクスチャ画像の読み込み */
if ((fp = fopen(texture1, "rb")) != NULL) {
fread(texture, sizeof texture, 1, fp);
fclose(fp);
}
else {
perror(texture1);
}
#endif

/* テクスチャ名を１個生成する */
glGenTextures(1, texname);

/* テクスチャ画像はワード単位に詰め込まれている */

glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
```

<dl>
<dt>void `glGenTextures`(GLsizei n, `GLuint` *`textures`)</dt>
<dd>テクスチャ名を n 個生成します．生成したテクスチャ名は，引数 `textures` に指定した配列の各要素に格納されます．</dd>
</dl>

## テクスチャオブジェクトを選択する

このテクスチャ名を使って，テクスチャオブジェクトを処理対象のテクスチャとします．ここでは外側の箱の１面に貼り付けているテクスチャを，キューブマッピングの１面のテクスチャにも利用することにします．
まず，キューブマッピング用のテクスチャのターゲット名を配列変数 `target` に格納しておきます．そして，[`glTexImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml) を使ってテクスチャの割り当てを行う処理を追加します．この処理に先立って `glBindTexture`(`GL_TEXTURE_CUBE_MAP`, <`em`>`texname`[0]) を実行し，[`glTexImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml) によるテクスチャの割り当てが `texname`[0] で指定されるテクスチャオブジェクトに対して行われるようにします．その後，`glBindTexture`(`GL_TEXTURE_2D`, <`em`>0) を呼び出して，処理対象のテクスチャを箱のテクスチャに切り替えます．このテクスチャ名が <`em`>0 のテクスチャを無名テクスチャといい，デフォルトで用意されているテクスチャを表します．

```c
/* テクスチャの割り当て */
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, texture);

for (int i = 0; i < 6; ++i) {

/* テクスチャファイル名 */
static const char *textures[] = {
"room2ny.raw", /* 下 */
"room2nz.raw", /* 裏 */
"room2px.raw", /* 右 */
"room2pz.raw", /* 前 */
"room2nx.raw", /* 左 */
"room2py.raw", /* 上 */
};
  /* テクスチャのターゲット名 */
static const int target[] = {
GL_TEXTURE_CUBE_MAP_NEGATIVE_Y,
GL_TEXTURE_CUBE_MAP_NEGATIVE_Z,
GL_TEXTURE_CUBE_MAP_POSITIVE_X,
GL_TEXTURE_CUBE_MAP_POSITIVE_Z,
GL_TEXTURE_CUBE_MAP_NEGATIVE_X,
GL_TEXTURE_CUBE_MAP_POSITIVE_Y,
};

if ((fp = fopen(textures[i], "rb")) != NULL) {

/* テクスチャ画像の読み込み */
fread(texture, 128 * 128 * 4, 1, fp);
fclose(fp);
/* テクスチャの置き換え */
glTexSubImage2D(GL_TEXTURE_2D, 0, i * 128, 0, 128, 128,
GL_RGBA, GL_UNSIGNED_BYTE, texture);
  /* キューブマッピングのテクスチャの割り当て */
glBindTexture(GL_TEXTURE_CUBE_MAP, texname[0]);
glTexImage2D(target[i], 0, GL_RGBA, 128, 128, 0, 
GL_RGBA, GL_UNSIGNED_BYTE, texture);
glBindTexture(GL_TEXTURE_2D, 0);
}
}
```

<dl>
<dt>void `glBindTexture`(GLenum `target`, `GLuint` `texture`)</dt>
<dd>`target` に対して `texture` というテクスチャ名のテクスチャオブジェクトを結合します．テクスチャオブジェクトは，テクスチャ名に対して最初にこの呼び出しが行われたときに生成されます．これ以降，テクスチャに対する設定は `texture` に指定したテクスチャオブジェクトに対して行われます．`target` には `GL_TEXTURE_1D`, `GL_TEXTURE_2D`, および OpenGL 1.2 以降では `GL_TEXTURE_3D`，OpenGL 1.3 以降では `GL_TEXTURE_CUBE_MAP` が指定できます．テクスチャ名 0 はデフォルトのテクスチャを示します．</dd>
</dl>

## `texname`[0] のテクスチャに対する，そのほかの設定も行いましょう．この部分もやはり `glBindTexture`(`GL_TEXTURE_CUBE_MAP`, `texname`[0]) と `glBindTexture`(`GL_TEXTURE_2D`, 0) ではさみます．

なお，ここで [`glTexEnvi()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexEnvi.xhtml) で指定するテクスチャ環境が，テクスチャオブジェクトごとに保存されないことに注意してください．このため，テクスチャオブジェクトごとに異なるテクスチャ環境を設定する場合は，テクスチャオブジェクトを切り替える都度，テクスチャ環境を設定する必要があります．

```c
/* テクスチャを拡大・縮小する方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

/* テクスチャの繰り返し方法の指定 */

glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);

#if 0
/* テクスチャ環境 */
glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
#endif

/* 設定対象をtexname[0] のテクスチャに切り替える */
glBindTexture(GL_TEXTURE_CUBE_MAP, texname[0]);

/* テクスチャを拡大・縮小する方法の指定 */
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

/* テクスチャの繰り返し方法の指定 */
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_S, GL_CLAMP);
glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_WRAP_T, GL_CLAMP);

/* キューブマッピング用にテクスチャ座標を生成する */
glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);

/* 設定対象を無名テクスチャに戻す */
glBindTexture(GL_TEXTURE_2D, 0);
```

## キューブマッピングを有効にする

そして，図形の描画時にキューブマッピングを有効にします．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
static const GLfloat color[] = { 1.0, 1.0, 1.0, 1.0 };  /* 材質 (色) */

/* 材質の設定 */

glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, color);

/* 設定対象をtexname[0] のテクスチャに切り替える*/
glBindTexture(GL_TEXTURE_CUBE_MAP, texname[0]);

/* テクスチャ環境 */
glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

/* キューブマッピングを有効にする */
glEnable(GL_TEXTURE_CUBE_MAP);
glEnable(GL_TEXTURE_GEN_S);
glEnable(GL_TEXTURE_GEN_T);
glEnable(GL_TEXTURE_GEN_R);

/* 視点より少し奥にティーポットを描く */

glPushMatrix();
glTranslated(0.0, 0.0, -5.0);
glutSolidTeapot(1.0);
glPopMatrix();

/* キューブマッピングを解除する */
glDisable(GL_TEXTURE_GEN_S);
glDisable(GL_TEXTURE_GEN_T);
glDisable(GL_TEXTURE_GEN_R);
glDisable(GL_TEXTURE_CUBE_MAP);

/* 設定対象を無名テクスチャに戻す */
glBindTexture(GL_TEXTURE_2D, 0);

/* テクスチャ環境 */
glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
```

## これで普通のテクスチャマッピングとキューブマッピングを両方実装できました．

![ティーポットにキューブマッピング]({{ '/assets/images/texobj2.jpg' | relative_url }})

## 部屋の回転にあわせて映り込みも回転させよう

このプログラムでは，マウスのドラッグにしたがって，部屋というか，部屋のテクスチャをマッピングした箱を回転させることができます．しかし，今のままではティーポットへの映り込みが動かないため，ちょっと違和感があります．そこで，部屋の回転にあわせて，[以前やった]({% post_url 2005-01-31-post %})ようにティーポットへの映り込みを回転させてみましょう．
なお，Visual C++ 6.0 の gl.h にはこの回転に使う [`glLoadTransposeMatrixd()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glLoadTransposeMatrixd.xhtml) が宣言されていないので，プログラムの先頭部分でこの関数を指す関数ポインタ変数の定義を追加します．

```c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#if defined(WIN32)
//#  pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#  include "glut.h"
#  include "glext.h"
PFNGLLOADTRANSPOSEMATRIXDPROC glLoadTransposeMatrixd;
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  include <GL/glut.h>
#endif
```

## また，初期化の関数 `init`() の最後あたりで，この関数ポインタ変数に [`glLoadTransposeMatrixd()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glLoadTransposeMatrixd.xhtml) の実体のエントリポイントを代入しておきます．

```c
...

/* 光源の初期設定 */

glEnable(GL_LIGHTING);
glEnable(GL_LIGHT0);
glLightfv(GL_LIGHT0, GL_DIFFUSE, lightcol);
glLightfv(GL_LIGHT0, GL_SPECULAR, lightcol);
glLightfv(GL_LIGHT0, GL_AMBIENT, lightamb);

#if defined(WIN32)
glLoadTransposeMatrixd =
(PFNGLLOADTRANSPOSEMATRIXDPROC)wglGetProcAddress("glLoadTransposeMatrixd");
#endif
}
```

## 例によって手を抜いてエラーチェックを省略しています．もし [`glLoadTransposeMatrixd()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glLoadTransposeMatrixd.xhtml) が実装されていない場合，関数ポインタ変数 `glLoadTransposeMatrixd` が NULL になるので，その状態で実行するとプログラムが異常終了してしまいます．

## 映り込みのテクスチャを回転する

テクスチャを回転させるために，まず `glMatrixMode`(`GL_TEXTURE`) でテクスチャ変換行列に切り替えてから，[`glLoadTransposeMatrixd()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glLoadTransposeMatrixd.xhtml) を使って回転の行列を設定します．その後，すぐに `glMatrixMode`(`GL_MODELVIEW`) を呼び出してモデルビュー変換行列に戻しておかないと，その後の座標変換が（テクスチャ変換行列に適用されて）正しく行われなくなってしまいます．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
static const GLfloat color[] = { 1.0, 1.0, 1.0, 1.0 };  /* 材質 (色) */

/* 材質の設定 */

glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, color);

/* 設定対象をtexname[0] のテクスチャに切り替える*/

glBindTexture(GL_TEXTURE_CUBE_MAP, texname[0]);

/* テクスチャ環境 */

glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);

/* キューブマッピングを有効にする */

glEnable(GL_TEXTURE_CUBE_MAP);
glEnable(GL_TEXTURE_GEN_S);
glEnable(GL_TEXTURE_GEN_T);
glEnable(GL_TEXTURE_GEN_R);

/* テクスチャ変換行列にトラックボール式の回転を加える */
glMatrixMode(GL_TEXTURE);
glLoadTransposeMatrixd(trackballRotation());
glMatrixMode(GL_MODELVIEW);

/* 視点より少し奥にティーポットを描く */

glPushMatrix();
glTranslated(0.0, 0.0, -5.0);
glutSolidTeapot(1.0);
glPopMatrix();

/* テクスチャ変換行列を元に戻す */
glMatrixMode(GL_TEXTURE);
glLoadIdentity();
glMatrixMode(GL_MODELVIEW);

/* キューブマッピングを解除する */

glDisable(GL_TEXTURE_GEN_S);
glDisable(GL_TEXTURE_GEN_T);
glDisable(GL_TEXTURE_GEN_R);
glDisable(GL_TEXTURE_CUBE_MAP);

/* 設定対象を無名テクスチャに戻す */

glBindTexture(GL_TEXTURE_2D, 0);

/* テクスチャ環境 */

glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
```

## テクスチャ変換行列はテクスチャオブジェクトと関連していないので，他の図形を描画するときはテクスチャ変換行列を元に戻しておく必要があります．

![ティーポットへの映り込みも回転する]({{ '/assets/images/texobj3.jpg' | relative_url }})

## これで周囲の情景にあわせてティーポットへの映り込みも回転するので，レイトレーシングっぽい表現が可能になります．映り込みのテクスチャにレンダリングした画像を用いれば，擬似的なレイトレーシングがリアルタイムに可能になります．図形をテクスチャとしてレンダリングする方法については，また後日．

<ul>
<li>[Linux 版](`texture`/texture13.tar.gz)</li>
<li>[Mac OS X 版](`texture`/texture13.zip)</li>
<li>[Windows 版](`texture`/texture13.lzh)</li>
</ul>
