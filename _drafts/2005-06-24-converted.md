---
title: "第２２回 放物面マッピング"
date: 2005-06-24
categories: [OpenGL,テクスチャ]
published: true
---

## 放物面鏡への映り込みを環境のテクスチャに使う

環境マッピングの手法には，[スフィアマッピング]({% post_url 2005-01-07-post %})と[キューブマッピング]({% post_url 2005-01-21-post %})のほかに，放物面マッピングと呼ばれる手法があります．この方法は Heidrich と Seidel によって提案されました．放物面というのは，パラボラアンテナに使われる曲面 (paraboloid) です．この方法はスフィアマッピングやキューブマッピングのように OpenGL に専用の機能が用意されているわけではありませんが，[マルチテクスチャ]({% post_url 2005-06-15-post %})を使えば簡単に実装できます．

## 放物面マッピングの特徴

スフィアマッピングは環境のテクスチャを簡単に作成できますが，実写だと球状の鏡を撮影する際にカメラが映り込んでしまいますし，視点の位置を自由に変えることもできません．一方，キューブマッピングでは視点の位置を任意に設定できますが，画像が６枚必要になります．これらの画像は平面的なのでコンピュータでレンダリングして作るのは楽ですが，実写だと撮影や画像の接合に手間がかかったりします．
これに対して放物面マッピングでは，環境のテクスチャを放物面鏡，あるいは近似的に魚眼レンズを使って作成することができます．魚眼レンズがその辺に転がっているとは思えませんが，これを使えばスフィアマッピングのようにカメラが映り込むことはありません．またこの方法は２枚の画像だけでキューブマッピングと同様に視点を任意の位置に設定することができます．

## 放物面鏡の性質

放物面鏡の凹面鏡には，入射した平行光線が１点（焦点）に集まるという性質を持っています．これに対して，放物面鏡の凸面鏡（凹面鏡の裏側）に光を当てると，反射光は焦点と反射点を結んだ直線の方向に反射します．

![放物面鏡の反射]({{ site.baseurl }}/assets/images/paraboloid1.gif)

## そこで，この放物面鏡を焦点の位置で切断し，２つを切断面で貼り合わせた鏡を考えます．

![二つの放物面鏡の貼り合わせ]({{ site.baseurl }}/assets/images/paraboloid2.gif)

## そして，反射ベクトルの Z 成分が正の場合は表の鏡に映った画像をテクスチャに用い，Z 成分が負の場合は裏の鏡に映った画像をテクスチャに用いれば，環境全体をくまなくマッピングできることになります．

## テクスチャ座標の算出

それでは，反射ベクトル (r<sub>x</sub>, r<sub>y</sub>, r<sub>z</sub>) からテクスチャ座標 (s, t) を算出してみましょう．今，x<sup>2</sup> + y<sup>2</sup> = z という回転放物面の焦点が原点となるように平行移動して，x<sup>2</sup> + y<sup>2</sup> = z + 0.25 という曲面について考えてみます．

![テクスチャ座標の算出]({{ site.baseurl }}/assets/images/paraboloid3.gif)

## これは裏側の鏡に映った画像に対するテクスチャ座標です．表側の鏡に対するテクスチャ座標は，単に r<sub>z</sub> の符号を反転するだけで求めることができます．また，このままでは (s, t) は [-0.5, 0.5] の範囲になりますから，[0, 1] のテクスチャ座標の範囲に収まるよう，s, t のそれぞれに 0.5 を足しておきます．

![放物面マッピングのテクスチャ座標]({{ site.baseurl }}/assets/images/paraboloid4.gif)

## 放物面マッピングの実装

