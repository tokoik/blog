---
title: "第１６回 テクスチャの部分的な置き換え"
date: 2005-06-10
categories: [OpenGL,テクスチャ]
published: true
---

## 複数のテクスチャを使う

これまでの解説では，テクスチャは１枚しか使用しませんでした（キューブマッピングでは６枚の画像を使用していますが，これは６枚まとめてひとつのテクスチャとして扱っています）．シーン中でテクスチャが１枚しか使えないというのは，一見不便なように思えます．しかし，１枚のテクスチャを切り分けて使えば，シーン中の異なる部分に異なるテクスチャを貼り付けることができます．

## 複数のテクスチャを合成した画像ファイルを使う

テクスチャを切り分けて使うには，あらかじめ複数のテクスチャをつなぎ合わせて１枚の画像ファイルに書き込んでおく必要があります．たとえば立方体の６面に異なる画像を貼り付けてサイコロのような図形を表示したい場合，次のような画像を用意します（実際のサイズは 1024×128 画素）．

![サイコロのテクスチャ]({{ site.baseurl }}/assets/images/dice.jpg)

## 画像ファイルの縦横のサイズは，例によって 2<sup>n</sup> 画素にしておきます．使わないところは，もったいないですが，余らしておきましょう．これをこの[第２回]({{ site.baseurl }}{% post_url 2004-09-14-post %})でやったように，四角形の全面に貼り付けてみます．

<ul>
<li>[Linux 版](`texture`/texture10.tar.gz)</li>
<li>[Mac OS X 版](`texture`/texture10.zip)</li>
<li>[Windows 版](`texture`/texture10.lzh)</li>
</ul>

## すると，こんな具合になります．

 
![テクスチャ全体を全面に貼り付けたとき]({{ site.baseurl }}/assets/images/dice1.jpg)

## 各面にテクスチャの異なる部分を貼り付ける

画像の大きさが正方形でなくても，テクスチャ座標は縦横とも 0〜1 の範囲になるので，画像は長辺方向に圧縮されてしまいます．そこで，立方体の各面に異なるテクスチャを貼り付けるために，各面に対応したテクスチャの範囲をテクスチャから切り出すようにテクスチャ座標を取ります．

![テクスチャの切り出し]({{ site.baseurl }}/assets/images/dice2.gif)

## これを各面の頂点のテクスチャ座標に割り当てます．box.cpp で定義している変数 `texcoord` の初期値を次のように変更してください．

```c
...

/* 頂点のテクスチャ座標 */

static const GLdouble texcoord[][4][2] = {
{{ 0.0,   1.0 }, { 0.125, 1.0 }, { 0.125, 0.0 }, { 0.0,   0.0 }},
{{ 0.125, 1.0 }, { 0.25,  1.0 }, { 0.25,  0.0 }, { 0.125, 0.0 }},
{{ 0.25,  1.0 }, { 0.375, 1.0 }, { 0.375, 0.0 }, { 0.25,  0.0 }},
{{ 0.375, 1.0 }, { 0.5,   1.0 }, { 0.5,   0.0 }, { 0.375, 0.0 }},
{{ 0.5,   1.0 }, { 0.625, 1.0 }, { 0.625, 0.0 }, { 0.5,   0.0 }},
{{ 0.625, 1.0 }, { 0.75,  1.0 }, { 0.75,  0.0 }, { 0.625, 0.0 }},
};
```

## すると，ちゃんと６面に異なるテクスチャが貼り付けられ，サイコロらしくなります．

![テクスチャを分割して貼り付けたとき]({{ site.baseurl }}/assets/images/dice3.jpg)

## 複数の画像ファイルを使う

