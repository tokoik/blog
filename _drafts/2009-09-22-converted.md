---
title: "第１４回 頂点座標の生成"
date: 2009-09-22
categories: [OpenGL,GLSL,ゼミ]
published: true
---

## つゆ

島根県松江市の[マルヤしょうゆ](http://www.yasumoto-kk.jp/shopping/)は美味しいです. ただ, ぽん酢しょうゆとめんつゆの瓶が同じなので, 先日子供がしらす丼にぽん酢しょうゆをかけようとして, 間違えてめんつゆをかけてしまいました. しかし, 食べてみると意外と美味しい! ということで, 結局全部たいらげていました. まあ, そばつゆは天つゆとあんまり変わりませんから, 組み合わせとして不自然ではないと思います. 機会があれば, しらす丼にめんつゆをかけて食べてみてください.

## バーテックスシェーダによる頂点座標の生成

`solidSphere()` では (s, t) を使って頂点の３次元空間中の座標値 (x, y, z) を求めています. (s, t) はテクスチャ座標としてバーテックスシェーダに送っていますので, 同じことはバーテックスシェーダでもできそうです. バーテックスシェーダで頂点の座標値を求めるようにすれば, バーテックスシェーダに頂点の座標値を送る必要もなくなります.
x = `cos` 2πs `sin` πt, y = `cos` πt, z = `sin` 2πs `sin` πt ですから, これをバーテックスシェーダで計算します. `attribute` 変数 `position` を削除して, かわりに `main()` 内に `vec3` 型の変数 `position` を宣言します.

```c
#version 120
//
// simple.vert
//
invariant gl_Position;
attribute vec2 texture;
//attribute vec3 position;
uniform mat4 projectionMatrix;
varying vec3 diffuseColor;
uniform vec3 lightDirection;
uniform vec3 lightColor;
varying vec2 t;

void main(void)

{
float th = 6.283185 * texture.s;
float ph = 3.141593 * texture.t;
float r = sin(ph);
vec3 position = vec3(r * cos(th), cos(ph), r * sin(th));

t = texture * 16.0;

diffuseColor = vec3(dot(lightDirection, position)) * lightColor;
gl_Position = projectionMatrix * vec4(position, 1.0);
}
```

## `attribute` 変数 `position` を削除したので, `solidSphere()` でこれに値を設定している部分を削除します. まず, `Position` 型の要素数を 5 から <strong>2</strong> に減らします.

```c
...

/* 頂点バッファオブジェクトのメモリを参照するポインタのデータ型 */

typedef GLfloat Position[2];
typedef GLuint Edge[2];
typedef GLuint Face[3];

...
```

## `solidSphere()` では, 頂点位置を計算している部分を削除します. また s と t を, それぞれ (*`position`)[<strong>0</strong>] と (*`position`)[<strong>1</strong>] に代入します.

```c
GLuint solidSphere(int slices, int stacks, const GLuint *buffer)
{
...

/* 頂点の位置 */

for (int j = 0; j //float ph = 3.141593f * t;
//float y = cosf(ph);
//float r = sinf(ph);

for (int i = 0; i //float th = 2.0f * 3.141593f * s;
//float x = r * cosf(th);
//float z = r * sinf(th);

//(*position)[0] = x;
//(*position)[1] = y;
//(*position)[2] = z;
(*position)[0] = s;
(*position)[1] = t;
++position;
}
}

...
```

## `attribute` 変数 `position` がなくなったので, メインプログラムでも初期化を行う関数 `init()` において `attribute` 変数 `position` の `index` に 0 を指定している部分を削除します. かわりに, `attribute` 変数 `texture` の `index` に <strong>0</strong> を指定します.

```c
...

/*
** 初期化
*/
static void init(void)
{
...

/* attribute 変数 position の index を 0 に指定する */
//glBindAttribLocation(gl2Program, 0, "position");

/* attribute 変数 texture の index を 0 に指定する */

glBindAttribLocation(gl2Program, 0, "texture");

...
```

## `index` が 1 の `attribute` 変数は使わなくなったので, これを指定している部分を削除します. また, 頂点バッファオブジェクトには `vec2` 型 (`GLfloat` ２個組) のテクスチャ座標しか入っていないので, [`glVertexAttribPointer()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glVertexAttribPointer.xhtml) の第２引数 size には <strong>2</strong> を指定し, 第５引数 stride には <strong>0</strong> を指定します.

```c
...

/*
** 画面表示
*/
static void display(void)
{
...

/* index が 0 ... の attribute 変数に頂点情報を対応付ける */

glEnableVertexAttribArray(0);
//glEnableVertexAttribArray(1);

/* 頂点バッファオブジェクトとして buffer[0] を指定する */

glBindBuffer(GL_ARRAY_BUFFER, buffer[0]);

/* 頂点情報の格納場所と書式を指定する */

glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 0, 0);
//glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, (GLfloat) * 5, (GLfloat *)0 + 3);

/* 頂点バッファオブジェクトの指標として buffer[1] を指定する */

glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer[1]);

/* 図形を描く */

glDrawElements(GL_TRIANGLES, points, GL_UNSIGNED_INT, 0);

/* 頂点バッファオブジェクトを解放する */

glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
glBindBuffer(GL_ARRAY_BUFFER, 0);

/* index が ... 0 の attribute 変数の頂点情報との対応付けを解除する */

//glDisableVertexAttribArray(1);
glDisableVertexAttribArray(0);

/* 隠面消去処理を無効にする */

glDisable(GL_DEPTH_TEST);

glFlush();

}

...
```

## これでも前と同じ図形が描かれるはずです. なお, 以下のファイルでは使っていない関数を削除するなど, 若干整理しています. 

<ul>
<li>[Linux 版](summer/summer11.tar.gz)</li>
<li>[Mac OS X 版](summer/summer11.zip)</li>
<li>[Windows 版](summer/summer11.lzh)</li>
</ul>

## バーテックスシェーダを切り替えて形を変える

バーテックスシェーダで頂点の座標値を求めてしまうと, `solidSphere()` はテクスチャ座標と頂点のつながり情報 (三角形のデータ) だけを生成することになり, 球という形を決める処理を行いません. また, バーテックスシェーダでテクスチャ座標から頂点の座標値を求める方法を変更すれば, 描画する図形の形を変えることができます.
それではバーテックスシェーダを変更して, y 軸中心に半径 1, 上面の高さ y = 1, 底面の高さ y = -1 の円柱を描いてください. 円柱では, 球のように頂点位置をそのまま法線ベクトルに使うことができないことに注意してください.

![バーテックスシェーダを変更して作成した円柱]({{ site.baseurl }}/assets/images/texture06_result.jpg)

<ul>
<li>[【解答例】](summer/cylinder.txt)</li>
</ul>