上の式より，キューブマッピングと同様にテクスチャ座標として反射ベクトルを用い，テクスチャ変換行列に上記の行列を設定しておけば，放物面マッピングが実現できることになります．本当はキューブマッピングと違って，この手法ではテクスチャ座標の第４要素 (q) が必ず 1 である必要があります．しかし，テクスチャ座標のデフォルト値は (0, 0, 0, 1) なので，ここでは q を自動生成しなければ q は多分 1 のままだろうという甘い考え方を採用します．
もう一つ問題があります．この手法では二つのテクスチャを使い分けまが，どちらのテクスチャを使うのかは画素単位に判断しなければなりません．この判断は反射ベクトル r<sub>z</sub> の符号を見て行うことができるのですが，OpenGL には（プログラマブルシェーダを使わなければ）このような判断を組み込む余地がありません．
しかし，(s, t) が一方のテクスチャの範囲内にあれば，もう一方のテクスチャでは (s, t) は必ずテクスチャの範囲外になるはずです．そこで Heidrich と Seidel は，アルファテストを使って範囲外のポリゴンを削り取り，表側と裏側に分けて２回描くという[手法](http://www.cs.ubc.ca/~heidrich/Papers/GH.98.pdf)を採用しています．
一方 [Real-Time Rendering](http://www.realtimerendering.com/) の本には，双方のテクスチャの範囲外の色を黒にして，２つのテクスチャを単に加算するという方法が示されています．確かに，こうすれば範囲内にあるほうのテクスチャの色がマッピングされるはずです．
ということで，こっちの方法を使って実際にやってみましょう．雛形のプログラムには[マルチテクスチャ]({% post_url 2005-06-15-post %})のときに使ったものを流用します．

<ul>
<li>[Linux 版](`texture`/texture14.tar.gz)</li>
<li>[Mac OS X 版](`texture`/texture14.zip)</li>
<li>[Windows 版](`texture`/texture14.lzh)</li>
</ul>

## マルチテクスチャを使って実装するので，Windows ではまず `glext`.h の読み込みと，関数ポインタ変数 `glActiveTexture` の宣言を行っておいてください．

```c
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#if defined(WIN32)
//#  pragma comment(linker, "/subsystem:\"windows\" /entry:\"mainCRTStartup\"")
#  include "glut.h"
#  include "glext.h"
PFNGLACTIVETEXTUREPROC glActiveTexture;
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  include <GL/glut.h>
#endif
```

## あらかじめテクスチャの境界色に使う変数 `border` を宣言し，それに黒色を設定しておきます．また今回は，もともとあった下地のテクスチャと合わせて合計３つのテクスチャを使うので，テクスチャオブジェクトを３つ作成しておきます．さらに Windows の場合は，関数ポインタ変数 `glActiveTexture` に [`glActiveTexture()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glActiveTexture.xhtml) の実体のエントリポイントを代入しておきます．

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

/* テクスチャ画像はワード単位に詰め込まれている */

glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

/* テクスチャの境界色 */
static const GLfloat border[] = { 0.0, 0.0, 0.0, 0.0 };

/* 各テクスチャユニット用にテクスチャオブジェクトを作る */
GLuint texname[3];
glGenTextures(3, texname);

#if defined(WIN32)
glActiveTexture =
(PFNGLACTIVETEXTUREPROC)wglGetProcAddress("glActiveTexture");
#endif
```

## そうしたら，先に裏面の放物面テクスチャのマッピングを行います．このテクスチャマッピングにはテクスチャユニット０を使います．放物面テクスチャは２次元テクスチャとしてマッピングします．

```c
/* 裏面の放物面テクスチャのマッピングに使うテクスチャユニット */
glActiveTexture(GL_TEXTURE0);
glBindTexture(GL_TEXTURE_2D, texname[0]);

/* テクスチャ画像の読み込み */
if ((fp = fopen("paraboloid1.raw", "rb")) != NULL) {
fread(texture, sizeof texture, 1, fp);
fclose(fp);
}

/* テクスチャの割り当て */
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, texture);

/* テクスチャを拡大・縮小する方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
```

## `GL_TEXTURE_WRAP_S` と `GL_TEXTURE_WRAP_T` に `GL_CLAMP_TO_BORDER` を設定して，境界色がテクスチャの周囲に拡張されるようにします．そしてテクスチャの境界色に黒色を設定すれば，テクスチャからはみ出た部分が黒になります．あと，今回は下地の色が影響すると具合が悪いので，裏側の放物面テクスチャで下地のテクスチャを置き換えてしまいます．

```c
/* テクスチャの繰り返し方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

/* テクスチャの境界色 */
glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, border);

/* テクスチャ環境 */
glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
```

## テクスチャ座標として，反射ベクトルを自動生成するようにします．また，このテクスチャ座標の変換行列に，前述の行列を設定しておきます．このあたりが，この手法の一番のミソですね．

```c
/* 反射ベクトルをテクスチャ座標として使う */
glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);

/* 裏面のマッピングに使うテクスチャ変換行列の設定 */
glMatrixMode(GL_TEXTURE);
static const GLdouble mat1[] = {
1.0,  0.0,  0.0,  0.0,
0.0,  1.0,  0.0,  0.0,
-1.0, -1.0,  0.0, -2.0,
1.0,  1.0,  0.0,  2.0,
};
glLoadMatrixd(mat1);
glMatrixMode(GL_MODELVIEW);
```

## 表面のテクスチャについても，同様の設定を行います．このテクスチャマッピングにはテクスチャユニット１を使います．

```c
/* 表面の放物面テクスチャのマッピングに使うテクスチャユニット */
glActiveTexture(GL_TEXTURE1);
glBindTexture(GL_TEXTURE_2D, texname[1]);