このように複数のテクスチャを合成した画像ファイルを用意すれば，１枚のテクスチャでも異なるテクスチャを使い分けることができます．しかし，そのような画像をあらかじめ用意しておくのも手間ですし，利用できるテクスチャのサイズには限界があるので，その限界を超えてテクスチャを詰め込むこともできません．
そこで，既に割り当てているテクスチャの一部を別の画像で入れ替えるという手段が用意されています．こうすればプログラムの実行時にテクスチャを入れ替えて，（処理時間は余計にかかりますが）何枚のテクスチャでも使用可能になります．これには [`glTexSubImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexSubImage2D.xhtml) を使用します．main.cpp に以下の内容を追加します．

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

/* テクスチャ画像の読み込み */

if ((fp = fopen(texture1, "rb")) != NULL) {
fread(texture, sizeof texture, 1, fp);
fclose(fp);
}
else {
perror(texture1);
}

/* テクスチャ画像はワード単位に詰め込まれている */

glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

/* テクスチャの割り当て */

glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, texture);

if ((fp = fopen("room2ny.raw", "rb")) != NULL) {
/* テクスチャ画像の読み込み */
fread(texture, 128 * 128 * 4, 1, fp);
fclose(fp);
/* テクスチャの置き換え */
glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, 128, 128,
GL_RGBA, GL_UNSIGNED_BYTE, texture);
}
```

<dl>
<dt>void glTexSubImage2D(GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels)</dt>
<dd>現在のテクスチャの一部を別の画像で置き換えます．引数 target は GL_TEXTURE_2D でないといけません．level には MIPMAP を行う場合のテクスチャの解像度レベルを指定します．MIPMAP を行わない場合は 0 にしておいてください．xoffset と yoffset には，テクスチャを置き換える先のテクスチャ上の位置を指定します．width と height には置き換えるテクスチャの幅と高さを指定します．format は引数 pixels に指定したメモリ上の画像の形式です．GL_RGB のほか，GL_RGBA, GL_COLOR_INDEX, GL_RED, GL_GREEN, GL_BLUE, GL_ALPHA, GL_LUMINANCE, GL_LUMINANCE_ALPHA が指定できます．type には引数 pixel の要素のデータ型を指定します．GL_UNSIGNED_BYTE は *pixels が GLubyte（unsigned char と等価）であることを示します．他に GL_BYTE, GL_SHORT, GL_UNSIGNED_SHORT, GL_INT, GL_UNSIGNED_INT, GL_FLOAT, GL_BITMAP が指定できます．pixels にはテクスチャの画像を格納したメモリ（配列）のポインタを指定します．</dd>
</dl>

![テクスチャの一部分を置き換えたとき]({{ site.baseurl }}/assets/images/dice4.jpg)

## [`glTexSubImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexSubImage2D.xhtml) は，[`glTexImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml) でテクスチャを割り当てた後，そのテクスチャの一部を別の画像で置き換えます．この際，置き換える画像のサイズは 2<sup>n</sup> である必要はありません．つまり，最初に [`glTexImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml) で（2<sup>n</sup> のサイズの）テクスチャを割り当てておけば，[`glTexSubImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexSubImage2D.xhtml) を使って（割り当てたテクスチャより小さな）任意のサイズの画像をテクスチャとして利用できます．

それでは先ほど追加した部分を<`em`>書き換えて，６面全部を置き換えてしまいましょう．テクスチャを置き換える位置の x 座標値を 128 画素ずつずらしながら，テクスチャを置き換えてゆきます．こうして全部の面を置き換えてしまうと，最初のサイコロの画像は不要になるので，この読み込みは無効にしておきます．

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

/* テクスチャ画像はワード単位に詰め込まれている */

glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

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

  if ((fp = fopen(textures[i], "rb")) != NULL) {
  /* テクスチャ画像の読み込み */
  fread(texture, 128 * 128 * 4, 1, fp);
  fclose(fp);
  /* テクスチャの置き換え */
  glTexSubImage2D(GL_TEXTURE_2D, 0, i * 128, 0, 128, 128,
    GL_RGBA, GL_UNSIGNED_BYTE, texture);
  }
}
```

## [`glTexSubImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexSubImage2D.xhtml) は実行時に動的にテクスチャを置き換えることができるので，これを使ってテクスチャのアニメーションなども実現できます．

![６面全部のテクスチャを置き換えたとき]({{ site.baseurl }}/assets/images/dice5.jpg)

<ul>
<li>[Linux 版](`texture`/texture11.tar.gz)</li>
<li>[Mac OS X 版](`texture`/texture11.zip)</li>
<li>[Windows 版](`texture`/texture11.lzh)</li>
</ul>
