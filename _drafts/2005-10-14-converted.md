---
title: "第４回 GLSL によるバンプマッピング"
date: 2005-10-14
categories: [OpenGL,GLSL]
published: true
---

## バンプマッピングを `GLSL` で実装してみる

`GLSL` を使ったバンプマッピングの実装例は<%= a "オレンジブック" %>にありますが，ここではこれを参考に，以前に書いた [`dot`3 バンプマッピング]({% post-url 2005-08-26-post %})を使って[球にバンプマッピング]({% post-url 2005-08-31-post %})するサンプルプログラムを，`GLSL` を使って書き直してみようと思います．

## `GLSL` で書くと楽かもー

<p>[以前]({% post-url 2005-08-26-post %})に「`dot`3 バンプマッピングは面倒」とか書いてましたけど，`GLSL` ではこれをかなり簡単に実装できます．特に，接空間における光線ベクトルの算出をバーテックスシェーダ内に実装できるため，モデルの描画に光源を関わらせずにすみ，アプリケーションプログラムはかなりすっきりとしたものになります．ここでは[球にバンプマッピング]({% post-url 2005-08-31-post %})するサンプルプログラムから，バンプマッピングに関する処理を取り除いたものを雛形にします．</p>

<ul>
<li>[第４版ソースファイル](`glsl`/glsl4.zip)</li>
</ul>

## このプログラムは高さマップ dotbump.raw から作成した法線マップを，そのままテクスチャとして球に貼り付けたものを表示します．材質には赤色を設定していますが，テクスチャ環境を `GL_REPLACE` に設定しているので，法線マップがそのまま色として貼り付けられます．

![法線マップをそのまま色のテクスチャとして貼り付けた球]({{ '/assets/images/glsl16.jpg' | relative_url }})

## シェーダプログラムの読み込み

ファイル `main`.cpp に，シェーダプログラムを読み込む手続きを追加します．これは[第１回]({% post-url 2005-10-06-post %})と同様です．まず `glsl`.h を #`include` して，シェーダオブジェクトのハンドルに使う変数を宣言します．

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
#  define GL_GLEXT_PROTOTYPES
#  include <GL/glut.h>
#endif

#include "normalmap.h"

#include "glsl.h"

/*
** シェーダオブジェクト
*/
static GLuint vertShader;
static GLuint fragShader;
static GLuint gl2Program;
```

## そして，初期化の際にシェーダプログラムの読み込みを行います．

```c
...

/*
** 初期化
*/
static void init(void)
{
/* 法線マップを格納する配列 */
GLubyte texture[TEXHEIGHT * TEXWIDTH * 4];
/* シェーダプログラムのコンパイル／リンク結果を得る変数 */
GLint compiled, linked;

．．．

/* 光源の初期設定 */

glEnable(GL_LIGHTING);
glEnable(GL_LIGHT0);
glLightfv(GL_LIGHT0, GL_DIFFUSE, lightcol);
glLightfv(GL_LIGHT0, GL_SPECULAR, lightcol);
glLightfv(GL_LIGHT0, GL_AMBIENT, lightamb);
glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER, GL_TRUE);

/* GLSL の初期化 */
if (glslInit()) exit(1);

/* シェーダオブジェクトの作成 */
vertShader = glCreateShader(GL_VERTEX_SHADER);
fragShader = glCreateShader(GL_FRAGMENT_SHADER);

/* シェーダのソースプログラムの読み込み */
if (readShaderSource(vertShader, "bump.vert")) exit(1);
if (readShaderSource(fragShader, "bump.frag")) exit(1);

/* バーテックスシェーダのソースプログラムのコンパイル */
glCompileShader(vertShader);
glGetShaderiv(vertShader, GL_COMPILE_STATUS, &compiled);
printShaderInfoLog(vertShader);
if (compiled == GL_FALSE) {
fprintf(stderr, "Compile error in vertex shader.\n");
exit(1);
}

