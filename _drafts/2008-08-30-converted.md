---
title: "Vertex Buffer Object"
date: 2008-08-30
categories: [OpenGL]
published: true
---

## OpenGL 3.0 と GLSL 1.3

[OpenGL 3.0](http://www.opengl.org/registry/doc/glspec30.20080811.pdf) と [GLSL 1.3](http://www.opengl.org/registry/doc/GLSLangSpec.Full.1.30.08.pdf) のドキュメントを軽く眺めていたんですが，ちょっと気が滅入ってきました．最初にこれを読んで私が驚いた [The Deprecation Model](20080821#c02) というのは，固定機能を使うのをやめてプログラマブルシェーダに移行することを推奨するものなんですね．後方互換性は維持されているので「現時点では」まだ焦る必要はないと思うのですが，将来の仕様変更に対する前方互換性を確保しようとすると，glBegin() / glEnd() が使えないばかりか，[`glVertexPointer()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glVertexPointer.xhtml) 等を使って頂点配列を指定することすらできません．変換行列の操作や光源の設定，材質の設定なんかも一切できなくなってしまいます．

## このため GLSL の側でも，ftransform() が使えないというより，gl_Vertex や gl_ModelViewProjectionMatrix など，固定機能に由来する一切の組み込み変数が使えなくなります．つまり，頂点のデータは glVertexAttribPointer() を使ってユーザ定義の attribute（vertex shader では in になってしまうわけですが）変数で与え，変換行列もアプリケーション側で配列に値を設定してからユーザ定義の uniform 変数で与えることになります．そしてこれらを使ってシェーダで座標変換や陰影計算を行わなければなりません．さらに，この描画にはバッファオブジェクトを使うようです．

確かに，これは以前から言われていたことであり，これが新しいグラフィックスハードウェアのアーキテクチャを抽象化した結果なんでしょう．しかし，現実に移行しなければならないとなると，これまで固定機能がやってくれていたことをみんな自分で実装しないといけません．固定機能は結構シェーダプログラミングを助けてくれていたんですね．また，このプログラミングを教える場合にも，とっかかりが難しくなりそうです．将来，状態をオブジェクトにまとめるような書き方になってしまうと，もう昔の OpenGL のプログラムとは似ても似つかないものになっているでしょうね．GLU はどうなるのかな．赤本とかもどうするんでしょう？

## Vertex Buffer Object (VBO)

それで，試しにこの制限でプログラムを書いてみようと思いました．まだドライバを OpenGL 3.0 対応にしていないので真似事に過ぎないんですが，それでもこれは実に面倒に思えます．gluLookAt() や glFrustum() / gluPerspective() などに相当する関数を書くのは簡単ですし，glRotated() なんかもそれほど手間はかからないでしょう．だから，やり始めてしまえば何とかなると思うんですが，どういう attribute 変数や uniform 変数を準備しておくかとか，全体的な見通しを決めるのには，ちょっと慣れというか試行錯誤が必要になりそうです．そこで，今更ですが，OpenGL 1.5 から標準機能となった Vertex Buffer Object (VBO) を手始めに使ってみたいと思います．

## API を準備する

まず，VBO を使うための API を準備します．[前]({% post_url 2006-07-15-post %})にも書いていますが，これは [GLEW](http://glew.sourceforge.net/) を使うと手軽にできます．しかし，ここでは例によって自分で準備することにします．

```c
#if defined(WIN32)
//#  pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#  include "glut.h"
#  include "glext.h"
PFNGLGENBUFFERSPROC glGenBuffers;
PFNGLISBUFFERPROC glIsBuffer;
PFNGLBINDBUFFERPROC glBindBuffer;
PFNGLBUFFERDATAPROC glBufferData;
PFNGLBUFFERSUBDATAPROC glBufferSubData;
PFNGLMAPBUFFERPROC glMapBuffer;
PFNGLUNMAPBUFFERPROC glUnmapBuffer;
PFNGLDELETEBUFFERSPROC glDeleteBuffers;
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  define GL_GLEXT_PROTOTYPES
#  include <GL/glut.h>
#endif

...

void init(void)

{
#if defined(WIN32)
glGenBuffers =
(PFNGLGENBUFFERSPROC)wglGetProcAddress("glGenBuffers");
glIsBuffer =
(PFNGLISBUFFERPROC)wglGetProcAddress("glIsBuffer");
glBindBuffer =
(PFNGLBINDBUFFERPROC)wglGetProcAddress("glBindBuffer");
glBufferData =
(PFNGLBUFFERDATAPROC)wglGetProcAddress("glBufferData");
glBufferSubData =
(PFNGLBUFFERSUBDATAPROC)wglGetProcAddress("glBufferSubData");
glMapBuffer =
(PFNGLMAPBUFFERPROC)wglGetProcAddress("glMapBuffer");
glUnmapBuffer =
(PFNGLUNMAPBUFFERPROC)wglGetProcAddress("glUnmapBuffer");
glDeleteBuffers =
(PFNGLDELETEBUFFERSPROC)wglGetProcAddress("glDeleteBuffers");
#endif

...
}
```

## ちなみに Linux では，nVIDIA のプロプライエタリドライバを使えば libGL にこれらのエントリポイントが入っているんですが，AMD (ATI) のドライバだと用意してくれないみたいですね．この場合は glxGetProcAddress() を使って，Windows と同じように API のエントリポイントを取り出す必要があります．

## 頂点配列

[前回]({% post_url 2008-08-29-post %})に書いた頂点配列による描画手順は，まとめると次のようになります．

```c
/* 頂点データ */
static GLfloat vert[][3] = {
...
};

/* 法線データ */

static GLfloat norm[][3] = {
...
};

/* テクスチャ座標 */

static GLfloat texc[][2] = {
...
};

/* 頂点のインデックス */

static GLuint face[][3] = {
...
};

...

/* 三角形の数 */

static int nf = sizeof face / sizeof face[0];

...

/*
** 図形の表示
*/
void display(void)
{
...

/* 頂点データ，法線データ，テクスチャ座標の配列を有効にする */

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_NORMAL_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

/* 頂点データ，法線データ，テクスチャ座標の場所を指定する */

glVertexPointer(3, GL_FLOAT, 0, vert);
glNormalPointer(GL_FLOAT, 0, norm);
glTexCoordPointer(2, GL_FLOAT, 0, texc);

/* 頂点のインデックスの場所を指定して図形を描画する */

glEnable(GL_TEXTURE_2D);
glDrawElements(GL_TRIANGLES, nf * 3, GL_UNSIGNED_INT, face);
glDisable(GL_TEXTURE_2D);

/* 頂点データ，法線データ，テクスチャ座標の配列を無効にする */

glDisableClientState(GL_VERTEX_ARRAY);
glDisableClientState(GL_NORMAL_ARRAY);
glDisableClientState(GL_TEXTURE_COORD_ARRAY);

...
}
```

## バッファオブジェクトの作成

VBO の場合は，まずグラフィックスサブシステム側にメモリを確保（バッファオブジェクトを作成）し，あらかじめそこにデータを転送しておきます．

```c
...

/* バッファオブジェクトの名前を４つ用意する */

statc GLuint buffers[4];

...

/*
** 初期化
*/
void init(void)
{
...

/* バッファオブジェクトの名前を４つ作る */

glGenBuffers(4, buffers);

/* １つ目のバッファオブジェクトに頂点データ配列を転送する */

glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
glBufferData(GL_ARRAY_BUFFER, sizeof vert, vert, GL_STATIC_DRAW);

/* ２つ目のバッファオブジェクトに法線データ配列を転送する */

glBindBuffer(GL_ARRAY_BUFFER, buffers[1]);
glBufferData(GL_ARRAY_BUFFER, sizeof norm, norm, GL_STATIC_DRAW);

/* ３つ目のバッファオブジェクトにテクスチャ座標配列を転送する */

glBindBuffer(GL_ARRAY_BUFFER, buffers[2]);
glBufferData(GL_ARRAY_BUFFER, sizeof texc, texc, GL_STATIC_DRAW);

/* ４つ目のバッファオブジェクトに頂点のインデックスを転送する */

glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[3]);
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof face, face, GL_STATIC_DRAW);

...
}
```

## VBO による描画

そして，次の手順で描画を行います．これは頂点配列の描画手順に似ています．

```c
...

#define BUFFER_OFFSET(bytes) ((GLubyte *)NULL + (bytes))

...

/*
** 図形の表示
*/
void display(void)
{
...

/* 頂点データ，法線データ，テクスチャ座標の配列を有効にする */

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_NORMAL_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

/* 頂点データの場所を指定する */

glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
glVertexPointer(3, GL_FLOAT, 0, BUFFER_OFFSET(0));

/* 法線データの場所を指定する */

glBindBuffer(GL_ARRAY_BUFFER, buffers[1]);
glNormalPointer(GL_FLOAT, 0, BUFFER_OFFSET(0));

/* テクスチャ座標の場所を指定する */

glBindBuffer(GL_ARRAY_BUFFER, buffers[2]);
glTexCoordPointer(2, GL_FLOAT, 0, BUFFER_OFFSET(0));

/* 頂点のインデックスの場所を指定して図形を描く */

glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[3]);
glEnable(GL_TEXTURE_2D);
glDrawElements(GL_TRIANGLES, nf * 3, GL_UNSIGNED_INT, BUFFER_OFFSET(0));
glDisable(GL_TEXTURE_2D);

/* 頂点データ，法線データ，テクスチャ座標の配列を無効にする */

glDisableClientState(GL_VERTEX_ARRAY);
glDisableClientState(GL_NORMAL_ARRAY);
glDisableClientState(GL_TEXTURE_COORD_ARRAY);

...
}
```

## 頂点配列の場合と異なるのは，データの場所を指定する際に [`glBindBuffer()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBindBuffer.xhtml) を使ってバッファオブジェクトをバインドしておき，`glVertexPointer` 等で指定するデータの場所を，バッファオブジェクトの先頭からのオフセットで指定するという点です．

`BUFFER_OFFSET(`bytes`)` というマクロは赤本から借りました．これは `bytes` を unsigned char にキャストするのとあんまり変わりませんが，unsigned char が１バイトでない（unsigned char のポインタに１を足したときにアドレスが１より大きく増える）システム（あるのか？）てもオフセットを正しく計算できます．

## バッファオブジェクトの削除

使わなくなったバッファオブジェクトは，[`glDeleteBuffers()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glDeleteBuffers.xhtml) を使って削除します．

```c
glDeleteBuffers(4, buffers);
```

## バッファオブジェクトをまとめる

先の例ではバッファオブジェクトを４つ作っていましたが，`GL_ARRAY_BUFFER` にバインドするバッファオブジェクトは，ひとつにまとめることもできます．まず，`vert`，`norm`，および `texc` を合計したサイズのバッファオブジェクトを確保します．

```c
...

#define BUFFER_OFFSET(bytes) ((GLubyte *)NULL + (bytes))

...

/* バッファオブジェクトの名前を２つ用意する */

statc GLuint buffers[2];

...

/*
** 初期化
*/
void init(void)
{
...

/* バッファオブジェクトの名前を２つ作る */

glGenBuffers(2, buffers);

/* １つ目のバッファオブジェクトに頂点，法線，テクスチャ座標を合わせた領域を確保する */

glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
glBufferData(GL_ARRAY_BUFFER, sizeof vert + sizeof norm + sizeof texc, NULL, GL_STATIC_DRAW);
```

## [`glBufferData()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBufferData.xhtml) の第３引数に NULL を指定しているので，ここではバッファオブジェクトの確保のみが行われ，バッファオブジェクトの初期化（データの転送）は行われません．データの転送は，この後 [`glBufferSubData()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBufferSubData.xhtml) を使って行います．

```c
/* バッファオブジェクトの先頭に頂点データを転送する */
glBufferSubData(GL_ARRAY_BUFFER, BUFFER_OFFSET(0), sizeof vert, vert);
/* バッファオブジェクトの頂点データの次に法線データを転送する */
glBufferSubData(GL_ARRAY_BUFFER, BUFFER_OFFSET(sizeof vert), sizeof norm, norm);
/* バッファオブジェクトの法線データの次にテクスチャ座標を転送する */
glBufferSubData(GL_ARRAY_BUFFER, BUFFER_OFFSET(sizeof vert + sizeof norm), sizeof texc, texc);
```

## 頂点のインデックスの転送は，以前と同じです．

```c
/* ２つ目のバッファオブジェクトに頂点のインデックスを転送する */
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof face, face, GL_STATIC_DRAW);

...
}
```

## 描画のときは，[`glVertexPointer()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glVertexPointer.xhtml) 等で，データの場所としてデータを転送したバッファオブジェクトのオフセットを指定します．

```c
/*
** 図形の表示
*/
void display(void)
{
...

/* 頂点データ，法線データ，テクスチャ座標の配列を有効にする */

glEnableClientState(GL_VERTEX_ARRAY);
glEnableClientState(GL_NORMAL_ARRAY);
glEnableClientState(GL_TEXTURE_COORD_ARRAY);

/* 頂点データ，法線データ，テクスチャ座標の場所を指定する */

glBindBuffer(GL_ARRAY_BUFFER, buffers[0]);
glVertexPointer(3, GL_FLOAT, 0, BUFFER_OFFSET(0));
glNormalPointer(GL_FLOAT, 0, BUFFER_OFFSET(sizeof vert));
glTexCoordPointer(2, GL_FLOAT, 0, BUFFER_OFFSET(sizeof vert + sizeof norm));

/* 頂点のインデックスの場所を指定して図形を描く */

glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffers[1]);
glEnable(GL_TEXTURE_2D);
glDrawElements(GL_TRIANGLES, nf * 3, GL_UNSIGNED_INT, BUFFER_OFFSET(0));
glDisable(GL_TEXTURE_2D);

/* 頂点データ，法線データ，テクスチャ座標の配列を無効にする */

glDisableClientState(GL_VERTEX_ARRAY);
glDisableClientState(GL_NORMAL_ARRAY);
glDisableClientState(GL_TEXTURE_COORD_ARRAY);

...
}
```

## 複数のデータを一つのバッファオブジェクトにまとめるには，他に glInterleavedArray() を使う方法があるのですが，サンプルプログラムのデータ構造を変えないと使えないので，今回は割愛します．頂点の位置や法線ベクトル，テクスチャ座標などを構造体を使って一つの頂点ごとにまとめているような場合は，glInterleavedArray() を使うことになると思います．

## 補足

コメントで頂きましたように，一つの頂点の頂点属性をこの例のように離れたところに配置するより，頂点ごとにまとめた方がキャッシュのヒット率やデータの転送効率などの点で有利だと思われます（インターリーブの配置）．これに関して，エマ・デュランダルさまより詳しい解説を頂きました．ありがとうございます！

<ul>
<li>[[OpenGL] 任意の頂点形式に対応可能な頂点バッファオブジェクトの設定方法](https://docs.google.com/document/pub?id=1DyW4bu-ni8cr28lnltu6_r-bhve44BdIwqb2ZjwpcrI)</li>
</ul>

## サンプルプログラム

今回は説明のプログラムと作ったサンプルプログラムが一致していないので，説明のプログラムがちゃんと動くかどうかわかりません．

<ul>
<li>[Linux 版](vbo/vbo.tar.gz)</li>
<li>[Mac OS X 版](vbo/vbo.zip)</li>
<li>[Windows 版](vbo/vbo.lzh)</li>
</ul>