/* テクスチャ画像の読み込み */
if ((fp = fopen("paraboloid2.raw", "rb")) != NULL) {
fread(texture, sizeof texture, 1, fp);
fclose(fp);
}

/* テクスチャの割り当て */
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, texture);

/* テクスチャを拡大・縮小する方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);

/* テクスチャの繰り返し方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);

/* テクスチャの境界色 */
glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, border);
```

## ただし，表面のテクスチャのテクスチャ環境は `GL_ADD` にして，表面のテクスチャを裏面のテクスチャに加算するようにします．

```c
/* テクスチャ環境 */
glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_ADD);

/* 反射ベクトルをテクスチャ座標として使う */
glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);

/* 表面のマッピングに使うテクスチャ変換行列の設定 */
glMatrixMode(GL_TEXTURE);
static const GLdouble mat2[] = {
1.0,  0.0,  0.0,  0.0,
0.0,  1.0,  0.0,  0.0,
1.0,  1.0,  0.0,  2.0,
1.0,  1.0,  0.0,  2.0,
};
glLoadMatrixd(mat2);
glMatrixMode(GL_MODELVIEW);
```

## 最後にもともとあったテクスチャをテクスチャユニット２に割り当てます．

```c
/* 拡散色のマッピングに用いるテクスチャユニット */
glActiveTexture(GL_TEXTURE2);
glBindTexture(GL_TEXTURE_2D, texname[2]);

/* テクスチャ画像の読み込み */

if ((fp = fopen(texture1, "rb")) != NULL) {
fread(texture, sizeof texture, 1, fp);
fclose(fp);
}
```

## シーンを描画する際は，二つの放物面テクスチャのマッピングとテクスチャ座標の自動生成を有効にします．描画が終わったら，それぞれを無効にします．なお，もともとあったテクスチャは，今回は使用しないので，無効にしておきます．

 

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

/* 裏面の放物面テクスチャのマッピング開始 */
glActiveTexture(GL_TEXTURE0);
glEnable(GL_TEXTURE_2D);
glEnable(GL_TEXTURE_GEN_S);
glEnable(GL_TEXTURE_GEN_T);
glEnable(GL_TEXTURE_GEN_R);

/* 表面の放物面テクスチャのマッピング開始 */
glActiveTexture(GL_TEXTURE1);
glEnable(GL_TEXTURE_2D);
glEnable(GL_TEXTURE_GEN_S);
glEnable(GL_TEXTURE_GEN_T);
glEnable(GL_TEXTURE_GEN_R);

#if 0
/* テクスチャマッピング開始 */
glEnable(GL_TEXTURE_2D);
#endif

/* トラックボール処理による回転 */

glMultMatrixd(trackballRotation());

/* 箱を描く */

box(1.0, 1.0, 1.0);

#if 0
/* テクスチャマッピング終了 */
glDisable(GL_TEXTURE_2D);
#endif

/* 表面の放物面テクスチャのマッピング終了 */
glActiveTexture(GL_TEXTURE1);
glDisable(GL_TEXTURE_GEN_S);
glDisable(GL_TEXTURE_GEN_T);
glDisable(GL_TEXTURE_GEN_R);
glDisable(GL_TEXTURE_2D);

/* 裏面の放物面テクスチャのマッピング終了 */
glActiveTexture(GL_TEXTURE0);
glDisable(GL_TEXTURE_GEN_S);
glDisable(GL_TEXTURE_GEN_T);
glDisable(GL_TEXTURE_GEN_R);
glDisable(GL_TEXTURE_2D);
}
```

## これでプログラムの方は完成です．あとは使用する放物面テクスチャを用意するだけです．ここでは魚眼レンズを使って作成した，次の画像を使用してください．

<div class="figure">
![裏面の放物面テクスチャ]({{ site.baseurl }}/assets/images/paraboloid1.jpg)
![表面の放物面テクスチャ]({{ site.baseurl }}/assets/images/paraboloid2.jpg)
</div>

<ul>
<li>[裏面の放物面テクスチャ](`texture`/paraboloid1.`raw`.gz)</li>
<li>[表面の放物面テクスチャ](`texture`/paraboloid2.`raw`.gz)</li>
</ul>

## 使用した魚眼レンズは画像の中心からの距離と角度が比例しているもので，放物面鏡とは角度分布が異なります．ただ，放物面鏡の角度分布を調べてみると次のようなグラフになったので，「この程度なら人間の目はごまかされるやろ，環境マッピングやし」ということで，補正することなしにそのまま使っています．