/* フラグメントシェーダのソースプログラムのコンパイル */
glCompileShader(fragShader);
glGetShaderiv(fragShader, GL_COMPILE_STATUS, &compiled);
printShaderInfoLog(fragShader);
if (compiled == GL_FALSE) {
fprintf(stderr, "Compile error in fragment shader.\n");
exit(1);
}

/* プログラムオブジェクトの作成 */
gl2Program = glCreateProgram();

/* シェーダオブジェクトのシェーダプログラムへの登録 */
glAttachShader(gl2Program, vertShader);
glAttachShader(gl2Program, fragShader);

/* シェーダオブジェクトの削除 */
glDeleteShader(vertShader);
glDeleteShader(fragShader);

/* シェーダプログラムのリンク */
glLinkProgram(gl2Program);
glGetProgramiv(gl2Program, GL_LINK_STATUS, &linked);
printProgramInfoLog(gl2Program);
if (linked == GL_FALSE) {
fprintf(stderr, "Link error.\n");
exit(1);
}

/* シェーダプログラムの適用 */
glUseProgram(gl2Program);

/* テクスチャユニット０を指定する */
glUniform1i(glGetUniformLocation(gl2Program, "texture"), 0);
}
```

## ここでバーテックスシェーダ (`bump`.`vert`) とフラグメントシェーダ (`bump`.`frag`）に[第３回]({% post-url 2005-10-08-post %})で作成したテクスチャの参照を行うものをそのまま用いれば，この球にテクスチャを貼った状態で陰影を付けることができます．

```c
// bump.vert

varying vec4 position;

varying vec3 normal;

void main(void)

{
position = gl_ModelViewMatrix * gl_Vertex;
normal = normalize(gl_NormalMatrix * gl_Normal);

gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;

gl_Position = ftransform();
}
```

```c
// bump.frag

uniform sampler2D texture;

varying vec3 position;

varying vec3 normal;

void main (void)

{
vec4 color = texture2DProj(texture, gl_TexCoord[0]);
vec3 light = normalize((gl_LightSource[0].position * position.w - gl_LightSource[0].position.w * position).xyz);
vec3 fnormal = normalize(normal)
float diffuse = max(dot(light, fnormal), 0.0);

vec3 view = -normalize(position.xyz);

vec3 halfway = normalize(light + view);
float specular = pow(max(dot(fnormal, halfway), 0.0), gl_FrontMaterial.shininess);
gl_FragColor = color * (gl_LightSource[0].diffuse * diffuse + gl_LightSource[0].ambient)
+ gl_FrontLightProduct[0].specular * specular;
}
```

## ちゃんとハイライトも付いています．

![法線マップをそのまま色のテクスチャとして貼り付けて陰影をつけた球]({{ '/assets/images/glsl17.jpg' | relative_url }})

## 球の描画手続きの変更

ファイル `sphere`.cpp で定義している球の描画手続きにも，若干の変更を加えます．頂点位置を設定する際に，法線マップのテクスチャ座標や法線ベクトルに加えて，接線ベクトルも設定します．
まず，法線ベクトルから接線ベクトルを算出する手続き `setTangent`() を定義します．接線ベクトルは，球の上方向のベクトル (0, 1, 0) と法線ベクトルとの外積により求めることにします．これをバーテックスシェーダで算出することもできますが，この算出方法は球のモデルに依存していますから，シェーダプログラムに汎用性を持たせるために，接線ベクトルの算出手続きを球の描画手続きとセットにしておくことにします．

```c
#include <math.h>

#if defined(WIN32)

#  include "glut.h"
#  include "glext.h"
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  define GL_GLEXT_PROTOTYPES
#  include <GL/glut.h>
#endif

#include "sphere.h"

#include "glsl.h"

#define PI 3.14159265358979323846

