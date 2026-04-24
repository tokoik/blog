---
title: "第３回 テクスチャの参照"
date: 2005-10-08
categories: [OpenGL,GLSL]
published: true
---

## 昭和テイスト

研究室のミーティングで学生さんに対して「当たり前田のクラッカー！」っていう具合に突っ込みを入れたら，「昭和テイストだなぁー」とか「世代が違いますよ，世代が」とか散々な言われ方をしました．私，やっぱり旧い人なんでしょうか？（聞くまでもないか）そういえば以前，奥さんに「<`em`>おさじとって」と言ったら，「はい，<`em`>スプーン」と訂正されてしまいました．昭和は遠くなったもんだ（違

## テクスチャを参照する

シェーダプログラムの中でもテクスチャを参照することができます．もちろん，[マルチテクスチャ]({% post_url 2005-06-15-post %})が使えます．複数のテクスチャを組み合わせた処理を<`em`>手続きで書けるってあたりが，シェーダプログラミングの醍醐味でしょう．
とりあえず，[前回]({% post_url 2005-10-07-post %})のプログラムにテクスチャに使う画像を読み込む処理を追加します．テクスチャには，以前に使った[この画像](glsl/dot.`raw`.gz)を使います．なお本題とは関係ありませんが，以下のプログラムでは OpenGL 1.4 で標準機能となったミップマップの自動生成機能を使用しています．

<ul>
<li>[第２版ソースファイル](glsl/glsl2.zip)</li>
</ul>

```c
...

/*
** テクスチャ
*/
#define TEXWIDTH  256                      /* テクスチャの幅　　　 */
#define TEXHEIGHT 256                      /* テクスチャの高さ　　 */
static const char texture1[] = "dot.raw";  /* テクスチャファイル名 */

/*
** 初期化
*/
static void init(void)
{
/* シェーダプログラムのコンパイル／リンク結果を得る変数 */
GLint compiled, linked;

/* テクスチャの読み込みに使う配列 */
GLubyte texture[TEXHEIGHT][TEXWIDTH][4];
FILE *fp;

...

/* シェーダプログラムの適用 */

glUseProgram(gl2Program);

/* テクスチャ画像の読み込み */
if ((fp = fopen(texture1, "rb")) != NULL) {
fread(texture, sizeof texture, 1, fp);
fclose(fp);
}
else {
perror(texture1);
}

/* テクスチャ画像はバイト単位に詰め込まれている */
glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_TRUE);

/* テクスチャを拡大・縮小する方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);

/* テクスチャの繰り返し方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

/* テクスチャの割り当て */
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, TEXWIDTH, TEXHEIGHT, 0,
GL_RGBA, GL_UNSIGNED_BYTE, texture);

/* 初期設定 */

glClearColor(0.3, 0.3, 1.0, 0.0);
glEnable(GL_DEPTH_TEST);
glDisable(GL_CULL_FACE);
```

## 図形描画の際にテクスチャ座標を設定しておきます．シェーダプログラムを使う場合は，`glEnable`(`GL_TEXTURE_2D`); を実行する必要はありません．

```c
...

/*
** シーンの描画
*/
static void scene(void)
{
static const GLfloat diffuse[] = { 0.6, 0.1, 0.1, 1.0 };
static const GLfloat specular[] = { 0.3, 0.3, 0.3, 1.0 };

/* 材質の設定 */

glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE, diffuse);
glMaterialfv(GL_FRONT_AND_BACK, GL_SPECULAR, specular);
glMaterialf(GL_FRONT_AND_BACK, GL_SHININESS, 100.0f);

#if 1

/* １枚の４角形を描く */
glNormal3d(0.0, 0.0, 1.0);
glBegin(GL_QUADS);
glTexCoord2d(0.0, 1.0);
glVertex3d(-1.0, -1.0,  0.0);
glTexCoord2d(1.0, 1.0);
glVertex3d( 1.0, -1.0,  0.0);
glTexCoord2d(1.0, 0.0);
glVertex3d( 1.0,  1.0,  0.0);
glTexCoord2d(0.0, 0.0);
glVertex3d(-1.0,  1.0,  0.0);
glEnd();
#else
glutSolidTeapot(1.0);
#endif
}
```

## これでテクスチャマッピングの準備は完了です．試しに関数 `init`() の最後にある `glUseProgram`(`gl2Program`); をコメントアウトしてプログラムをコンパイル・実行し，テクスチャが正しく貼れるか確かめてください（確かめたらプログラムを元に戻してください）．

```c
/* シェーダプログラムの適用 */
```

## シェーダプログラムの作成

シェーダプログラムは前回作成した Phong シェーディングのものをもとにして作成します．phong.`vert` と phong.`frag` をそれぞれ `texture`.`vert` と `texture`.`frag` というファイル名にコピーしてください．

## バーテックスシェーダ