![放物面鏡の角度分布]({{ site.baseurl }}/assets/images/paraboloid5.gif)

## プログラムの実行結果

これらのテクスチャを使ってプログラムを実際に動かしてみると，次のような実行結果が得られます．右の図は関数 `box()` を glutSolidSphere() に置き換えたものです．

<div class="figure">
![`GL_ADD` を使って合成した場合（箱）]({{ site.baseurl }}/assets/images/paraboloid6.jpg)
![`GL_ADD` を使って合成した場合（球）]({{ site.baseurl }}/assets/images/paraboloid7.jpg)
</div>

## 箱にマッピングした場合は，真ん中に「お化け」のような妙なものが写っています．これは裏側のテクスチャが表側の領域に現れているようです．

表側のテクスチャの領域は裏側のテクスチャの領域の範囲外なので，本当ならこんなところに裏側のテクスチャが現れるはずはありません．しかし，裏側のテクスチャ座標を求める式の分母は 1-r<sub>z</sub> となっており，r<sub>z</sub> = 1 のとき，すなわち反射方向が表側の正面のときは，テクスチャ座標を求めることができません．これがきっとこの「お化け」の正体なんでしょう．
一方，球にマッピングしたときは，明るい円のようなものが見えています．これは裏面のテクスチャと表面のテクスチャが重なっている部分で，明度が加算されて明るくなってしまっているようです．
これは表と裏のテクスチャの周囲が正確に一致するようテクスチャを丁寧に切り抜けば，目立たなくすることができます．でも，２枚のテクスチャの周囲を一致させる作業は，今回は手作業でやっているので，どうしても完全にはできませんでした．
そこで，`GL_ADD` を使うのをあきらめて，`GL_DECAL` を使うことにします．`GL_DECAL` なら，アルファ値を使って必要なところだけ貼り付けることができます．加算をしないので，裏側のテクスチャがにじみ出てきたり，周囲が重なって明るくなったりすることはありません．ただ，逆に表側のテクスチャが裏側 (r<sub>z</sub> = -1) の面に現れる可能性がありますが，物体が閉じていれば裏側の面は見えないので，問題にはならないでしょう．

```c
...

/* 表面の放物面テクスチャのマッピングに使うテクスチャユニット */

glActiveTexture(GL_TEXTURE1);
glBindTexture(GL_TEXTURE_2D, texname[1]);

...

/* テクスチャ環境 */

glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);

/* 反射ベクトルをテクスチャ座標として使う */

glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);
glTexGeni(GL_R, GL_TEXTURE_GEN_MODE, GL_REFLECTION_MAP);

/* 表面のマッピングに使うテクスチャ変換行列の設定 */

glMatrixMode(GL_TEXTURE);
static const GLdouble mat2[] = {
1.0,  0.0,  0.0,  0.0,
0.0,  1.0,  0.0,  0.0,
1.0,  1.0,  0.0,  2.0,
1.0,  1.0,  0.0,  2.0,
};
glLoadMatrixd(mat2);
glMatrixMode(GL_MODELVIEW);
```

<div class="figure">
![`GL_DECAL` を使って合成した場合（箱）]({{ site.baseurl }}/assets/images/paraboloid8.jpg)
![`GL_DECAL` を使って合成した場合（球）]({{ site.baseurl }}/assets/images/paraboloid9.jpg)
</div>

## 球はまだ少しテクスチャの境界が見えていますが，だいぶましになりました．実はテクスチャ自体にも少し工夫してあります．使用した魚眼レンズは画角が 180°より少しだけ大きいらしく，周囲に若干の余裕がありました．そこで画像は実際に貼り付ける領域よりも少し大きめに切り取り，アルファ値の方は実際に貼り付ける領域の周囲に少しだけグラデーションをつけています．これで表面と裏面のテクスチャが境界部分でブレンドされるようにしています．

<div class="figure">
![`GL_DECAL` を使って合成した場合（トーラス）]({{ site.baseurl }}/assets/images/paraboloid10.jpg)
![`GL_DECAL` を使って合成した場合（ティーポット）]({{ site.baseurl }}/assets/images/paraboloid11.jpg)
</div>

<ul>
<li>[Linux 版](`texture`/texture18.tar.gz)</li>
<li>[Mac OS X 版](`texture`/texture18.zip)</li>
<li>[Windows 版](`texture`/texture18.lzh)</li>
</ul>

## この方法では環境の２枚のテクスチャを，下地の色が透けないように不透明にしてマッピングする必要があります．したがって，他のテクスチャと合成する場合には，これらの環境のテクスチャを最下層（テクスチャユニット０と１）に置いて，その上から他のテクスチャを合成する必要があります．