/*
** ローカル座標系から n を法線ベクトルとする接線ベクトル t を求める
*/
static void setTangent(const double n[3], GLint tangent)
{
double l = n[0] * n[0] + n[2] * n[2];
double t[3];

/* 接線ベクトル = (0, 1, 0) × n */

if (l > 0) {
double a = sqrt(l);

t[0] = n[2] / a;

t[1] = 0.0;
t[2] = -n[0] / a;
}
else {
t[0] = t[1] = t[2] = 0.0;
}

glVertexAttrib3dv(tangent, t);

}
```

## 求めた接線ベクトル t は，[`glVertexAttrib3dv()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glVertexAttrib3dv.xhtml) を使って `attribute` 変数としてバーテックスシェーダに渡します．この `attribute` 変数のハンドル `tangent` は，後で `main`.cpp で設定します．

次に，この関数 `setTangent`() を，球の描画において頂点位置を設定している部分に追加します．

```c
/*
** 球の描画
*/
void sphere(double radius, int slices, int stacks, GLint tangent)
{
/* 球を描く */
for (int j = 0; j /* 接線ベクトルを設定する */
setTangent(n[0], tangent);

/* 頂点位置 */

glVertex3dv(p[0]);

/* 法線マップのテクスチャ座標を設定する */

glTexCoord2d(s, t1);

/* 法線ベクトルを設定する */

glNormal3dv(n[1]);

/* 接線ベクトルを設定する */
setTangent(n[1], tangent);

/* 頂点位置 */

glVertex3dv(p[1]);
}
glEnd();
}
}
```

## なお，もし接線ベクトルの算出をバーテックスシェーダで行うなら，図形の描画手続きにまったく手を加える必要はありません．

## `attribute` 変数のハンドル

接線ベクトルの設定に用いている `attribute` 変数のハンドルを保存する変数を用意します．

```c
...

/*
** シェーダオブジェクト
*/
static GLuint vertShader;
static GLuint fragShader;
static GLuint gl2Program;

/*
** 接線ベクトルを格納する attribute 変数のハンドル
*/
GLint tangent;
```

## シェーダプログラムオブジェクト `gl2Program` から，`attribute` 変数 `tangent` のハンドルを取り出して，この変数に保存しておきます．

```c
...

/*
** 初期化
*/
static void init(void)
{
...

/* シェーダプログラムの適用 */

glUseProgram(gl2Program);

/* テクスチャユニット０を指定する */

glUniform1i(glGetUniformLocation(gl2Program, "texture"), 0);

/* 接線ベクトルを渡すために使う attribute 変数のハンドルを得る */
tangent = glGetAttribLocation(gl2Program, "tangent");
}
```

## 球を描画する関数  `sphere`() の引数にこのハンドルを渡します．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
static const GLfloat diffuse[] = { 0.6f, 0.1f, 0.1f, 1.0f };
static const GLfloat specular[] = { 0.3f, 0.3f, 0.3f, 1.0f };

/* 材質の設定 */

glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, diffuse);
glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specular);
glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 100.0f);

/* 球を描く */

sphere(1.0, 64, 32, tangent);
}
```

## これによりバーテックスシェーダ内で `tangent` という `attribute` 変数を参照できます．

## バーテックスシェーダの変更

<p>[第２回]({% post-url 2005-10-07-post %})で作成した Phong の陰影付けのシェーダプログラムでは，陰影計算を視点座標系で行うために，オブジェクト表面上の点の位置 `position` と，その点における法線ベクトル `normal` を `varying` 変数にしてバーテックスシェーダからフラグメントシェーダに送っていました．バンプマッピングでは接空間において陰影計算を行わなければならないため，代わりに接空間における光線ベクトル `light` と視線ベクトル `view` を `varying` 変数にします．</p>

```c
// bump.vert

attribute vec3 tangent;

