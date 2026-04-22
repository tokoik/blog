---
title: "シェーダで Point Sprite"
date: 2011-03-24
categories: [OpenGL,GLSL]
published: true
---

## 大震災

東北地方太平洋沖地震で被災された皆様, ならびにご家族・関係者の皆様, そしてこれに心を痛めておられるすべての皆様に, 心よりお見舞い申し上げます.  どうしてこんな目に遭わなきゃならないんだという怒りの持って行き場も無く, 「お見舞い」という言葉すらも空虚に思えて, ただただ空を仰ぎ見るばかりです. 今日, うちの大学では「[わかやま自主研究フェスティバル](http://www.crea.wakayama-u.ac.jp/contest/festival2010/fes1.html)」というイベントがあったのですが, その開会式の冒頭でも黙祷の時間がとられました. 私はどうしても下を向けず, 空に登られた方々を見送る気持ちで顔を上げたまま黙祷していました. 「いつかくるとは思っていたが今日くるとは思わなかった」という警句がありますが, それにしてもあまりにも過酷です. この負債は他人任せにせず, 我々日本に住む者皆が負うという覚悟をしたいと思います.

## シェーダで Point Sprite

点 (`GL_POINTS`) にテクスチャを貼る Point Sprite については[だいぶ前に書いた]({% post_url 2006-02-27-post %})んですけど, メールに対するレスポンスの悪さでは定評のある T 君のデモの<`em`>ニギヤカシに, こういうことをやってみてはどうだろうっていう提案を書いておきます.

<ul>
<li>[サンプルプログラム](glsl/sprite2.zip)</li>
</ul>

## 点を描く

まず, `GL_POINTS` を使って点を描画するプログラムを書いたとします.

![点の描画]({{ '/assets/images/sprite10.jpg' | relative_url }})

## この点をシェーダを使って書くとき, バーテックスシェーダとフラグメントシェーダのプログラムは, 例えばそれぞれ次のようになります. Point Sprite 自体ジオメトリシェーダ (テッセレータ) で置き換えられるべき機能だと思いますし, いい加減 OpenGL 3.0 以降に移行しろという感じですけど, この記事の本質ではないので許してください. Mac OS X Lion の OpenGL のバージョンはいくつになるんでしょうね?

```c
#version 120
//
// pointsprite.vert
//

void main(void)

{
gl_Position = ftransform();  // 座標変換するだけ
```

```c
#version 120
//
// pointsprite.frag
//

void main(void)

{
gl_FragColor = vec4(1.0);  // 白色を描くだけ
```

## 点の大きさを変更する

シェーダで点の大きさを変更するには, CPU 側のプログラムで `GL_VERTEX_PROGRAM_POINT_SIZE` を有効にしておきます.

```c
...

/*
** 初期化
*/
static void init(void)
{
...

// ポイントスプライトの設定

glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
}
```

## そしてバーテックスシェーダで変数 `gl_PointSize` に点の大きさを画素数で指定します.

```c
#version 120
//
// pointsprite.vert
//
uniform float size;  // 点の大きさ

void main(void)

{
gl_Position = ftransform();  // 座標変換するだけ
gl_PointSize = size;  // 点の大きさを変更する
```

## ここでは大きさ `size` を `uniform` 変数で与えています. これを CPU 側のプログラムで表示領域のサイズ (ウィンドウの h など) に比例した値を設定すれば，ウィンドウをリサイズした時に点の大きさが追従するようになります.

![点の大きさを変更する]({{ '/assets/images/sprite11.jpg' | relative_url }})

## なお, 点の大きさを投影変換後の w 要素で割れば, 点の大きさを視点からの距離に反比例させることができます.

```c
#version 120
//
// pointsprite.vert
//
uniform float size  // 点の大きさ;

void main(void)

{
gl_Position = ftransform();  // 座標変換するだけ
gl_PointSize = size / gl_Position.w;  // 点の大きさを変更する
```

## なかなかいい感じではないでしょうか.

![点の大きさを視点からの距離に反比例させる]({{ '/assets/images/sprite12.jpg' | relative_url }})

## 点を丸くする

前の [Point Sprite の記事]({% post_url 2006-02-27-post %}) では, 点を丸くするために[アルファテスト]({% post_url 2004-09-16-post %})によるカットアウトを使いました. また, [アンチエリアシング]({% post_url 2008-08-21-post %})の設定を行って点を丸くすることもできます. ここでは Point Sprite で生成されたフラグメントの点内の相対座標値が格納される変数 `gl_PointCoord` を使ってみます. これは CPU 側のプログラムで `GL_POINT_SPRITE` を有効にすれば値が設定されます.

```c
...

/*
** 初期化
*/
static void init(void)
{
...

// ポイントスプライトの設定

glEnable(GL_VERTEX_PROGRAM_POINT_SIZE);
glEnable(GL_POINT_SPRITE);
}
```

## `gl_PointCoord` はフラグメントシェーダだけで使用できる `vec2` 型の変数で, 処理対象のフラグメントの描画する点 (大きさを設定しているので実際は正方形) 内での相対位置が [0, 1] の範囲で設定されます. これは点に貼付けるテクスチャをサンプリングするための<`em`>テクスチャ座標として使うことができます. ここではこれを使って, 点の中心から半径 0.5 の範囲より外にあるフラグメントを捨ててしまいます.

```c
#version 120
//
// pointsprite.frag
//

void main(void)

{
vec3 n;

n.xy = gl_PointCoord * 2.0 - 1.0;  // 座標値を [0, 1] → [-1, 1] に変換する
n.z = 1.0 - dot(n.xy, n.xy);  // 1 から x と y のそれぞれの二乗和を引く
if (n.z < 0.0) discard;  // 結果が負ならフラグメントを捨てる

gl_FragColor = vec4(1.0);  // 白色を描くだけ
```

## これで点が丸くなります.

![点を丸くする]({{ '/assets/images/sprite13.jpg' | relative_url }})

## 点に陰影を付ける

前の [Point Sprite の記事]({% post_url 2006-02-27-post %}) では, あらかじめ球の陰影のテクスチャを貼り付けていましたが, これだと光源の位置などをダイナミックに陰影に反映することができません (不可能ではないですが…). そこで, ここではシェーダーで陰影を計算することにします. まず, バーテックスシェーダで光線ベクトルを求めておきます. ここで光源はローカルな点光源とし, 光源の座標値及び点の座標値の w 要素は 1 であるとします.

```c
#version 120
//
// pointsprite.vert
//

uniform float size;  // 点の大きさ

varying vec3 light;  // 光線ベクトル

void main(void)

{
light = normalize(vec3(gl_LightSource[0].position - gl_ModelViewMatrix * gl_Vertex));  // 点光源の光線ベクトル
gl_Position = ftransform();  // 座標変換するだけ
gl_PointSize = size / gl_Position.w;  // 点の大きさを変更する
```

## これを `varying` 変数 `light` でフラグメントシェーダに渡します. 点なので, `light` は多分補間されないと思います.

```c
#version 120
//
// pointsprite.frag
//
varying vec3 light;  // 光線ベクトル

void main(void)

{
vec3 n;

n.xy = gl_PointCoord * 2.0 - 1.0;  // 座標値を [0, 1] → [-1, 1] に変換する

n.z = 1.0 - dot(n.xy, n.xy);  // 1 から x と y のそれぞれの二乗和を引く
if (n.z < 0.0) discard;  // 結果が負ならフラグメントを捨てる

n.z = sqrt(n.z);  // 球面だと仮定して法線ベクトルの z 成分を求める
vec3 m = normalize(gl_NormalMatrix * n);  // モデルビュー変換による回転の影響を加味する
float d = dot(light, m);  // 拡散反射光強度
gl_FragColor.rgb = vec3(d);
gl_FragColor.a = 1.0;
```

## この計算は<`em`>スクリーン空間で行っているので<`em`>正確ではないのですが, なんだかそれらしく見えます (ほんまか?).

![点に陰影を付ける]({{ '/assets/images/sprite14.jpg' | relative_url }})

## 視線の向きを変えると陰影も変化します.

![視線の向きを変える]({{ '/assets/images/sprite15.jpg' | relative_url }})

## 鏡面反射光も加えてみます.

```c
#version 120
//
// pointsprite.frag
//
varying vec3 light;  // 光線ベクトル

void main(void)

{
vec3 n;

n.xy = gl_PointCoord * 2.0 - 1.0;  // 座標値を [0, 1] → [-1, 1] に変換する

n.z = 1.0 - dot(n.xy, n.xy);  // 1 から x と y のそれぞれの二乗和を引く
if (n.z < 0.0) discard;  // 結果が負ならフラグメントを捨てる

n.z = sqrt(n.z);  // 球面だと仮定して法線ベクトルの z 成分を求める

vec3 m = normalize(gl_NormalMatrix * n);  // モデルビュー変換による回転の影響を加味する
float d = dot(light, m);  // 拡散反射光強度
float s = pow(clamp(-reflect(light, m).z, 0.0, 1.0), 20.0);  // 鏡面反射光強度
gl_FragColor.rgb = vec3(mix(d, s, 0.4));
gl_FragColor.a = 1.0;
```

## めんどくさいので色はつけてませんが. こんな感じになります.

![点の陰影に鏡面反射光を追加する]({{ '/assets/images/sprite16.jpg' | relative_url }})

## 半透明にする

点を描画する際, 点の裏側にある背景のテクスチャを点のテクスチャとしてサンプリングすれば, 点に透明感を与えることができます. CPU 側のプログラムにおいて, `uniform` 変数 `back` にはテクスチャを保持しているテクスチャユニット, `viewport` には表示領域のサイズ (ウィンドウの w と h) を格納しておきます. `gl_FragCoord`.`xy` にはウィンドウ上のフラグメント位置が格納されているので, `viewport` で割って背景のテクスチャ座標を求めます.

```c
#version 120
//
// pointsprite.frag
//
uniform sampler2D back;  // 背景のテクスチャを格納しているテクスチャユニット
uniform vec2 viewport;  // 表示領域のサイズ (ウィンドウの w と h)
varying vec3 light;  // 光線ベクトル

void main(void)

{
vec3 n;

n.xy = gl_PointCoord * 2.0 - 1.0;  // 座標値を [0, 1] → [-1, 1] に変換する

n.z = 1.0 - dot(n.xy, n.xy);  // 1 から x と y のそれぞれの二乗和を引く
if (n.z < 0.0) discard;  // 結果が負ならフラグメントを捨てる

n.z = sqrt(n.z);  // 球面だと仮定して法線ベクトルの z 成分を求める

vec3 m = normalize(gl_NormalMatrix * n);  // モデルビュー変換による回転の影響を加味する
float d = dot(light, m);  // 拡散反射光強度
float s = pow(clamp(-reflect(light, m).z, 0.0, 1.0), 20.0);  // 鏡面反射光強度
gl_FragColor.rgb = mix(texture2D(back, gl_FragCoord.xy / viewport).rgb * d, vec3(s), 0.4);
gl_FragColor.a = 1.0;
```

## こんな具合になります.

![点を半透明にする]({{ '/assets/images/sprite17.jpg' | relative_url }})

## 屈折させてみる

スクリーンスペースでやってるので計算自体はでたらめですけど, 法線ベクトルがわかってるなら屈折<`em`>風の表現もできなくはありません.

```c
#version 120
//
// pointsprite.frag
//
uniform sampler2D back;  // 背景のテクスチャを格納しているテクスチャユニット
uniform vec2 viewport;  // 表示領域のサイズ (ウィンドウの w と h)
varying vec3 light;  // 光線ベクトル

void main(void)

{
vec3 n;

n.xy = gl_PointCoord * 2.0 - 1.0;  // 座標値を [0, 1] → [-1, 1] に変換する

n.z = 1.0 - dot(n.xy, n.xy);  // 1 から x と y のそれぞれの二乗和を引く
if (n.z < 0.0) discard;  // 結果が負ならフラグメントを捨てる

n.z = sqrt(n.z);  // 球面だと仮定して法線ベクトルの z 成分を求める

vec3 m = normalize(gl_NormalMatrix * n);  // モデルビュー変換による回転の影響を加味する
float d = dot(light, m);  // 拡散反射光強度
float s = pow(clamp(-reflect(light, m).z, 0.0, 1.0), 20.0);  // 鏡面反射光強度
gl_FragColor.rgb = mix(texture2D(back, gl_FragCoord.xy / viewport
+ refract(vec3(0.0, 0.0, -1.0), n, 0.67).xy * 0.2).rgb * d, vec3(s), 0.4);
gl_FragColor.a = 1.0;
```

## やっぱりめんどくさいので, 視線ベクトルは (0, 0, -1) にしています. 0.2 は背景との距離みたいなものです.

![屈折させてみる]({{ '/assets/images/sprite18.jpg' | relative_url }})

## 透明なのに diffuse 見えるのはおかしいので, d の代わりに視線と法線の内積 (n.z) を用います. こうすると球の周辺部が暗くなるので, 多少立体感が出ます. これに環境光も加えて, 全体的に明るくします.

```c
#version 120
//
// pointsprite.frag
//
uniform sampler2D back;  // 背景のテクスチャを格納しているテクスチャユニット
uniform vec2 viewport;  // 表示領域のサイズ (ウィンドウの w と h)
varying vec3 light;  // 光線ベクトル

void main(void)

{
vec3 n;

n.xy = gl_PointCoord * 2.0 - 1.0;  // 座標値を [0, 1] → [-1, 1] に変換する

n.z = 1.0 - dot(n.xy, n.xy);  // 1 から x と y のそれぞれの二乗和を引く
if (n.z < 0.0) discard;  // 結果が負ならフラグメントを捨てる

n.z = sqrt(n.z);  // 球面だと仮定して法線ベクトルの z 成分を求める

vec3 m = normalize(gl_NormalMatrix * n);  // モデルビュー変換による回転の影響を加味する
float d = dot(light, m);  // 拡散反射光強度
float s = pow(clamp(-reflect(light, m).z, 0.0, 1.0), 20.0);  // 鏡面反射光強度
gl_FragColor.rgb = texture2D(back, gl_FragCoord.xy / viewport
+ refract(vec3(0.0, 0.0, -1.0), n, 0.67).xy * 0.2).rgb * (n.z * 0.6 + 0.4) + vec3(s * 0.4);
gl_FragColor.a = 1.0;
```

## ということで, こういうのはエフェクトとしてはアリでしょうか? ムリでしょうか?

![環境光を加える]({{ '/assets/images/sprite19.jpg' | relative_url }})