バーテックスシェーダでは，テクスチャ変換行列 `gl_TextureMatrix`[0] を処理対象の頂点のテクスチャ座標 `gl_MultiTexCoord0` に掛けて，組み込み `varying` 変数 `gl_TexCoord`[0] に代入します．`gl_MultiTexCoord0` はテクスチャユニット０に設定されたテクスチャ座標です．`gl_TexCoord` は配列変数になっていますが，添え字の番号とテクスチャユニットは無関係（ただし総数は同じ）なので，`gl_TexCoord` のどの要素にどのテクスチャユニットのテクスチャ座標を入れても構いません．

```c
// texture.vert

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

## なお，テクスチャ変換行列を使わない場合は，`gl_TextureMatrix`[0] を `gl_MultiTexCoord0` にかける必要はありません．

## フラグメントシェーダ

２次元テクスチャは GLSL の組み込み関数 `texture2DProj`() を使ってサンプリングします．変数 `texture` は `sampler2D` 型の `uniform` 変数で，どのテクスチャユニットからどういう方法でテクスチャをサンプリングするかを指定します．この変数 `texture` の値（すなわちテクスチャユニット番号）の設定は，アプリケーションプログラム側で行います．
以下のプログラムでは，`gl_TexCoord`[0] に格納されているテクスチャ座標をテクスチャ変換行列 `gl_TextureMatrix`[0] により変換し，その結果を使って `texture` で指定されたテクスチャユニットが保持するテクスチャをサンプリングします．そして，サンプリングした色 `color` を使って拡散反射光強度と環境光の反射光強度を計算します．

```c
// texture.frag

uniform sampler2D texture;

varying vec3 position;

varying vec3 normal;

void main (void)

{
vec4 color = texture2DProj(texture, gl_TexCoord[0]);
vec3 light = normalize((gl_LightSource[0].position * position.w - gl_LightSource[0].position.w * position).xyz);
vec3 fnormal = normalize(normal);
float diffuse = max(dot(light, fnormal), 0.0);

vec3 view = -normalize(position.xyz);

vec3 halfway = normalize(light + view);
float specular = pow(max(dot(fnormal, halfway), 0.0), gl_FrontMaterial.shininess);
gl_FragColor = color * gl_LightSource[0].diffuse * diffuse
+ gl_FrontLightProduct[0].specular * specular
+ color * gl_LightSource[0].ambient;
}
```

## もちろん，`gl_LightSource`[0].`diffuse` と `color` * `gl_LightSource`[0].`ambient` は `color` でくくることができます．

```c
// texture.frag

uniform sampler2D texture;

varying vec3 position;

varying vec3 normal;

void main (void)

{
vec4 color = texture2DProj(texture, gl_TexCoord[0]);
vec3 light = normalize((gl_LightSource[0].position * position.w - gl_LightSource[0].position.w * position).xyz);
vec3 fnormal = normalize(normal);
float diffuse = max(dot(light, fnormal), 0.0);

vec3 view = -normalize(position.xyz);

vec3 halfway = normalize(light + view);
float specular = pow(max(dot(fnormal, halfway), 0.0), gl_FrontMaterial.shininess);
gl_FragColor = color * (gl_LightSource[0].diffuse * diffuse + gl_LightSource[0].ambient)
+ gl_FrontLightProduct[0].specular * specular;
}
```

## `uniform` 変数への値の設定

`uniform` 変数の値はアプリケーションプログラムで設定します．これは，まず[`glGetUniformLocation()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glGetUniformLocation.xhtml) 関数を使ってプログラムオブジェクト内から値を設定する `uniform` 変数を探し出し，その識別子を得ます．そして glUniform*() 関数を使って，その識別子に対して値を設定します．ここではフラグメントシェーダプログラムの `texture` という `uniform` 変数に値を設定しますから，次のような手続きになります．

```c
...

/*
** 初期化
*/
static void init(void)
{
...

/* シェーダオブジェクトの作成 */

vertShader = glCreateShader(GL_VERTEX_SHADER);
fragShader = glCreateShader(GL_FRAGMENT_SHADER);

/* シェーダのソースプログラムの読み込み */

if (readShaderSource(vertShader, "texture.vert")) exit(1);
if (readShaderSource(fragShader, "texture.frag")) exit(1);

...

/* シェーダプログラムの適用 */

glUseProgram(gl2Program);

/* テクスチャユニット０を指定する */
glUniform1i(glGetUniformLocation(gl2Program, "texture"), 0);

/* テクスチャ画像の読み込み */

if ((fp = fopen(texture1, "rb")) != NULL) {
fread(texture, sizeof texture, 1, fp);
fclose(fp);
}
else {
perror(texture1);
}
```

## 以上によりシェーダプログラムの中でテクスチャを参照することが可能になります．

<ul>
<li>[第３版ソースファイル](glsl/glsl3.zip)</li>
</ul>

<div class="figure">
![Phong シェーディングによるテクスチャを貼った四角形]({{ site.baseurl }}/assets/images/glsl13.jpg)
![Phong ーシェーディングによるテクスチャを貼った四角形を斜めから見たところ]({{ site.baseurl }}/assets/images/glsl14.jpg)
</div>
![Phong シェーディングによるテクスチャを貼ったティーポット]({{ site.baseurl }}/assets/images/glsl15.jpg)