varying vec3 light;
varying vec3 view;
```

## まず，視点座標系における視線ベクトルと光線ベクトルを求めます．

```c
void main()
{
// 位置ベクトルと光線ベクトルを求める
vec4 p = gl_ModelViewMatrix * gl_Vertex;
vec3 l = normalize((gl_LightSource[0].position * p.w - gl_LightSource[0].position.w * p).xyz);
```

## 同様に，視点座標系における法線ベクトル $\mathbf{n}$ と接線ベクトル $\mathbf{t}$ を求めます．次に，これらの外積により従法線ベクトル $\mathbf{b}$ を求めておきます．そして，これらを使って視点座標系から接空間への変換を行います．下のプログラムでは `GLSL` の組み込み関数を `dot`() を用いて，($\mathbf{t}$<sup><i>T</i></sup> $\mathbf{b}$<sup><i>T</i></sup> $\mathbf{n}$<sup><i>T</i></sup>) による変換を行っています．

```c
// 法線ベクトルと接線ベクトルから接空間への変換行列を求める
vec3 n = normalize(gl_NormalMatrix * gl_Normal);
vec3 t = normalize(gl_NormalMatrix * tangent);
vec3 b = cross(n, t);

vec3 temp;

// 接空間における視線ベクトルを求める
temp.x = dot(p.xyz, t);
temp.y = dot(p.xyz, b);
temp.z = dot(p.xyz, n);
view = -normalize(temp);

// 接空間における光線ベクトルを求める
temp.x = dot(l, t);
temp.y = dot(l, b);
temp.z = dot(l, n);
light = normalize(temp);

// テクスチャ座標と頂点座標を出力する

gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
gl_Position = ftransform();
}
```

## フラグメントシェーダの変更

フラグメントシェーダの変更点のポイントは，法線ベクトルをテクスチャから取り出してくることと，その法線ベクトルを使った陰影計算を接空間の座標系で行うところにあります．したがってこの陰影計算には，視点座標系の位置 `position` や法線ベクトル `normal` の代わりに，バーテックスシェーダで計算した接空間における光線ベクトル `light` と視線ベクトル `view` を用います．

```c
// bump.frag

uniform sampler2D texture;

varying vec3 light;
varying vec3 view;
```

## テクスチャは法線マップなので，これをサンプリングした値 `color` を用いてフラグメントの法線ベクトル `fnormal` を求めます．法線マップに格納されている法線ベクトルの各要素の値は [0,1] に収められているので，これを [-1,1] に引き伸ばします．光線ベクトル `light` は `varying` 変数で得ているので，ここで計算する必要はありません．その代わり，`varying` 変数の `light` を正規化して `flight` としておきます．`diffuse` は `flight` と `fnormal` の内積で求めます．

```c
void main (void)
{
vec4 color = texture2DProj(texture, gl_TexCoord[0]);
vec3 fnormal = vec3(color) * 2.0 - 1.0;
vec3 flight = normalize(light);
float diffuse = max(dot(flight, fnormal), 0.0);
```

## 視線ベクトル `view` も `varying` 変数として得ていますから，これを正規化して `fview` としておきます．中間ベクトル `halfway` は `flight` と `fview` の逆ベクトルの和から求めます．拡散反射係数には材質として設定したものを用いるので，それと光源強度の拡散反射成分との積 `gl_FrontLightProduct`[0].`diffuse` を使って拡散反射光強度を求めます．これに材質として設定した環境光の反射係数と環境光強度の積 `gl_FrontLightProduct`[0].`ambient` と鏡面反射光強度 `specular` を加えて，`gl_FragColor` に代入します．

```c
vec3 fview = normalize(view);
vec3 halfway = normalize(flight + fview);
float specular = pow(max(dot(fnormal, halfway), 0.0), gl_FrontMaterial.shininess);
gl_FragColor = gl_FrontLightProduct[0].diffuse * diffuse + gl_FrontLightProduct[0].ambient
+ gl_FrontLightProduct[0].specular * specular;
}
```

![シェーダプログラムを使って球にバンプマッピング]({{ '/assets/images/glsl18.jpg' | relative_url }})

## 接線ベクトルをバーテックスシェーダ内ででっち上げてやれば，ティーポットにバンプマッピングするなんてこともできなくはありません．ただし glutSolidTeapot() は面の表裏が反転しているので，凹凸も逆になってしまいます．

![シェーダプログラムを使ってティーポットにバンプマッピング]({{ '/assets/images/glsl21.jpg' | relative_url }})
