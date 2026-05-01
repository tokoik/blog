---
title: "Transform Feedback"
date: 2011-08-18
categories: [OpenGL,メモ]
published: true
---

## Lion

Mac OS X Lion では OpenGL のバージョン 3.2 が使えるものの，それは lagacy な API を削除した core profile なんですね．そのため後方互換性が必要な場合は，バージョン 3.2 の compatibility profile ではなく，「legacy なバージョン」を使うようにピクセルフォーマット属性を設定するんですね．だから legacy な API を使っている GLUT は，この「legacy なバージョン」すなわちバージョン 2.1 以前を使うようにピクセルフォーマット属性を設定していて，バージョン 3.2 に切り替える方法は（official には）提供されていないんですね．うーん，さてどうしよう．誰か core profile で動く GLUT を作らんかな．

## `Transform` `Feedback`

`Transform` `Feedback` はバーテックスシェーダやジオメトリシェーダでの計算結果を，CPU を介さずに頂点バッファオブジェクト (Vertex Buffer Object, VBO) に格納する機能です．頂点バッファオブジェクトの内容はバーテックスシェーダに入力する頂点属性 (`attribute`) として使えますから，この機能により頂点属性を GPU 単独で更新することができるようになります．したがって，これまで頂点属性の計算に要していた CPU の計算負荷の多くを GPU に委譲できるほか，CPU から GPU へのデータの転送量を大幅に削減できます．また，ラスタライザを起動しないようにすれば，GPU を数値計算に専念させることもできます．
んで，これは[以前]({{ site.baseurl }}{% post_url 2009-12-25-post %})からやらなきゃと思いつつ放置していたのですが，ちょっとやりたいことがあったので，使い方をメモっておこうと思います．`Transform` `Feedback` は OpenGL のバージョン 3.0 から標準機能になりました．ところが，前述のとおり Mac OS X では Lion でも GLUT を使っている限り 2.1 以前になってしまいます．仕方がないので，Mac OS X では[拡張機能](http://www.opengl.org/registry/specs/EXT/transform_feedback.txt)として使うことにします．

## 頂点バッファオブジェクト

描画する図形は[以前]({{ site.baseurl }}{% post_url 2009-12-25-post %})と同様に点 (`GL_POINTS`) にします．頂点バッファオブジェクトを作成し，それに点の位置の初期値を設定します．点の位置の初期値は乱数により決定します．この<`em`>初期値は CPU 側からは変更することがないので，[`glBufferData()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBufferData.xhtml) の第 4 引数 usage は `GL_STATIC_DRAW` でいいんじゃないかと思います．

```c
...

/*
** 点の数
*/
#define POINTS 100000

/*
** シェーダ
*/
#include "shader.h"
static GLuint shader;

/*
** 変換行列
*/
#include "Matrix.h"
static Matrix projectionMatrix;
static Matrix modelviewMatrix;
static GLint transformMatrixLocation;

/*
** 頂点属性
*/
static GLuint buffer[1];
static GLint pointLocation;

...

/*
** 初期化
*/
static void init(void)
{
...

// シェーダーのソースファイルの読み込み

shader = loadShader("simple.vert", "simple.frag");

// uniform 変数 transformMatrix の場所の取得

transformMatrixLocation = glGetUniformLocation(shader, "transformMatrix");

// attribute 変数 point の場所の取得

pointLocation = glGetAttribLocation(shader, "point");

// ビュー変換行列の設定

modelviewMatrix.loadLookat(0.0f, 0.0f, 5.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);

// 頂点バッファオブジェクトの作成

glGenBuffers(sizeof buffer / sizeof buffer[0], buffer);

// 一つ目の頂点バッファオブジェクト

glBindBuffer(GL_ARRAY_BUFFER, buffer[0]);

// 一つ目の頂点バッファオブジェクトのメモリを確保

glBufferData(GL_ARRAY_BUFFER, sizeof (GLfloat[3]) * POINTS, 0, GL_STATIC_DRAW);

// 一つ目の頂点バッファオブジェクトのメモリをプログラムのメモリ空間にマップ

GLfloat (*point)[3] = (GLfloat (*)[3])glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

// 頂点の初期位置の設定

for (int i = 0; i < POINTS; ++i) {
point[i][0] = 2.0f * (float)rand() / (float)RAND_MAX - 1.0f;
point[i][1] = 2.0f * (float)rand() / (float)RAND_MAX - 1.0f;
point[i][2] = 2.0f * (float)rand() / (float)RAND_MAX - 1.0f;
}

// 一つ目の頂点バッファオブジェクトのメモリをプログラムのメモリ空間からアンマップ

glUnmapBuffer(GL_ARRAY_BUFFER);

// 頂点バッファオブジェクトの指定の解除

glBindBuffer(GL_ARRAY_BUFFER, 0);

...

}
```

## 点 (`GL_POINT`) の描画

頂点バッファオブジェクトに格納された頂点属性（座標値）を使って，[`glDrawArrays()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glDrawArrays.xhtml) により点を描画します．

```c
...

/*
** 画面表示
*/
static void display(void)
{
...

// 画面クリア

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// シェーダプログラムの適用

glUseProgram(shader);

// uniform 変数 transformMatrix に変換行列を設定

Matrix transformMatrix = projectionMatrix * modelviewMatrix * trackball.get();
glUniformMatrix4fv(transformMatrixLocation, 1, GL_FALSE, transformMatrix.get());

// attribute 変数 point に頂点属性を設定

glEnableVertexAttribArray(pointLocation);

// 一つ目の頂点バッファオブジェクトを指定

glBindBuffer(GL_ARRAY_BUFFER, buffer[0]);

// 頂点属性の格納場所と書式を指定

glVertexAttribPointer(pointLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

// 図形の描画

glDrawArrays(GL_POINTS, 0, POINTS);

// 頂点バッファオブジェクトの指定の解除

glBindBuffer(GL_ARRAY_BUFFER, 0);

// attribute 変数 point の頂点属性の設定を解除

glDisableVertexAttribArray(pointLocation);

// シェーダプログラムの指定の解除

glUseProgram(0);

// ダブルバッファリング

glutSwapBuffers();
}
```

## バーテックスシェーダプログラムでは `attribute` 変数 `point` に与えられた座標値を座標変換して `gl_Position` に代入します．ここで `point` のデータ型を `vec4` にしても構いません．その場合 `point` の w 要素には 1.0 が入っているみたいなので，`transformMatrix` を乗じる際に `vec4` にキャストする必要はありません．

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
```

## フラグメントシェーダでは，フラグメントカラーに白色を設定します．

```c
#version 120
//
// simple.frag
//

void main(void)

{
gl_FragColor = vec4(1.0);
```

## これで次のような図形が表示されたとします．

![`GL_POINTS` による図形表示]({{ site.baseurl }}/assets/images/tfb0.gif)

## 二つ目の頂点バッファオブジェクト

`Transform` `Feedback` による計算結果の格納先として，頂点バッファオブジェクトをもう一つ用意します．この [`glBufferData()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBufferData.xhtml) の第 4 引数 usage に何を指定すればいいのかよくわからないのですが（調べ方が足りない），とりあえず `GL_STATIC_DRAW` を指定しています．もしかしたら `GL_STREAM_COPY` か `GL_DYNAMIC_COPY` を指定すべきなのかもしれません．

```c
...

/*
** 頂点属性
*/
static GLuint buffer[2];
static GLint pointLocation;

...

/*
** 初期化
*/
static void init(void)
{
...

// 一つ目の頂点バッファオブジェクトのメモリをプログラムのメモリ空間からアンマップ

glUnmapBuffer(GL_ARRAY_BUFFER);

// 二つ目の頂点バッファオブジェクト
glBindBuffer(GL_ARRAY_BUFFER, buffer[1]);

// 二つ目の頂点バッファオブジェクトのメモリを確保
glBufferData(GL_ARRAY_BUFFER, sizeof (GLfloat[3]) * POINTS, 0, GL_STATIC_DRAW);

// 頂点バッファオブジェクトの指定の解除

glBindBuffer(GL_ARRAY_BUFFER, 0);

...

}
```

## 頂点バッファオブジェクトへのデータの格納

シェーダプログラムによる計算結果の格納先となる頂点バッファオブジェクトの指定には [`glBindBufferBase()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBindBufferBase.xhtml) を使用します．この第 1 引数 target には，`Transform` `Feedback` の場合は `GL_TRANSFORM_FEEDBACK_BUFFER` を指定します．第 2 引数 index には格納先として使用する<`em`>結合点の配列の要素のインデックス（後述）を指定します．第 3 引数 `buffer` には格納先の頂点バッファオブジェクトを指定します．その後 [`glBeginTransformFeedback()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBeginTransformFeedback.xhtml) で `Transform` `Feedback` を開始します．この引数 primitiveMode には，描画する図形要素が点 (`GL_POINTS`) なら `GL_POINTS`, 線 (`GL_LINES`, `GL_LINE_LOOP`, `GL_LINE_STRIP`, `GL_LINES_ADJACENCY`, `GL_LINE_STRIP_ADJACENCY`) なら `GL_LINES`，三角形 (`GL_TRIANGLES`, `GL_TRIANGLE_STRIP`, `GL_TRIANGLE_FAN`, `GL_TRIANGLES_ADJACENCY`, `GL_TRIANGLE_STRIP_ADJACENCY`) なら `GL_TRIANGLES` を指定します．ジオメトリシェーダを使用する場合も，これに準じます．
二つの頂点バッファオブジェクトは，一方を描画用に参照しているときは，もう一方をデータの格納用に使用します．そして次のフレームの描画では，この関係を逆転します．このような<`em`>ダブルバッファリングを実現するために，<`em`>静的変数 `frame` を使ってバッファの切り替えを行っています．

```c
...

/*
** 画面表示
*/
static void display(void)
{
static int frame = 0;

...

// 画面クリア

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// シェーダプログラムの適用

glUseProgram(shader);

// uniform 変数 transformMatrix に変換行列を設定

Matrix transformMatrix = projectionMatrix * modelviewMatrix * trackball.get();
glUniformMatrix4fv(transformMatrixLocation, 1, GL_FALSE, transformMatrix.get());

// attribute 変数 point に頂点属性を設定

glEnableVertexAttribArray(pointLocation);

// 一つ目の頂点バッファオブジェクトを指定

glBindBuffer(GL_ARRAY_BUFFER, buffer[frame]);

// 頂点属性の格納場所と書式を指定

glVertexAttribPointer(pointLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

// 二つ目の頂点バッファオブジェクトをターゲットとして指定
glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, buffer[1 - frame]);

// Transform Feedback 開始
glBeginTransformFeedback(GL_POINTS);

// 図形の描画

glDrawArrays(GL_POINTS, 0, POINTS);

// Transform Feedback 終了
glEndTransformFeedback();

// 頂点バッファオブジェクトの指定の解除

glBindBuffer(GL_ARRAY_BUFFER, 0);

// attribute 変数 point の頂点属性の設定を解除

glDisableVertexAttribArray(pointLocation);

// シェーダプログラムの指定の解除

glUseProgram(0);

// 頂点バッファオブジェクトのダブルバッファリング

frame = 1 - frame;

// ダブルバッファリング

glutSwapBuffers();
}
```

## データの格納先の指定

シェーダプログラムでデータの格納先として使用する<`em`>結合点を指定するには，[`glTransformFeedbackVaryings()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTransformFeedbackVaryings.xhtml) を使用します．この結合点には `varying` 変数名を指定します．この第 1 引数 `program` には glCreateShader() で得たプログラム名（番号），第 2 引数 count には結合点として使用する `varying` 変数の数，第 3 引数には `varying` 変数名の文字列の配列を指定します．先の [`glBindBufferBase()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBindBufferBase.xhtml) の第 2 引数 index には，この `varying` 変数名の配列の要素のインデックスを指定します．そして第 4 引数の bufferMode には，複数の頂点属性を単一の頂点バッファオブジェクトにまとめる場合には `GL_INTERLEAVED_ATTRIBS`，別々の頂点バッファオブジェクトに対応付ける場合は `GL_SEPARATE_ATTRIBS` を指定します．
なお，これはシェーダプログラムにおいてバーテックスシェーダあるいはジオメトリシェーダのアタッチ後，[`glLinkProgram()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glLinkProgram.xhtml) によりリンクするまでの間に行わなければならないので，`shader`.cpp で定義している関数 `loadShader()` を変更します．

```c
...

/*
** シェーダーソースファイルの読み込み
*/
GLuint loadShader(const char *vert, const char *frag, const char *geom, GLenum input, GLenum output)
{
...

// feedback に使う varying 変数を指定する
const static char *varyings[] = { "position" };
glTransformFeedbackVaryings(program, sizeof varyings / sizeof varyings[0], varyings, GL_INTERLEAVED_ATTRIBS);  

// シェーダプログラムのリンク

glLinkProgram(program);
glGetProgramiv(program, GL_LINK_STATUS, &linked);
printProgramInfoLog(program);
if (linked == GL_FALSE) {
std::cerr << "Error: Could not link shader program" << std::endl;
return 0;
}

return program;

}
```

## 上記では計算結果の格納先の `varying` 変数として `position` を使用することにしましたので，バーテックスシェーダプログラムにこれを追加します．ここでは現在の点の位置 `point` に 1 フレームごとの移動量 (0.0, -0.01, 0.0) を加えたものを `position` とし，その y が点を描画する範囲を超えたら反対側の位置に戻します．これが次のフレームの描画において `point` として参照されます．

```c
#version 120
//
// simple.vert
//
attribute vec3 point;
uniform mat4 transformMatrix;
varying vec3 position;

void main(void)

{
gl_Position = transformMatrix * vec4(point, 1.0);
position = point + vec3(0.0, -0.01, 0.0);  // 点の位置を移動する
if (position.y < -1.0) position.y += 2.0;  // 範囲を出たら反対側の位置に戻す
```

## 以上で点のアニメーションができると思います．

<ul>
<li>[サンプルプログラム](tfb/tfb.zip)</li>
</ul>

## 加速させる (8 月 19 日追記)

これを書いているうちに，`Transform` `Feedback` を使った良い解説 [Noise-Based Particles, Part II at The Little Grasshopper](http://prideout.net/blog/?p=67) を見つけました．[The Little Grasshopper](http://prideout.net/blog/) には他にも非常に有用な解説やサンプルがあります．素晴らしい．
複数の頂点バッファオブジェクトに書き込む場合について考えます．これは上記のサイトに書いてありますが，自分なりにまとめておきたいと思います．物体を加速させる場合は，加速度を積分して速度を求め，速度を積分して位置を求める必要がありますから，位置のほかに速度も更新する必要があります．このため，頂点バッファオブジェクトをさらに二つ追加します．また，速度は `attribute` 変数 `motion` を介してバーテックスシェーダに渡すことにします．

```c
...

/*
** 頂点属性
*/
static GLuint buffer[4];
static GLint pointLocation;
static GLint motionLocation;

...

/*
** 初期化
*/
static void init(void)
{
...

// シェーダーのソースファイルの読み込み

shader = loadShader("simple.vert", "simple.frag");

// uniform 変数 transformMatrix の場所の取得

transformMatrixLocation = glGetUniformLocation(shader, "transformMatrix");

// attribute 変数 point の場所の取得

pointLocation = glGetAttribLocation(shader, "point");

// attribute 変数 motion の場所の取得
motionLocation = glGetAttribLocation(shader, "motion");

// ビュー変換行列の設定

modelviewMatrix.loadLookat(0.0f, 0.0f, 5.0f, 0.0f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f);

...

// 二つ目の頂点バッファオブジェクト

glBindBuffer(GL_ARRAY_BUFFER, buffer[1]);

// 二つ目の頂点バッファオブジェクトのメモリを確保

glBufferData(GL_ARRAY_BUFFER, sizeof (GLfloat[3]) * POINTS, 0, GL_STATIC_DRAW);

// 三つ目の頂点バッファオブジェクト
glBindBuffer(GL_ARRAY_BUFFER, buffer[2]);

// 三つ目の頂点バッファオブジェクトのメモリを確保
glBufferData(GL_ARRAY_BUFFER, sizeof (GLfloat[3]) * POINTS, 0, GL_STATIC_DRAW);

// 三つ目の頂点バッファオブジェクトのメモリをプログラムのメモリ空間にマップ
GLfloat (*motion)[3] = (GLfloat (*)[3])glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

// 頂点の初速度の設定
for (int i = 0; i < POINTS; ++i) {
motion[i][0] = 0.0f;
motion[i][1] = 0.0f;
motion[i][2] = 0.0f;
}

// 三つ目の頂点バッファオブジェクトのメモリをプログラムのメモリ空間からアンマップ
glUnmapBuffer(GL_ARRAY_BUFFER);

// 四つ目の頂点バッファオブジェクト
glBindBuffer(GL_ARRAY_BUFFER, buffer[3]);

// 四つ目の頂点バッファオブジェクトのメモリを確保
glBufferData(GL_ARRAY_BUFFER, sizeof (GLfloat[3]) * POINTS, 0, GL_STATIC_DRAW);

// 頂点バッファオブジェクトの指定の解除

glBindBuffer(GL_ARRAY_BUFFER, 0);

...

}
```

## 一方，バーテックスシェーダで更新した速度は，`varying` 変数 `velocity` に代入して頂点バッファオブジェクトに格納することにします．このため，`shader`.cpp の `loadShader()` において [`glTransformFeedbackVaryings()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTransformFeedbackVaryings.xhtml) の第 3 引数の配列 `varyings` のターゲットの変数名に `velocity` を追加します．さらに第 4 引数の bufferMode は，ここでは `position` と `velocity` に別々の頂点バッファオブジェクトに対応付けているので，`GL_SEPARATE_ATTRIBS` を指定します．

```c
...

/*
** シェーダーソースファイルの読み込み
*/
GLuint loadShader(const char *vert, const char *frag, const char *geom, GLenum input, GLenum output)
{
...

// feedback に使う varying 変数を指定する

const static char *varyings[] = { "position", "velocity" };
glTransformFeedbackVaryings(program, sizeof varyings / sizeof varyings[0], varyings, GL_SEPARATE_ATTRIBS);

// シェーダプログラムのリンク

glLinkProgram(program);
glGetProgramiv(program, GL_LINK_STATUS, &linked);
printProgramInfoLog(program);
if (linked == GL_FALSE) {
std::cerr << "Error: Could not link shader program" << std::endl;
return 0;
}

return program;

}
```

## 描画の際には三つ目の頂点バッファオブジェクトを `attribute` 変数 `motion` に結び付け，四つ目の頂点バッファオブジェクトを `varying` 変数 `velocity` に対応付けます．[`glBindBufferBase()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glBindBufferBase.xhtml) の第 2 引数 index は `shader`.cpp で定義している `loadShader()` 内の配列変数 `varyings` における文字列 "`velocity`" のインデックスである 1 を指定します．

```c
...

/*
** 画面表示
*/
static void display(void)
{
static int frame = 0;

...

// 画面クリア

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// シェーダプログラムの適用

glUseProgram(shader);

// uniform 変数 transformMatrix に変換行列を設定

Matrix transformMatrix = projectionMatrix * modelviewMatrix * trackball.get();
glUniformMatrix4fv(transformMatrixLocation, 1, GL_FALSE, transformMatrix.get());

// attribute 変数 point に頂点属性を設定

glEnableVertexAttribArray(pointLocation);

// 一つ目の頂点バッファオブジェクトを指定

glBindBuffer(GL_ARRAY_BUFFER, buffer[frame]);

// 頂点属性の格納場所と書式を指定

glVertexAttribPointer(pointLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

// 二つ目の頂点バッファオブジェクトをターゲットとして指定

glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 0, buffer[1 - frame]);

// attribute 変数 motion に頂点属性を設定
glEnableVertexAttribArray(motionLocation);

// 三つ目の頂点バッファオブジェクトを指定
glBindBuffer(GL_ARRAY_BUFFER, buffer[2 + frame]);

// 頂点属性の格納場所と書式を指定
glVertexAttribPointer(motionLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

// 四つ目の頂点バッファオブジェクトをターゲットとして指定
glBindBufferBase(GL_TRANSFORM_FEEDBACK_BUFFER, 1, buffer[3 - frame]);

// Transform Feedback 開始

glBeginTransformFeedback(GL_POINTS);

// 図形の描画

glDrawArrays(GL_POINTS, 0, POINTS);

// Transform Feedback 終了

glEndTransformFeedback();

// 頂点バッファオブジェクトの指定の解除

glBindBuffer(GL_ARRAY_BUFFER, 0);

// attribute 変数 point の頂点属性の設定を解除

glDisableVertexAttribArray(pointLocation);

// シェーダプログラムの指定の解除

glUseProgram(0);

// 頂点バッファオブジェクトのダブルバッファリング

frame = 1 - frame;

// ダブルバッファリング

glutSwapBuffers();
}
```

## バーテックスシェーダでは `attribute` 変数 `motion` と `varying` 変数 `velocity` を追加します．現在の速度 `motion` に加速度を加えたものを `velocity` に代入します．これは次のフレームの描画において `motion` として参照されます．この速度を現在の位置 `point` に加えて `position` に代入します．ただし，この位置が範囲をはみ出た時には反対側に戻すとともに，速度を 0 にします．

```c
#version 120
//
// simple.vert
//
attribute vec3 point, motion;
uniform mat4 transformMatrix;
varying vec3 position, velocity;

void main(void)

{
gl_Position = transformMatrix * vec4(point, 1.0);
velocity = motion + vec3(0.0, -0.0001, 0.0);  // 速度に加速度を加える
position = point + velocity;                  // 点の位置を移動する
if (position.y 
position.y += 2.0;                          // 位置を反対側に戻す
velocity = vec3(0.0, 0.0, 0.0);             // 速度を 0 にする
}
```

## なお，これだとムラのある（ドサッ，ドサッという感じの）動きになってしまいます．これは点の初期位置における初速度をすべて 0 にしているからです．粒子の生成・消滅を考慮するなら，[Noise-Based Particles, Part II at The Little Grasshopper](http://prideout.net/blog/?p=67) でやっているように粒子の発生時刻あるいは生存時間も管理する必要があります．
