---
title: "第１５回 ポイントのアニメーション"
date: 2009-12-25
categories: [OpenGL,GLSL,ゼミ]
published: true
---

## あああまた年末だ

夏休みに何か始めて気がついたら年末になっているという状況には[前にも陥った]({{ site.baseurl }}{% post_url 2004-12-18-post %})記憶があるのですが, 考えてみれば毎年こういうことを繰り返した挙句に除夜の鐘を聞いているわけで, このまま何の進歩もなく老いさらばえていくのかと半ばあきらめに似た感情を抱くとともに, 人生の悲哀を感じている今日この頃です.

## ところで, 毎年同じことをしているといえば, 我が家では[大晦日に焼肉とそばを食べ]({{ site.baseurl }}{% post_url 2005-01-07-post %}), 元旦にカレーを食べることが恒例となっているのですが, 知り合いには「それは正月の過ごし方として間違っている」と指摘されました. 別にいいじゃんと思っていたのですが, 先日通勤途中でこういうのぼりを見かけました.

![正月用カレー]({{ site.baseurl }}/assets/images/curry.jpg)

## 正月にカレーを食べることは, 正式な日本の風習として認められています.

## 宇宙は美しい

ということで, 研究室の学生さん向け「[夏休みゼミ]({{ site.baseurl }}{% post_url 2009-08-21-post %})」の続編の「冬休みゼミ」です. 私からのクリスマスプレゼントです. ありがたくないですかそうですかどうもすみません.
先日, 某所で[国立天文台](http://www.nao.ac.jp/)の [Mitaka](http://4d2u.nao.ac.jp/html/program/mitaka/) というソフトウェアを見せていただき, その美しさに魅了されて自分も点をいっぱい描いてみたくなりました. 大量の点でアニメーションするには, CPU による座標値の更新をできるだけ控えて, GPU (バーテックスシェーダ) で座標値の更新を行った方がよいようです. 確かに, この方が描画性能を上げやすい (少なくともビデオカードの性能を出しやすい) と予想されます.
CPU に頼らずバーテックスシェーダで座標値を逐次更新するには, 現在の座標値を GPU 側に保持しておく必要があります. これは [Transform Feedback](http://www.opengl.org/registry/specs/NV/transform_feedback.txt) を使ってバーテックスシェーダでの計算結果をバッファオブジェクトに格納すれば実現できますが, ここでは座標を時間をパラーメータとする関数で表すことにします (腰砕けで悪いけど Transform Feedback もそのうち使ってみます). 以後, 以下の雛形をもとに解説します.

<ul>
<li>[Linux 版](winter/winter01.tar.gz)</li>
<li>[Mac OS X 版](winter/winter01.zip)</li>
<li>[Windows 版](winter/winter01.lzh)</li>
</ul>

## 点で円柱を描く

とりあえず点をいっぱい描くプログラムを作ってみます. CPU から GPU への座標値 (頂点情報, `attribute`) の転送には, 夏休みゼミでやった[頂点バッファオブジェクト]({{ site.baseurl }}{% post_url 2009-08-28-post %})を使います. バッファオブジェクトをプログラムのメモリ空間にマップし, そこに乱数で決定した座標値を格納します. 点を円柱状に散布 (撒布) するには, 一様乱数 <i>u</i> を用いて円柱座標系の座標値 (<i>r</i>, <i>θ</i>, <i>h</i>) を発生し, それを直交座標系 (<i>x</i>, <i>y</i>, <i>z</i>) に変換します.

![円柱座標系から直交座標系への変換]({{ site.baseurl }}/assets/images/figure01.gif)

## ただし, このままだと点の密度が中心からの距離 <i>r</i> に反比例して下がってしまうので, <i>r</i> として一様乱数 <i>u</i> の代わりに 2<i>u</i> の平方根を用います. これは <i>r</i> に比例した分布を持つ乱数になります.

![円柱状に一様に点を発生]({{ site.baseurl }}/assets/images/figure02.gif)

## これにより, <i>u</i> が区間 [0, 1] に一様に分布する乱数であれば, 半径 1, 高さ 1 の円柱状の空間に点が散布されます.

<blockquote>
確率密度関数 <i>f</i>(<i>x</i>) に従う分布を持つ乱数を発生するには, <i>f</i>(<i>x</i>) の累積分布関数,

![累積分布関数]({{ site.baseurl }}/assets/images/figure03.gif)

## の逆関数 <i>F</i><sup>-1</sup>(<i>x</i>) の引数に一様乱数 <i>u</i> を与えます. この方法は<`em`>逆関数法と呼ばれます. <i>f</i>(<i>x</i>) = <i>x</i> なら,

![f(x) = x の累積分布関数の逆関数]({{ site.baseurl }}/assets/images/figure04.gif)

## また球状に散布する場合は, <i>f</i>(<i>x</i>) = <i>x</i><sup>2</sup> なので,

![f(x) = x^2 の累積分布関数の逆関数]({{ site.baseurl }}/assets/images/figure05.gif)

## となります.

</blockquote>

```c
...

/* 頂点バッファオブジェクトのメモリを参照するポインタのデータ型 */

typedef GLfloat Point[3];

/*
** 点を空間に散布する
*/
GLuint disseminate(int points, const GLuint *buffer)
{
/* 頂点バッファオブジェクトを有効にする */
glBindBuffer(GL_ARRAY_BUFFER, buffer[0]);

/* 頂点バッファオブジェクトにメモリ領域を確保する */

glBufferData(GL_ARRAY_BUFFER, sizeof (Point) * points, NULL, GL_STATIC_DRAW);

/* 頂点バッファオブジェクトのメモリをプログラムのメモリ空間にマップする */

Point *point = (Point *)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

/* 頂点の位置 */

for (int i = 0; i < points; ++i) {
float r = sqrt(2.0f * (float)rand() / ((float)RAND_MAX + 1.0f));
float t = 6.283185f * (float)rand() / ((float)RAND_MAX + 1.0f);
(*point)[0] = r * cos(t);
(*point)[1] = r * sin(t);
(*point)[2] = (float)rand() / ((float)RAND_MAX + 1.0f);
++point;
}

/* 頂点バッファオブジェクトのメモリをプログラムのメモリ空間から切り離す */

glUnmapBuffer(GL_ARRAY_BUFFER);

/* 頂点バッファオブジェクトを解放する */

glBindBuffer(GL_ARRAY_BUFFER, 0);

return points;

}
```

## 初期化時にこの関数 `disseminate()` を呼び出して頂点バッファオブジェクトに座標値を転送しておき, 描画時に glDrawArrays() によって点を描きます.

![点で描いた円柱]({{ site.baseurl }}/assets/images/winter01.gif)

## 例によって, マウスの左ボタンでドラッグすれば, 図形を回転できます.

## シェーダプログラム

点を打つだけですから, シェーダプログラムは非常に簡単です. バーテックスシェーダでは点の座標値を格納した `attribute` 変数 `point` を座標変換するだけです.

```c
#version 120
//
// simple.vert
//
attribute vec3 point;
uniform mat4 transformMatrix;

void main(void)

{
gl_Position = transformMatrix * vec4(point, 1.0);
}
```

## この個々の点の座標値を時間とともに変化させます. 現在時刻は `uniform` 変数 `elapsedTime` に得ることにします. これを `point` の z 座標値 `point`.z から引いて, 描画する点の位置を変化させます. `point`.z は [0, 1) の区間にありますから, 移動後の位置がこの範囲からはみ出ないように, GLSL の組み込み関数 `fract()` を使って小数点以下のみを取り出します.

```c
#version 120
//
// simple.vert
//
attribute vec3 point;
uniform float elapsedTime;
uniform mat4 transformMatrix;

void main(void)

{
float z = fract(point.z - elapsedTime);
gl_Position = transformMatrix * vec4(point.xy, z, 1.0);
}
```

## フラグメントシェーダではフラグメントに白色を設定するだけです.

```c
#version 120
//
// simple.frag
//

void main(void)

{
gl_FragColor = vec4(1.0);
}
```

## 時間を計る

次に, プログラム実行中の経過時間を求め, シェーダプログラムの `uniform` 変数 `elapsedTime` に格納します. そのために, まず, `uniform` 変数 `elapsedTime` の場所を求め, 変数 `elapsedTimeLocation` に保存しておきます. `elapsedTimeLocation` は後で定義します.

```c
...

/*
** 初期化
*/
static void init(void)
{
...

/* シェーダプログラムのリンク */

glLinkProgram(gl2Program);
glGetProgramiv(gl2Program, GL_LINK_STATUS, &linked);
printProgramInfoLog(gl2Program);
if (linked == GL_FALSE) {
fprintf(stderr, "Link error.\n");
exit(1);
}

/* uniform 変数 elapsedTime の場所を得る */
elapsedTimeLocation = glGetUniformLocation(gl2Program, "elapsedTime");

/* uniform 変数 transformMatrix の場所を得る */

transformMatrixLocation = glGetUniformLocation(gl2Program, "transformMatrix");

...
```

## GLUT では `glutGet(`GLUT_ELAPSED_TIME`)` により経過時間をミリ秒単位で得ることができます. これを関数 `init()` の最後のほうで一度だけ呼び出しておきます.

```c
...

/* トラックボール処理の初期化 */

trackball.initialize();

/* 経過時間の初期化 */
glutGet(GLUT_ELAPSED_TIME);

/* 背景色 */

glClearColor(0.0, 0.1, 0.3, 1.0);
}

...
```

## 描画時に `glutGet(`GLUT_ELAPSED_TIME`)` を呼び出せば, 最初に `glutGet(`GLUT_ELAPSED_TIME`)` を呼び出してからの経過時間を得ることができます. 記号定数 `CYCLE` は変数 `elapsedTime` が 1 増えるのに要する時間で, アニメーションの速度調整に使います. これも後で定義します.

```c
...

/*
** 画面表示
*/
static void display(void)
{
/* 投影変換／ビュー変換／モデル変換 */
Matrix transformMatrix = projectionMatrix * modelviewMatrix * trackball.get();
transformMatrix.scale(1.0f, 1.0f, 2.0f);
transformMatrix.translate(0.0f, 0.0f, -0.5f);

/* シェーダプログラムを適用する */

glUseProgram(gl2Program);

/* 経過時間を求める */
float elapsedTime = (float)glutGet(GLUT_ELAPSED_TIME) / CYCLE;

/* uniform 変数 elapsedTime に時間を設定する */
glUniform1f(elapsedTimeLocation, elapsedTime);

/* uniform 変数 transformMatrix に行列を設定する */

glUniformMatrix4fv(transformMatrixLocation, 1, GL_FALSE, transformMatrix.get());

/* attribute 変数 point に頂点情報を対応付ける */

glEnableVertexAttribArray(pointLocation);

...
```

## 最後に変数 `elapsedTimeLocation` と記号定数 `CYCLE` を定義します. `CYCLE` は 5,000 ミリ秒にしておきます.

```c
...

/*
** 点の数
*/
#define POINTS 100000

/*
** 経過時間
*/
static GLint elapsedTimeLocation;
#define CYCLE 5000.0f

/*
**トラックボール処理
*/
#include "Trackball.h"
static Trackball trackball;
static int pressedButton;

...
```

## こういうアニメーションになります. マウスでぐるぐる回してみてください. 上等なビデオカードを使っている人は, `main`.cpp の最初のほうで定義している記号定数 `POINTS` を 1000000 とか 10000000 とかにして速さを堪能してみてください.

![点のアニメーション]({{ site.baseurl }}/assets/images/winter02.gif)

## 渦を描いてみる

それではバーテックスシェーダを変更して, 下図のような渦を描いてみてください. 点の x 座標値と y 座標値をそれぞれ <i>z</i><sup>2</sup> 倍すれば, この図のように円柱の半径を「絞る」ことができます.

![点で渦のアニメーション]({{ site.baseurl }}/assets/images/winter03.gif)

<ul>
<li>[【解答例】](winter/tornado.`vert`)</li>
</ul>
