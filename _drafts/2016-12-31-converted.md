---
title: "SSAO ベースの SSRO 付きライブ放射照度マッピング"
date: 2016-12-31
categories: [OpenGL,GLSL]
published: true
---

## 大晦日だ

今日は大晦日です。色々あった 2016 年も暮れていきます。今年は忙しかったです。本当に忙しかったです。iPhone の「ヘルスケア」アプリの「睡眠分析」には、今日は「1日平均: 4時間 8分」とか出ています。てなことをバンドの忘年会で自慢してたら他の人も同じくらいの睡眠時間で、色々おかしいと思いました。そういえば私は先日ついにキレて、任された仕事を一つ投げてしまいました。書きかけの原稿の催促もいただいていますが、返事していません。ごめんなさい。

## 学生さんとの約束

そんなこんなで、ここんとこ学生さんの面倒を全然見られていません。ごめんなさい。進捗を発表してもらうとプレゼンはとても良くできていたりして、うっかり騙されてしまいます。本当のところはどうなのかはポーリングしないとわからないことが多いのですが、それはコストが高いので、学生さんの方からシグナルを発生してくれた方が他の仕事と非同期に処理できて助かります。よろしくお願いします。
代わりに、進捗状況をもとに必要になりそうなことをここに書いておきます。これは以前からやっていたことですが、今年は本当に忙しくてこっちも滞っていました。にもかかわらず、学生さんが取り組んでるテーマが実は結構難しい話だったりして、解説を書くこと自体に難儀しています。
ということで、今日は大晦日ではありますが、[偽ポールマッカートニー氏](http://reo.hatenablog.jp/)に「年内に書く」と約束していた、2013 年に発表した「[天空画像を用いたスクリーンスペース表面下散乱](http://www.vc.media.yamanashi.ac.jp/nicograph2013/Program.html)」(この論文本体はネット上にないのね… [発表スライド](http://www.slideshare.net/tokoik/ss-40188035), [改良版のモデルの解説ポスター](http://www.slideshare.net/tokoik/ss-42562624), [会場で内職して作ってた発表デモプログラム](https://github.com/tokoik/imsss)) で使っている手法について解説します。ただし、元の研究のキモは表面下散乱ですけど、今回は光源環境に [RICOH THETA S などの全方位カメラ]({{ site.baseurl }}{% post_url 2016-06-29-post %})のライブストリーミング映像を使えるようにしたかわりに、サンプリングに使う確率分布を cosine lobe にしてしまったので、表面下散乱は実現していません。嫌がらせなみに長いですけど偽ポールマッカートニー氏これでいいですか。

## 頂点単位の陰影付けを画素単位の陰影付けに変更する

ベースは三角形分割された Alias OBJ 形式のファイルを読み込んで、マウスでグルグル回して見るプログラムです (プログラムがタコなので Visual Studio のデバッグビルドだと読み込みにすごく時間がかかりますが許してください)。このプログラムでは、陰影付けを頂点単位に行なっています。光源は視点側にあります (ヘッドライト)。

## ![頂点単位の陰影付け](/images/20161231_0.jpg)

<ul>
<li>[頂点単位の陰影付けを行うプログラム](https://github.com/tokoik/irmap/tree/pervertex)</li>
</ul>

## この手法は処理をスクリーン空間で行いますので、このプログラムを[画素単位の陰影付け]({{ site.baseurl }}{% post_url 2005-10-07-post %})に変更します。上のプログラムのバーテックスシェーダのソースプログラム ([pass1.vert](https://github.com/tokoik/irmap/blob/pervertex/irmap/pass1.vert)) は次にようになっています。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass1.vert
//
//   頂点単位に陰影付けを行うシェーダ
//
 
// 光源
uniform vec4 lamb;                                    // 環境光成分
uniform vec4 ldiff;                                   // 拡散反射光成分
uniform vec4 lspec;                                   // 鏡面反射光成分
uniform vec4 lpos;                                    // 位置
 
// 材質
uniform vec4 kamb;                                    // 環境光の反射係数
uniform vec4 kdiff;                                   // 拡散反射係数
uniform vec4 kspec;                                   // 鏡面反射係数
uniform float kshi;                                   // 輝き係数
 
// 変換行列
uniform mat4 mw;                                      // 視点座標系への変換行列
uniform mat4 mc;                                      // クリッピング座標系への変換行列
uniform mat4 mg;                                      // 法線ベクトルの変換行列
 
// 頂点属性
layout (location = 0) in vec4 pv;                     // ローカル座標系での頂点の位置
layout (location = 1) in vec4 nv;                     // ローカル座標系での頂点の法線
 
// ラスタライザに送る頂点属性
out vec4 idiff;                                       // 拡散反射光強度
out vec4 ispec;                                       // 鏡面反射光強度
 
void main(void)
{
  gl_Position = mc * pv;
  
  vec4 p = mw * pv;                                   // 視点座標系での頂点の位置
  vec3 n = normalize((mg * nv).xyz);                  // 視点座標系での頂点の法線
  
  // 陰影
  vec3 v = normalize(p.xyz / p.w);                    // 視線ベクトル
  vec3 l = normalize((lpos * p.w - p * lpos.w).xyz);  // 光線ベクトル
  vec3 h = normalize(l - v);                          // 中間ベクトル
  
  // 拡散反射光成分
  idiff = max(dot(n, l), 0.0) * kdiff * ldiff + kamb * lamb;
  
  // 鏡面反射光成分
  ispec = pow(max(dot(n, h), 0.0), kshi) * kspec * lspec;
```

## これを画素単位の陰影付けに変更するには、頂点の位置と法線ベクトルの算出を除く陰影計算の部分をフラグメントシェーダに移して、頂点の位置と法線ベクトルだけをラスタライザに送ります ([pass1.vert](https://github.com/tokoik/irmap/blob/perpixel/irmap/pass1.vert))。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass1.vert
//
//   画素単位に陰影付けを行うシェーダ
//
 
// 変換行列
uniform mat4 mw;                                      // 視点座標系への変換行列
uniform mat4 mc;                                      // クリッピング座標系への変換行列
uniform mat4 mg;                                      // 法線ベクトルの変換行列
 
// 頂点属性
layout (location = 0) in vec4 pv;                     // ローカル座標系での頂点の位置
layout (location = 1) in vec4 nv;                     // ローカル座標系での頂点の法線
 
// ラスタライザに送る頂点属性
out vec4 p;                                           // 頂点の位置
out vec3 n;                                           // 頂点の法線
 
void main(void)
{
  gl_Position = mc * pv;
  
  p = mw * pv;                                        // 視点座標系での頂点の位置
  n = normalize((mg * nv).xyz);                       // 視点座標系での頂点の法線
```

## 頂点単位の陰影付けのフラグメントシェーダ ([pass1.frag](https://github.com/tokoik/irmap/blob/pervertex/irmap/pass1.frag)) では、ラスタライザで補間された頂点の色をそのままフラグメントの色としていました。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass1.frag
//
//   頂点単位に陰影付けを行うシェーダ
//
 
// ラスタライザから受け取る頂点属性の補間値
in vec4 idiff;                                        // 拡散反射光強度
in vec4 ispec;                                        // 鏡面反射光強度
 
// フレームバッファに出力するデータ
layout (location = 0) out vec4 fc;                    // フラグメントの色
 
void main(void)
{
  // 画素の陰影を求める
  fc = idiff + ispec;
```

## 画素単位の陰影付けでは、ラスタライザで補間された頂点位置と法線ベクトルを使って陰影を計算します ([pass1.frag](https://github.com/tokoik/irmap/blob/perpixel/irmap/pass1.frag))。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass1.frag
//
//   画素単位に陰影付けを行うシェーダ
//
 
// 光源
uniform vec4 lamb;                                    // 環境光成分
uniform vec4 ldiff;                                   // 拡散反射光成分
uniform vec4 lspec;                                   // 鏡面反射光成分
uniform vec4 lpos;                                    // 位置
 
// 材質
uniform vec4 kamb;                                    // 環境光の反射係数
uniform vec4 kdiff;                                   // 拡散反射係数
uniform vec4 kspec;                                   // 鏡面反射係数
uniform float kshi;                                   // 輝き係数
 
// ラスタライザから受け取る頂点属性の補間値
in vec4 p;                                            // 頂点の位置
in vec3 n;                                            // 頂点の法線
 
// フレームバッファに出力するデータ
layout (location = 0) out vec4 fc;                    // フラグメントの色
 
void main(void)
{
  // 陰影
  vec3 v = normalize(p.xyz / p.w);                    // 視線ベクトル
  vec3 l = normalize((lpos * p.w - p * lpos.w).xyz);  // 光線ベクトル
  vec3 h = normalize(l - v);                          // 中間ベクトル
  
  // 拡散反射光成分
  vec4 idiff = max(dot(n, l), 0.0) * kdiff * ldiff + kamb * lamb;
  
  // 鏡面反射光成分
  vec4 ispec = pow(max(dot(n, h), 0.0), kshi) * kspec * lspec;
  
  // 画素の陰影を求める
  fc = idiff + ispec;
```

## これで結果は次のようになります。このウサギのモデルはそれなりにポリゴン数が多いので、陰影付けを画素単位に行っても見た目はあまり変わっていません。

## ![画素単位の陰影付け](/images/20161231_1.jpg)

<ul>
<li>[画素単位の陰影付けを行うプログラム](https://github.com/tokoik/irmap/tree/perpixel)</li>
</ul>

## フレームバッファオブジェクトを組み込む

処理をスクリーン空間で行うために、レンダリング結果を一旦[フレームバッファオブジェクト (FBO)]({{ site.baseurl }}{% post_url 2010-12-07-post %}) に格納します。このように画面に表示されないところに描くことを、オフスクリーンレンダリング (Off-screen Rendering) と呼んだりします。まず、フレームバッファオブジェクトのサイズを決めます。最終的なアウトプット以外の補助的なバッファの解像度は、パフォーマンスを稼ぐために実際の表示解像度より低くするのが一般的ですが、メンタルの具合が悪いとそういうことを決めるのがめんどくさいので、ここではデフォルトのウィンドウサイズと同じにしておきます。また、フレームバッファオブジェクトに使用するテクスチャの境界色も決めておきます。

```cpp
#include <iostream>
 
// ウィンドウ関連の処理
#include "Window.h"
 
// 最初に開くウィンドウのサイズ
const GLsizei width(960), height(540);
 
// フレームバッファオブジェクトのサイズ
const GLsizei fboWidth(width), fboHeight(height);
 
// 境界色
const GLfloat border[] = { 0.0f, 0.0f, 0.0f, 0.0f };
 
// 背景色
const GLfloat background[] = { 0.0f, 0.0f, 0.0f, 0.0f };
 
// 光源
const GgSimpleShader::Light light =
{
  { 0.2f, 0.2f, 0.2f, 1.0f }, // 環境光成分
  { 1.0f, 1.0f, 1.0f, 0.0f }, // 拡散反射光成分
  { 1.0f, 1.0f, 1.0f, 0.0f }, // 鏡面光成分
  { 0.0f, 0.0f, 1.0f, 0.0f }  // 位置
```

## 同じようなテクスチャを複数作ることが予想されるので、テクスチャを作成する関数を作っておきます。[glTexImage2D()](https://www.opengl.org/sdk/docs/man/html/glTexImage2D.xhtml) の引数 format と type をそれぞれ `GL_BGR`、`GL_UNSIGNED_BYTE` にしていますが、data が NULL にしてデータの転送を行いませんから、これらはどうでもいいです。なお、これは C++ なので、当然 NULL は nullptr で構いません。

```cpp
GLuint createTexture(GLenum internalFormat, GLsizei width, GLsizei height)
{
  GLuint t;
  
  glGenTextures(1, &t);
  glBindTexture(`GL_TEXTURE_2D`, t);
  glTexImage2D(`GL_TEXTURE_2D`, 0, internalFormat, width, height, 0, `GL_BGR`, `GL_UNSIGNED_BYTE`, NULL);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_MAG_FILTER`, `GL_LINEAR`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_MIN_FILTER`, `GL_LINEAR`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_WRAP_S`, `GL_CLAMP_TO_BORDER`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_WRAP_T`, `GL_CLAMP_TO_BORDER`);
  glTexParameterfv(`GL_TEXTURE_2D`, `GL_TEXTURE_BORDER_COLOR`, border);
  
  return t;
```

## この createTexture() を使って、`GL_RGBA` のテクスチャを一つ作ります。これはフレームバッファオブジェクトのカラーバッファに使います。

```cpp
  glClearColor(background[0], background[1], background[2], background[3]);
  
  // フレームバッファオブジェクトのカラーバッファに用いるテクスチャを作成する
```

## このほかに `GL_DEPTH_COMPONENT` のテクスチャを作ります。これは色ではなく深度 (デプス) を格納するテクスチャで、デプステクスチャとかデプスマップとか言います。これはフレームバッファオブジェクトのデプスバッファに使います。

```cpp
  const auto depth([] { GLuint t; glGenTextures(1, &t); return t; } ());
  glBindTexture(`GL_TEXTURE_2D`, depth);
  glTexImage2D(`GL_TEXTURE_2D`, 0, `GL_DEPTH_COMPONENT`, fboWidth, fboHeight, 0, `GL_DEPTH_COMPONENT`, `GL_FLOAT`, NULL);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_MAG_FILTER`, `GL_LINEAR`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_MIN_FILTER`, `GL_LINEAR`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_WRAP_S`, `GL_CLAMP_TO_BORDER`);
```

## フレームバッファオブジェクトを作成し、それにカラーバッファに使うテクスチャと、デプスバッファに使うテクスチャを組み込みます。カラーのテクスチャは `GL_COLOR_ATTACHMENT0` に取り付けます。デプステクスチャは `GL_DEPTH_ATTACHMENT` に取り付けます。

```cpp
  const auto fbo([] { GLuint f; glGenFramebuffers(1, &f); return f; } ());
  glBindFramebuffer(`GL_FRAMEBUFFER`, fbo);
  
  // フレームバッファオブジェクトにカラーバッファを組み込む
  glFramebufferTexture(`GL_FRAMEBUFFER`, `GL_COLOR_ATTACHMENT0`, color, 0);
  
  // フレームバッファオブジェクトにデプスバッファを組み込む
```

## このフレームバッファオブジェクトに描画を行うようにします。

```cpp
  while (!window.shouldClose())
  {
    // フレームバッファオブジェクトに描画する
    glBindFramebuffer(`GL_FRAMEBUFFER`, fbo);
    
    // フレームバッファオブジェクトに対するビューポートを設定する
    glViewport(0, 0, fboWidth, fboHeight);
    
    // 隠面消去を行う
    glEnable(`GL_DEPTH_TEST`);
```

## すると、レンダリング結果はフレームバッファオブジェクトに取り付けたテクスチャに格納されます。このテクニックは Render to Texture と呼ばれます。表示に使われる通常のフレームバッファには描かれないので、画面には何も表示されなくなります。

<ul>
<li>[フレームバッファオブジェクトを組み込んだプログラム](https://github.com/tokoik/irmap/tree/fbo)</li>
</ul>

## 遅延レンダリング

フレームバッファオブジェクトに描画すると通常のフレームバッファには描かれなくなるので、画面には表示されません。フレームバッファオブジェクトに描画した内容は、フレームバッファオブジェクトのカラーバッファに取り付けたテクスチャに格納されているので、これをマッピングしたポリゴンを描いて画面に表示します。つまり、一つのフレームを二回に分けてレンダリングするわけです。このような手法をマルチパスレンダリングと言います。また、マルチパスレンダリングにおいて最初に完全なレンダリングを行わず、後のパスで最終的な画像を完成させる手法を遅延レンダリング (Deffered Rendering) とか遅延シェーディング (Deffered Shading) とか言います。
まず、二回目のパスで使用するポリゴンを準備します。これに最初のパスでフレームバッファオブジェクトにレンダリングした内容をテクスチャとしてマッピングします。このポリゴンの描画に用いる頂点配列オブジェクト (Vertex Array Object, VAO) には、「[矩形の書き方]({{ site.baseurl }}{% post_url 2016-08-31-post %})」で説明した手法を使って頂点バッファオブジェクト (Vertex Buffer Object, VBO) を組み込まず、バーテックスシェーダで頂点位置を生成することにします。

```cpp
  const auto fbo([] { GLuint f; glGenFramebuffers(1, &f); return f; } ());
  glBindFramebuffer(`GL_FRAMEBUFFER`, fbo);
  
  // フレームバッファオブジェクトにカラーバッファを組み込む
  glFramebufferTexture(`GL_FRAMEBUFFER`, `GL_COLOR_ATTACHMENT0`, color, 0);
  
  // フレームバッファオブジェクトにデプスバッファを組み込む
  glFramebufferTexture(`GL_FRAMEBUFFER`, `GL_DEPTH_ATTACHMENT`, depth, 0);
  
  // 遅延レンダリングに用いる矩形を作成する
```

## また、このポリゴンの描画に使うシェーダのプログラムオブジェクトを作成します。

```cpp
  const auto pass2(ggLoadShader("pass2.vert", "pass2.frag"));
  
  // uniform 変数の場所を得る
```

## フレームバッファオブジェクトへのレンダリングの後、通常のフレームバッファに戻して、このポリゴンを描画します。

```cpp
  while (!window.shouldClose())
  {
    ...
    
    // 図形を描画する
    object.draw(simple);
    
    // 通常のフレームバッファに描画する
```

## ポリゴン 1 枚しか描かないので、隠面消去処理は無効にしておきます。このほかに、ここで glDepthMask(`GL_FALSE`); として、ポリゴンを描いた後に glDepthMask(`GL_TRUE`); とかすれば、デプスバッファへの書き込みを行わない分パフォーマンスが上がるかもしれません。

```cpp
    glDisable(`GL_DEPTH_TEST`);
```

## あとは通常の描画と同じです。フレームバッファのカラーバッファに取り付けたテクスチャをマッピングします。

```cpp
    window.setViewport();
    
    // 遅延レダリングを行うシェーダの使用を開始する
    glUseProgram(pass2);
    
    // カラーバッファに使ったテクスチャを指定する
    glUniform1i(colorLoc, 0);
    glActiveTexture(`GL_TEXTURE0`);
    glBindTexture(`GL_TEXTURE_2D`, color);
    
    // 矩形を描く
    glBindVertexArray(rectangle);
    glDrawArrays(`GL_TRIANGLE_STRIP`, 0, 4);
    
    // カラーバッファを入れ替えてイベントを取り出す
    window.swapBuffers();
```

## このバーテックスシェーダ ([pass2.vert](https://github.com/tokoik/irmap/blob/deffered/irmap/pass2.vert)) はバーテックスシェーダの組み込み変数 gl_VertexID に格納されている頂点番号を使って頂点のテクスチャ座標と位置を生成します。

```cpp
 
//
// pass2.vert
//
//   フレームバッファオブジェクトの内容を描画するシェーダ
//
 
// ラスタライザに送る頂点属性
out vec2 texcoord;                                    // テクスチャ座標
 
void main()
{
  // テクスチャ座標を求める
  texcoord = vec2(gl_VertexID & 1, gl_VertexID >> 1);
  
  // テクスチャ座標から頂点座標を求めて出力
  gl_Position = vec4(texcoord * 2.0 - 1.0, 0.0, 1.0);
```

## フラグメントシェーダ ([pass2.frag](https://github.com/tokoik/irmap/blob/deffered/irmap/pass2.frag)) はラスタライザで補間されたテクスチャ座標でテクスチャを拾ってフレームバッファに書き込むだけです。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass2.frag
//
//   フレームバッファオブジェクトの内容を描画するシェーダ
//
 
// ラスタライザから受け取る頂点属性の補間値
in vec2 texcoord;                                     // テクスチャ座標
 
// フレームバッファに出力するデータ
layout (location = 0) out vec4 fc;                    // フラグメントの色
 
// カラーのレンダーターゲットのテクスチャ
uniform sampler2D color;
 
void main(void)
{
  // 画素の陰影を求める
  fc = texture(color, texcoord);
```

## フレームバッファオブジェクトに描かれたものをそのまま表示しただけなので、見た目は変わりません。

## ![遅延レンダリング](/images/20161231_2.jpg)

<ul>
<li>[遅延レンダリングを行うプログラム](https://github.com/tokoik/irmap/tree/deffered)</li>
</ul>

## ちなみに、カラーのテクスチャの代わりにデプステクスチャを指定すると、デプスバッファの内容を見ることができます。

```cpp
    glUniform1i(colorLoc, 0);
    glActiveTexture(`GL_TEXTURE0`);
```

## ただし、デプステクスチャは 1 チャンネル、すなわち R (赤) しか持たないので、表示は真っ赤になってしまいます。

## ![デプスバッファの内容表示](/images/20161231_3.jpg)

## マルチプルレンダーターゲットにレンダリングする

前のプログラムではフレームバッファオブジェクトに色のデータを書き込んで、それをそのままポリゴンにマッピングしてレンダリングしました。(本当の) 遅延レンダリングでは、最初のパスで陰影計算まで行ってしまわずに、レンダリングに使う中間的なデータをフレームバッファオブジェクトに格納します。そして二回目のパスでそのデータを使って陰影を求めて、本来のフレームバッファに出力します。この中間的なデータには物体表面の色などの反射特性に加えて位置や法線など複数のものがあるため、フレームバッファオブジェクトに複数のカラーバッファを取り付ける必要があります。これを[マルチプルレンダーターゲット]({{ site.baseurl }}{% post_url 2010-12-08-post %})と言います。

## ![マルチプルレンダーターゲット](/images/20161231_17.jpg)

## フレームバッファオブジェクトのカラーバッファは 4 つ用意します。この最初のアルベドは物体の色です。観測者が見る色は反射光であり、それには拡散反射光と鏡面反射光が混ざりあっています。その配分比は光の入射角と放射角に依存するため、色は視点の位置や入射光の方向によって変わります。アルベドはそれらの要素を除いた材質本来の色、反射能を表します。その次のフレネル項は入射光の屈折成分と正反射成分の配分比で、材質表面の屈折率によって決まります。

これらの他に、画面上のその画素における物体表面の位置や法線もカラーバッファに格納します。[glTexImage2D()](https://www.opengl.org/sdk/docs/man/html/glTexImage2D.xhtml) の引数 format に `GL_RGB32F` を指定すると、テクスチャに GLfloat (float) 型のデータを 3 チャンネル (RGB) 保持することができます (`GL_RGBA` は [0, 1] の範囲の実数値 4 チャンネル)。法線に関しては、これに `GL_RGB16F` (16 ビット浮動小数点、CPU 側では普通使われません) を指定しても問題ないと思います。これを使えば GPU が確保するテクスチャメモリを半分に節約できます。

```cpp
  glClearColor(background[0], background[1], background[2], background[3]);
  
  // フレームバッファオブジェクトのカラーバッファに用いるテクスチャを作成する
  std::vector<GLuint> color;
  color.push_back(createTexture(`GL_RGBA`, fboWidth, fboHeight));   // アルベド
  color.push_back(createTexture(`GL_RGBA`, fboWidth, fboHeight));   // フレネル項
  color.push_back(createTexture(`GL_RGB32F`, fboWidth, fboHeight)); // 位置
  color.push_back(createTexture(`GL_RGB32F`, fboWidth, fboHeight)); // 法線
  
  // カラーバッファの数
```

## フレームバッファオブジェクトには、これらすべてのテクスチャを取り付けます。その際、フレームバッファオブジェクトのどのカラーバッファにテクスチャを取り付けたのかを記録しておきます。ちなみに `GL_COLOR_ATTACHMENT1` は `GL_COLOR_ATTACHMENT0` + 1 です。

```cpp
  const auto fbo([] { GLuint f; glGenFramebuffers(1, &f); return f; } ());
  glBindFramebuffer(`GL_FRAMEBUFFER`, fbo);
  
  // レンダーターゲット
  std::vector<GLenum> target;
  
  for (int i = 0; i < colorCount; ++i)
  {
    // フレームバッファオブジェクトにカラーバッファを組み込む
    const GLenum attachment(`GL_COLOR_ATTACHMENT0` + i);
    glFramebufferTexture(`GL_FRAMEBUFFER`, attachment, color[i], 0);
    
    // カラーバッファを組み込んだアタッチメントを保存しておく
    target.push_back(attachment);
  }
  
  // フレームバッファオブジェクトにデプスバッファを組み込む
```

## 陰影付けを二回目のパスで行うようにしたので、光原のパラメータを二回目のパスのシェーダプログラムに渡すようにします。

```cpp
  const auto rectangle([] { GLuint vao; glGenVertexArrays(1, &vao); return vao; } ());
  
  // 遅延レンダリングを行うシェーダを読み込む
  const auto pass2(ggLoadShader("pass2.vert", "pass2.frag"));
  
  // uniform 変数の場所を得る
  const auto colorLoc(glGetUniformLocation(pass2, "color"));
  const auto lambLoc(glGetUniformLocation(pass2, "lamb"));
  const auto ldiffLoc(glGetUniformLocation(pass2, "ldiff"));
  const auto lspecLoc(glGetUniformLocation(pass2, "lspec"));
  const auto lposLoc(glGetUniformLocation(pass2, "lpos"));
```

## フレームバッファオブジェクトへのレンダリング時には、レンダーターゲットの指定が必要になります。

```cpp
  while (!window.shouldClose())
  {
    // フレームバッファオブジェクトに描画する
    glBindFramebuffer(`GL_FRAMEBUFFER`, fbo);
    
    // レンダーターゲットを指定する
    glDrawBuffers(static_cast<GLsizei>(target.size()), target.data());
    
    // フレームバッファオブジェクトに対するビューポートを設定する
```

## 最初のパスのシェーダプログラムでは、光原の設定 simple.setLight(light) は必要ありません。

```cpp
    simple.use();
    
    // 変換行列を設定する
```

## 二回目のパスでもレンダリング先を指定します。通常のフレームバッファではダブルバッファリングを行なっているので、バックバッファにレンダリングします。

```cpp
    glBindFramebuffer(`GL_FRAMEBUFFER`, 0);
    
    // バックバッファを指定する
    glDrawBuffer(`GL_BACK`);
    
    // ビューポートを設定する
```

## ポリゴンにはすべてのテクスチャをマッピングします。[glActiveTexture()](https://www.opengl.org/sdk/docs/man/docbook4/xhtml/glActiveTexture.xml) を使って、それぞれにテクスチャユニットを割り当てます。ちなみに `GL_TEXTURE1` は `GL_TEXTURE0` + 1 です。この辺りは [Sampler Object](https://www.khronos.org/opengl/wiki/Sampler_Object) を使うと[めっちゃ綺麗に書ける](http://d.hatena.ne.jp/tueda_wolf/20111101/p1)んですが、うっかり OpenGL Version 3.2 縛りで書き始めてしまったので、ここでは昔ながらの方法でやってます。

```cpp
    glUseProgram(pass2);
    
    // カラーバッファに使ったテクスチャを指定する
    for (int i = 0; i < colorCount; ++i)
    {
      glUniform1i(colorLoc + i, i);
      glActiveTexture(`GL_TEXTURE0` + i);
      glBindTexture(`GL_TEXTURE_2D`, color[i]);
    }
```

## 光原の設定はここで行います。

```cpp
    glUniform4fv(lambLoc, 1, light.ambient);
    glUniform4fv(ldiffLoc, 1, light.diffuse);
    glUniform4fv(lspecLoc, 1, light.specular);
    glUniform4fv(lposLoc, 1, light.position);
    
    // 矩形を描く
    glBindVertexArray(rectangle);
```

## 次に最初のパスのバーテックスシェーダ ([pass1.vert](https://github.com/tokoik/irmap/blob/mrt/irmap/pass1.vert)) ですが、これは変更ありません。これに対してフラグメントシェーダ ([pass1.frag](https://github.com/tokoik/irmap/blob/mrt/irmap/pass1.frag)) は、次のように変更します。光原に関する uniform 変数は削除しています。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass1.frag
//
//   マルチプルレンダーターゲットに描画するシェーダ
//
 
// 材質
uniform vec4 kamb;                                  // 環境光の反射係数
uniform vec4 kdiff;                                 // 拡散反射係数
uniform vec4 kspec;                                 // 鏡面反射係数
uniform float kshi;                                 // 輝き係数
 
// ラスタライザから受け取る頂点属性の補間値
in vec4 p;                                          // 頂点の位置
```

## out 変数の location = <span style="font-style: italic;">n</span> の <span style="font-style: italic;">n</span> が `GL_COLOR_ATTACHMENT`<span style="font-style: italic;">n</span> の <span style="font-style: italic;">n</span> に対応します。

```cpp
layout (location = 0) out vec4 color;
layout (location = 1) out vec4 fresnel;
layout (location = 2) out vec3 position;
```

## color にはアルベドを格納しますが、ここではとりあえず形状データの拡散反射係数 kdiff で代用します。環境光に対する反射係数 kamb は kdiff と等しいものとし、そのアルファ値をこの材質の不透明度として使うとして color の第 4 要素に格納しておきます。fresnel にはフレネル項を格納しますが、これも形状データの鏡面反射係数 kspec で代用します。また fresnel の第 4 要素には輝き係数 kshi を格納しますが、fresnel は [glTexImage2D()](https://www.opengl.org/sdk/docs/man/html/glTexImage2D.xhtml) の format に `GL_RGBA` を指定して確保しているので、[0, 1] の間の値しか格納できません。古い OpenGL では kshi の最大値が 128 でしたので (したがって、それを前提に作られた Alias OBJ 形式のデータも、それを超えることがない)、kshi に 1 / 128 = 0.0078125 を掛けて fresnel の第 4 要素に格納しておき、使うときにこれを 128 倍することにします。このほか、頂点データは実座標に直して position に格納し、法線データは正規化してから normal に格納します。

```cpp
{
  color = vec4(kdiff.rgb, kamb.a);
  fresnel = vec4(kspec.rgb, kshi * 0.0078125);
  position = p.xyz / p.w;
  normal = normalize(n);
```

## 二回目のパスのフラグメントシェーダ ([pass2.frag](https://github.com/tokoik/irmap/blob/mrt/irmap/pass2.frag)) は、ラスタライザによって補間された頂点の位置や法線の情報、および uniform 変数で与えられた材質情報の代わりに、フレームバッファオブジェクトのカラーバッファの内容を使って陰影付けを行います。光原の情報は uniform 変数を介して受け取ります。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass2.frag
//
//   フレームバッファオブジェクトの内容を描画するシェーダ
//
 
// 光源
uniform vec4 lamb;                                    // 環境光成分
uniform vec4 ldiff;                                   // 拡散反射光成分
uniform vec4 lspec;                                   // 鏡面反射光成分
uniform vec4 lpos;                                    // 位置
 
// ラスタライザから受け取る頂点属性の補間値
in vec2 texcoord;                                     // テクスチャ座標
 
// フレームバッファに出力するデータ
```

## テクスチャのサンプラは、フレームバッファオブジェクトのカラーバッファの数を要素数とする配列にしておきます。

```cpp
```

## 頂点の位置 p 及び法線ベクトル n は、ラスタライザで補間された値 (in 変数) ではなく、テクスチャから得ます。同様に kdiff、kspec、および kshi もテクスチャから取得して、フラグメントの陰影を計算します。kshi はテクスチャに格納するときに 128 分の 1 にしているので 128 倍します。

```cpp
{
  vec3 p = texture(color[2], texcoord).xyz;           // 頂点の位置
  vec3 n = texture(color[3], texcoord).xyz;           // 頂点の法線
  
  // 陰影
  vec3 v = normalize(p);                              // 視線ベクトル
  vec3 l = normalize(lpos.xyz - p * lpos.w);          // 光線ベクトル
  vec3 h = normalize(l - v);                          // 中間ベクトル
  
  // 拡散反射光成分
  vec4 kdiff = texture(color[0], texcoord);
  vec4 idiff = kdiff * (max(dot(n, l), 0.0) * ldiff + lamb);
  
  // 鏡面反射光成分
  vec4 kspec = texture(color[1], texcoord);
  float kshi = kspec.a * 128.0;
  vec4 ispec = pow(max(dot(n, h), 0.0), kshi) * kspec * lspec;
  
  // 画素の陰影を求める
  fc = idiff + ispec;
```

## でも陰影付けの手法自体は変わっていないので、見かけは変わりません。

## ![マルチプルレンダーターゲット](/images/20161231_4.jpg)

<ul>
<li>[マルチプルレンダーターゲットにレンダリングするプログラム](https://github.com/tokoik/irmap/tree/mrt)</li>
</ul>

## 環境マッピング

OpenCV のビデオキャプチャを使って取得したライブビデオで環境マッピングを行います。OpenCV によるビデオキャプチャを行うクラス CamCV は、CamCV.h とその基底クラス Camera.h で定義しています。これは std::thread を使ってキャプチャを OpenGL の描画ループとは非同期に行うようにしています。この説明はここでは割愛します。プログラムの最初の方でキャプチャスレッドを起動します。captureWidth と captureHeight はキャプチャしようとする映像の幅と高さですが、実際にキャプチャされる画像のサイズは Camera::getWidth() と Camera::getHeight() で得られます。

```cpp
// メイン
//
int main()
{
  // カメラの使用を開始する
  CamCv camera;
  if (!camera.open(captureDevice, captureWidth, captureHeight, captureFps))
  {
    std::cerr << "Can't open capture device.\n";
    return EXIT_FAILURE;
  }
```

## キャプチャした光源環境の映像のフレームを格納するテクスチャを準備します。これを環境マップといいます。サイズはキャプチャされる画像のサイズに合わせます。

 
```cpp
  glFramebufferTexture(`GL_FRAMEBUFFER`, `GL_DEPTH_ATTACHMENT`, depth, 0);
  
  // 環境のテクスチャを準備する
  const auto image(createTexture(`GL_RGB`, camera.getWidth(), camera.getHeight()));
  
  // 遅延レンダリングに用いる矩形を作成する
  const auto rectangle([] { GLuint vao; glGenVertexArrays(1, &vao); return vao; } ());
```

## このテクスチャをシェーダのプログラムオブジェクトに渡すために、プログラムオブジェクトのサンプラの uniform 変数の場所を取得しておきます。

```cpp
  const auto colorLoc(glGetUniformLocation(pass2, "color"));
  const auto imageLoc(glGetUniformLocation(pass2, "image"));
  const auto lambLoc(glGetUniformLocation(pass2, "lamb"));
  const auto ldiffLoc(glGetUniformLocation(pass2, "ldiff"));
  const auto lspecLoc(glGetUniformLocation(pass2, "lspec"));
```

## 環境のテクスチャをマッピングします。テクスチャユニットはフレームバッファオブジェクトのカラーバッファのマッピングに使っているものと重ならないようにします。その後、カメラで取得した映像のフレームを、そのテクスチャに転送します。

```cpp
    glUseProgram(pass2);
    
    // カラーバッファに使ったテクスチャを指定する
    for (int i = 0; i < colorCount; ++i)
    {
      glUniform1i(colorLoc + i, i);
      glActiveTexture(`GL_TEXTURE0` + i);
      glBindTexture(`GL_TEXTURE_2D`, color[i]);
    }
    
    // 環境のテクスチャを指定する
    glUniform1i(imageLoc, colorCount);
    glActiveTexture(`GL_TEXTURE0` + colorCount);
    glBindTexture(`GL_TEXTURE_2D`, image);
    
    // 環境のテクスチャに画像を転送する
```

## 二回目のパスのフラグメントシェーダ ([pass2.frag](https://github.com/tokoik/irmap/blob/envmap/irmap/pass2.frag)) に、このテクスチャをマッピングする処理を追加します。画像の形式は正距円筒図法によるパノラマ画像、Kodak PIXPRO SP360 4K などの魚眼カメラ、および RICOH THETA S に対応しています。画像の形式の切り替えには [Shader Subroutine](https://www.khronos.org/opengl/wiki/Shader_Subroutine) を使うべきなんでしょうけど、これも OpenGL Version 3.2 縛りのために、ここでは #define と #if defined() を使ってお茶を濁しています。まず、このテクスチャのサンプラの uniform 変数 image を追加します。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass2.frag
//
//   フレームバッファオブジェクトの内容を描画するシェーダ
//
 
#define NONE      0
#define PANORAMA  1
#define FISHEYE   2
#define THETA     3
#define MODE THETA
 
// 光源
uniform vec4 lamb;                                    // 環境光成分
uniform vec4 ldiff;                                   // 拡散反射光成分
uniform vec4 lspec;                                   // 鏡面反射光成分
uniform vec4 lpos;                                    // 位置
 
// ラスタライザから受け取る頂点属性の補間値
in vec2 texcoord;                                     // テクスチャ座標
 
// フレームバッファに出力するデータ
layout (location = 0) out vec4 fc;                    // フラグメントの色
 
// カラーのレンダーターゲットのテクスチャ
uniform sampler2D color[4];
 
// 環境のテクスチャ
```

## 環境のテクスチャのサンプリング方法は、「[魚眼レンズ画像の平面展開]({{ site.baseurl }}{% post_url 2016-06-29-post %})」および「[魚眼レンズ画像の平面展開のサンプルプログラム]({{ site.baseurl }}{% post_url 2016-12-03-post %})」の手法に準じています。

```cpp
vec2 size = textureSize(image, 0);
 
// THETA: 環境テクスチャの後方カメラ像のテクスチャ空間上の半径と中心
vec2 radius_b = vec2(-0.25, 0.25 * size.x / size.y);
vec2 center_b = vec2( 0.25, radius_b.t);
 
// THETA: 環境テクスチャの前方カメラ像のテクスチャ空間上の半径と中心
vec2 radius_f = vec2( 0.25, radius_b.t);
vec2 center_f = vec2( 0.75, center_b.t);
 
// FISHEYE: 画角
//const float fisheye_fov = 0.31830989; // 180°
//const float fisheye_fov = 0.27813485; // 206°
const float fisheye_fov = 0.24381183; // 235°
//const float fisheye_fov = 0.21220659; // 270°
 
// 環境のテクスチャのサンプリング
vec4 sample(in vec3 vector)
{
#if MODE == PANORAMA
  
  //
  // 正距円筒図法のパノラマ画像の場合
  //
  
  // 経度方向のベクトル
  vec2 u = vector.xy;
  
  // 緯度方向のベクトル
  vec2 v = vec2(vector.z, length(vector.xz));
  
  // 緯度と経度からテクスチャ座標を求める
  vec2 t = atan(u, v) * vec2(-0.15915494, -0.31830989) + 0.5;
  return texture(image, t);
  
#elif MODE == FISHEYE
  
  //
  // 等距離射影方式の魚眼レンズ画像の場合
  //
  
  // レンズを上に向けた場合のテクスチャ座標を求める
  vec2 t = fisheye_fov * acos(vector.y) * normalize(vector.xz) + 0.5;
  return texture(image, t);
  
#elif MODE == THETA
  
  //
  // RICOH THETA S のライブストリーミング画像の場合
  //
  
  // この方向ベクトルの相対的な仰角
  float angle = 1.0 - acos(vector.z) * 0.63661977;
  
  // 前後のテクスチャの混合比
  float blend = smoothstep(-0.02, 0.02, angle);
  
  // この方向ベクトルの yx 上での方向ベクトル
  vec2 orientation = normalize(vector.yx) * 0.885;
  
  // 裏と表のテクスチャ座標を求める
  vec2 t_b = (1.0 - angle) * orientation * radius_b + center_b;
  vec2 t_f = (1.0 + angle) * orientation * radius_f + center_f;
  
  // 裏と表の環境のテクスチャをサンプリングする
  vec4 color_b = texture(image, t_b);
  vec4 color_f = texture(image, t_f);
  
  // サンプリングした色をブレンドする
  return mix(color_f, color_b, blend);
  
#else
  
  // そのままテクスチャを貼る
  return texture(image, texcoord);
  
#endif
}
 
void main(void)
{
  vec3 p = texture(color[2], texcoord).xyz;           // 頂点の位置
  vec3 n = texture(color[3], texcoord).xyz;           // 頂点の法線
  
  // 陰影
  vec3 v = normalize(p);                              // 視線ベクトル
  vec3 l = normalize(lpos.xyz - p * lpos.w);          // 光線ベクトル
  vec3 h = normalize(l - v);                          // 中間ベクトル
  
  // 拡散反射光成分
  vec4 kdiff = texture(color[0], texcoord);
  vec4 idiff = kdiff * (max(dot(n, l), 0.0) * ldiff + lamb);
  
  // 鏡面反射光成分
  vec4 kspec = texture(color[1], texcoord);
  float kshi = kspec.a * 128.0;
```

## 視線ベクトル v と法線ベクトル n から視線の反射ベクトル r を求め、これを使って環境のテクスチャをサンプリングします。そして得た色を kspec を使って拡散反射光強度 idiff とブレンドします。鏡面反射光 ispec は、本当はいらない (環境の映り込み自体が「鏡面反射」なので ispec を加算するのはそもそもおかしい) のですが、今はとりあえず残しておきます。

```cpp
  vec3 r = reflect(v, n);
  
  // 正反射方向の色
  vec4 s = sample(r);
  
  // 画素の陰影を求める
  fc = mix(idiff, s, kspec) + ispec;
```

## 映り込みと従来の鏡面反射光によるハイライトが重なっています。

## ![ライブ環境マッピング](/images/20161231_5.jpg)

<ul>
<li>[ライブビデオで環境マッピング行うプログラム](https://github.com/tokoik/irmap/tree/envmap)</li>
</ul>

## ライブ放射照度マッピング

ライブビデオを光源環境に用いて、それによる放射照度をマッピングします。物体表面上の一点に入射する光の照射照度 <span style="font-style: italic;">E</span> は、その点における法線方向 <span style="font-weight: bold;">n</span> を天頂とする半天球 (Hemi Sphere) Ω の各方向 <span style="font-weight: bold;">l</span> の放射輝度 <span style="font-style: italic;">L<sub>i</sub></span>(<span style="font-weight: bold;">l</span>) に入射角 <span style="font-style: italic;">θ<sub>i</sub></span> の余弦 cos <span style="font-style: italic;">θ<sub>i</sub></span> を乗じ、それを Ω について積分して求めます。

## ![放射照度](/images/20161231_13.jpg)

## $$E=\frac{1}{\pi}\int_{\Omega}L_i({\bf l})\cos\theta_id\omega_i$$

## ただ、この積分をまともに計算するとすごく時間がかかるので、先に天球のすべての方向からの放射照度を求めてテクスチャに格納しておく[放射照度マッピング]({{ site.baseurl }}{% post_url 2015-08-26-post %})や、天球の明度分布 (光源環境) を球面調和解析し畳み込み演算を周波数空間で行う [Precomputed radiance transfer (PRT)](http://dl.acm.org/citation.cfm?id=566612) ([PDF](http://cseweb.ucsd.edu/~ravir/6998/papers/p527-sloan.pdf)) をはじめ、様々な手法が提案されています。後者は物体表面上の一点 (頂点) から見える天空の状況 (伝達関数) についても球面調和解析し、光源環境と伝達関数の畳み込み演算を周波数空間の低次の項の内積によって求めることにより、局所的な影や相互反射、半透明などの照明効果をリアルタイムに実現することができます。これは Direct3D のバージョン 9 に[実装](https://msdn.microsoft.com/en-us/library/windows/desktop/bb147287(v=vs.85).aspx)されています。

<blockquote>この話とは全然関係ないし昔のことで記憶があいまいなんですけど、かつて購読していた (今は研究費がもったいなくて購読していない) IEEE CG&A という雑誌で、記事を書いていた有名な CG 研究者 (に限らんのですけど) のメールアドレスがどんどん[マイクロソフトリサーチ](https://www.microsoft.com/en-us/research/)に変わっていった時期があったように思います。んで、それと前後して Direct3D みたいなものが出てきてマイクロソフトが (リアルタイム) CG の世界でもイニシアチブを取るようになっちゃったっていう印象を私は持ってます。上記の PRT の開発者の Sloan 氏も、この研究のときはマイクロソフトリサーチの人でした。でも、今は[ディズニーリサーチ](https://www.disneyresearch.com/)にいらっしゃるんですよね。ちょっと前は有名な CG 研究者がディズニーリサーチに吸い寄せられていったような気がしてたんですけど、こういうのは時代の流れっちゅーもんですかね。今は [AI 関係者](http://wired.jp/2017/01/03/giant-worlds-ai-talent/)なんでしょうか。</blockquote>

## ただ、これらの方法は事前計算によるものであり、ライブビデオに対応するのは難しいように思えます。球面調和解析については[高速な計算法](http://olab.is.s.u-tokyo.ac.jp/~reiji/fltss.html)も存在し、GPU などを使えばリアルタイム化できそうな気がします。ですので、誰かがやってると思うんですけど私は不勉強なので知りません (誰か教えてください ← 自分で調べろや)。そこで、ここでは安直にモンテカルロ積分を使って大雑把に近似する手法を使ってみたいと思います。<span style="font-style: italic;">p</span>(<span style="font-style: italic;">x</span>) という確率分布に従う確率変数 <span style="font-style: italic;">x</span> における関数 <span style="font-style: italic;">f</span>(<span style="font-style: italic;">x</span>) の期待値〈<span style="font-style: italic;">f</span>(<span style="font-style: italic;">x</span>)〉は、次のようにして求められます。

## $$\langle f(x) \rangle \equiv \int p(x)f(x) dx$$

## この確率変数 <span style="font-style: italic;">x</span> の発生頻度が <span style="font-style: italic;">p</span>(<span style="font-style: italic;">x</span>) に従うのであれば、これは単純に <span style="font-style: italic;">f</span>(<span style="font-style: italic;">x</span>) の平均で近似することができます。これをモンテカルロ積分とかモンテカルロ法とか呼びます。大数の法則により、<span style="font-style: italic;">N</span> が大きくなるにつれ、この近似は真値に近づきます。

## $$\langle f(x) \rangle \simeq \frac{1}{N}\sum_{i=1}^{N}f(x_i)$$

## これを先ほどの放射照度の式と見比べてみます。入射角 <span style="font-style: italic;">θ<sub>i</sub></span> は入射方向 <span style="font-weight: bold;">l</span> によって決まりますから、<span style="font-style: italic;">θ<sub>i</sub></span> を <span style="font-style: italic;">p</span>(<span style="font-style: italic;">θ<sub>i</sub></span>) = cos(<span style="font-style: italic;">θ<sub>i</sub></span>) / 2 という確率密度関数 (Probability Density Function, PDF) に従う確率変数とすれば、この積分を次のように近似することができます。

## $$E\simeq\frac{1}{N}\sum_{i=1}^{N}L_{i}\left({\bf l}(\theta_i)\right)$$

## ここで <span style="font-weight: bold;">l</span>(<span style="font-style: italic;">θ<sub>i</sub></span>) は法線に対して <span style="font-style: italic;">θ<sub>i</sub></span> の角度を持つ任意のベクトルです。このベクトルを前述の確率密度関数 <span style="font-style: italic;">p</span>(<span style="font-style: italic;">θ<sub>i</sub></span>) に従って発生させれば、この式により放射照度 <span style="font-style: italic;">E</span> の近似値が得られます。

## 以前に説明した[放射照度マッピング]({{ site.baseurl }}{% post_url 2015-08-26-post %})は、放射照度、すなわち受光面の1点に入射する単位面積当たりの光の強さ (エネルギー) に着目したもので、受光面を入射光がすべての方向に均等に反射する完全拡散反射面とし、鏡面反射は考慮していませんでした。ここでは鏡面反射成分についても前述と同様の手法で強度を求めます。この手法については後述しますが、鏡面反射のモデルには古典とも言える Phong のモデルを採用します。

<blockquote> Phong のモデルを採用したのは、この確率密度関数の累積分布関数がとても簡単になるからです。より複雑なモデルに対しては重点サンプリング (インポータンスサンプリング) の手法が用いられます。[Ward の異方性モデル](http://dl.acm.org/citation.cfm?id=134078) ([PDF](http://testcis.cis.rit.edu/~cnspci/references/ward1992.pdf)) については、[shikihuiku](https://shikihuiku.wordpress.com/) さまが[レンダリングにおける importance sampling の基礎](https://shikihuiku.wordpress.com/2016/06/14/%e3%83%ac%e3%83%b3%e3%83%80%e3%83%aa%e3%83%b3%e3%82%b0%e3%81%ab%e3%81%8a%e3%81%91%e3%82%8bimportancesampling%e3%81%ae%e5%9f%ba%e7%a4%8e/), [(2)](https://shikihuiku.wordpress.com/2016/08/01/%e3%83%ac%e3%83%b3%e3%83%80%e3%83%aa%e3%83%b3%e3%82%b0%e3%81%ab%e3%81%8a%e3%81%91%e3%82%8bimportance-sampling%e3%81%ae%e5%9f%ba%e7%a4%8e2/), [(3)](https://shikihuiku.wordpress.com/2016/08/23/%e3%83%ac%e3%83%b3%e3%83%80%e3%83%aa%e3%83%b3%e3%82%b0%e3%81%ab%e3%81%8a%e3%81%91%e3%82%8bimportance-sampling%e3%81%ae%e5%9f%ba%e7%a4%8e3/), [(4)](https://shikihuiku.wordpress.com/2016/09/11/%e3%83%ac%e3%83%b3%e3%83%80%e3%83%aa%e3%83%b3%e3%82%b0%e3%81%ab%e3%81%8a%e3%81%91%e3%82%8bimportance-sampling%e3%81%ae%e5%9f%ba%e7%a4%8e4/) で 詳しく解説なさっています。また関係ない話なんですけど、重点サンプリングは AI 研究の機械学習の話にもよく出てきます ([人工知能に関する断創録](http://aidiary.hatenablog.com/)さまの[重点サンプリング (1)](http://aidiary.hatenablog.com/entry/20140920/1411207305), [(2)](http://aidiary.hatenablog.com/entry/20140921/1411292913) とか)。自分は学生時代は AI とか CV とかやっている研究室で逆らって CG やってたので、それらの領域には足を踏み入れるまいと心に誓っているのですが、基盤となる知識がめっちゃ被ってるのでしょっちゅう驚かされます。基礎はなんでも疎かにはできませんね。そういや、自分の最初に査読論文を書いたプログラムでも、当時の電総研 (今の産総研) で開発していた Valid っていう Lisp のシンタックスシュガーの説明を友達に聞いて思いついたテクニックを使ってました。</blockquote>

## ![cosine robe](/images/20161231_9.jpg)

## 今、この曲線上の一点の原点からの距離を <span style="font-style: italic;">r</span>、この点の高さを <span style="font-style: italic;">z</span>、xy 平面への足の原点からの距離を <span style="font-style: italic;">d</span> とします。これらは原点からこの点に向かう線分の、z 軸に対する角度 <span style="font-style: italic;">θ</span> の関数で表すことができます。

## $$\left\{\begin{array}{l} r(\theta)=\cos^n\theta\\ d(\theta)=\cos^n\theta\sin\theta\\ z(\theta)=\cos^n\theta\cos\theta \end{array}\right.$$

## この分布は等方性 (isotropic) なので、断面は円になります。

## ![cosine lobe の立体形状](/images/20161231_10.jpg)

## この高さ <span style="font-style: italic;">z</span> における断面の円周長 <span style="font-style: italic;">s</span> は、言うまでもなく <span style="font-style: italic;">d</span> に 2π をかけたものになります。

## $$s(\theta)=2\pi d(\theta)$$

## これを <span style="font-style: italic;">θ</span> について [0, π/2] の範囲で定積分すると、次のようになります。

## $$\int_0^{\frac{\pi}{2}} s(\theta)d\theta=2\pi\int_0^{\frac{\pi}{2}} \cos^n\theta\sin\theta d\theta=\frac{2\pi}{n+1}$$

## そこで、次のような関数を考えます。

## $$p(\theta)=(n+1)\cos^n\theta\sin\theta$$

## これを θ について [0, π/2] で積分したものは 1 になり、確率密度関数として使えます。これは、この形状の表面における「密度」が均一になっているという分布です。

## $$\int_0^{\frac{\pi}{2}} p(\theta)d\theta=1\ (n \geq 0)$$

## この分布に従う乱数を生成して、<span style="font-style: italic;">θ<sub>i</sub></span> として使います。これには[逆関数法]({{ site.baseurl }}{% post_url 2009-12-25-post %})を使います。まず、この確率密度関数の累積分布関数 (Cumulative Distribution Function, CDF) を求め、それを <span style="font-style: italic;">u</span> とします。

## $$F(t)=\int_0^t p(\theta)d\theta=1-\cos^{n+1}t=u$$

## この逆関数を求めます。

## $$F^{-1}(u)=\cos^{-1}(1-u)^{\frac{1}{n+1}}$$

## これを使って [0, 1] の範囲の一様乱数 <span style="font-style: italic;">u</span> から <span style="font-style: italic;">θ<sub>i</sub></span> ← <span style="font-style: italic;">F</span><sup>-1</sup>(<span style="font-style: italic;">u</span>) を求め、それをもとにベクトル <span style="font-weight: bold;">l</span>(<span style="font-style: italic;">θ<sub>i</sub></span>) = (<span style="font-style: italic;">x</span>, <span style="font-style: italic;">y</span>, <span style="font-style: italic;">z</span>) を得ます。ここで <span style="font-style: italic;">u</span> が [0, 1] の範囲の一様乱数なら 1 - <span style="font-style: italic;">u</span> も同じ分布の一様乱数になります。また、<span style="font-style: italic;">v</span> も [0, 1] の範囲の一様乱数です。

## $$z=\cos\left(F^{-1}(u)\right)=(1-u)^{\frac{1}{n+1}}\ \rightarrow\ z=u^{\frac{1}{n+1}}$$

## $$d=\sqrt{1-z^2}$$

## $$x=d\cos(2\pi v)\\y=d\sin(2\pi v)$$

## この手法によって、半天空上に下図の上段のような点群 (サンプル点) が生成されます (点の数 10,000 個)。半天空上のこの点の放射輝度をサンプリングして、放射照度を求めます。下段は密度を点の原点からの距離に反映したものです ([この図を描くプログラム](https://github.com/tokoik/sampler))。

## ![サンプル点](/images/20161231_11.jpg)

## しかし、1 点の放射照度を求めるのに 1 万点もサンプリングしていては、時間がかかりすぎます。リアルタイム (60fps 以上) でレンダリングするには、現在の GPU ならせいぜい数十点というところでしょう。以下のプログラム ([main.cpp](https://github.com/tokoik/irmap/blob/irradiance/irmap/main.cpp)) では、とりあえず 32 (diffuseSamples) にしています。

その一方で、サンプリングする天空の画像の解像度が高いとき、サンプリングする点の数が少なければ、ひどいエリアシング (モアレ) が発生してしまいます。そこでレンダリングに先立って、天空の画像をダウンサンプリングします。でも、このダウンサンプリングの処理を書く気力がもうないので、ここではミップマップ ([ゲームグラフィックス特論第7回22ページ](http://www.wakayama-u.ac.jp/~tokoi/lecture/gg/ggnote07.pdf#page=22)) の機能を使います。

## ![ミップマップ](/images/20161231_12.jpg)

## ミップマップはテクスチャがサンプリングによって縮小される場合に発生するエリアシングを軽減する機能なので、ここでこの機能を使うのは本来の使い方だとは思いますが、ここではサンプリングする天空の画像が直交座標系ではないので、適切なフィルタリングが行えるかどうか疑問が残ります。でも、もう気力がないので、これを使ってしまいます。ミップマップのレベルはどうやって決めたらいいのかよくわかんないんですけど、とりあえず 5 くらいにしてみます。

```cpp
#include <iostream>
#include <vector>
 
// ウィンドウ関連の処理
#include "Window.h"
 
// 最初に開くウィンドウのサイズ
const GLsizei width(960), height(540);
 
// フレームバッファオブジェクトのサイズ
const GLsizei fboWidth(width), fboHeight(height);
 
// 境界色
const GLfloat border[] = { 0.0f, 0.0f, 0.0f, 0.0f };
 
// 背景色
const GLfloat background[] = { 0.0f, 0.0f, 0.0f, 0.0f };
 
// OpenCV によるビデオキャプチャ
#include "CamCv.h"
 
// キャプチャに用いるカメラのデバイス番号
const int captureDevice(0);
 
// キャプチャするフレームのサイズ (0 ならデフォルト)
const int captureWidth(1280), captureHeight(720);
 
// キャプチャするフレームレート (0 ならデフォルト)
const int captureFps(0);
 
// 法線方向のサンプル数
const GLsizei diffuseSamples(32);
 
// 法線方向のミップマップのレベル
```

## ミップマップに対応したテクスチャの作成を行います。これは [glTexStorage2D()](https://www.opengl.org/sdk/docs/man/html/glTexStorage2D.xhtml) を使えば一気にできるんですけど、これも OpenGL Version 3.2 縛りだと使えないので、いちいち作ることになります。レベルを一つ増すごとに縦横の解像度を半分にします。また、テクスチャ縮小時のフィルタ `GL_TEXTURE_MIN_FILTER` は `GL_LINEAR_MIPMAP_LINEAR` にします。

```cpp
GLuint createTexture(GLenum internalFormat, GLsizei width, GLsizei height, GLint levels)
{
  GLuint t;
  
  glGenTextures(1, &t);
  glBindTexture(`GL_TEXTURE_2D`, t);
  for (GLint level = 0; level <= levels; ++level)
  {
    glTexImage2D(`GL_TEXTURE_2D`, level, internalFormat, width, height, 0, `GL_BGR`, `GL_UNSIGNED_BYTE`, NULL);
    width = std::max(1, (width / 2));
    height = std::max(1, (height / 2));
  }
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_MAG_FILTER`, `GL_LINEAR`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_MIN_FILTER`, `GL_LINEAR_MIPMAP_LINEAR`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_WRAP_S`, `GL_CLAMP_TO_BORDER`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_WRAP_T`, `GL_CLAMP_TO_BORDER`);
  glTexParameterfv(`GL_TEXTURE_2D`, `GL_TEXTURE_BORDER_COLOR`, border);
  
  return t;
```

## 環境のテクスチャをミップマップに対応します。

```cpp
// メイン
//
int main()
{
  ...
  
  // フレームバッファオブジェクトにデプスバッファを組み込む
  glFramebufferTexture(`GL_FRAMEBUFFER`, `GL_DEPTH_ATTACHMENT`, depth, 0);
  
  // 環境のテクスチャを準備する
```

## 法線方向の環境のテクスチャをサンプリングする点の数とミップマップのレベルは、シェーダプログラムにも渡します。その uniform 変数の場所を得ておきます。

```cpp
  const auto rectangle([] { GLuint vao; glGenVertexArrays(1, &vao); return vao; } ());
  
  // 遅延レンダリングを行うシェーダを読み込む
  const auto pass2(ggLoadShader("pass2.vert", "pass2.frag"));
  
  // uniform 変数の場所を得る
  const auto colorLoc(glGetUniformLocation(pass2, "color"));
  const auto imageLoc(glGetUniformLocation(pass2, "image"));
  const auto diffuseSamplesLoc(glGetUniformLocation(pass2, "diffuseSamples"));
```

## 環境のテクスチャに画像を転送した後、ミップマップを生成します。

```cpp
  while (!window.shouldClose())
  {
    ...
    
    // 環境のテクスチャを指定する
    glUniform1i(imageLoc, colorCount);
    glActiveTexture(`GL_TEXTURE0` + colorCount);
    glBindTexture(`GL_TEXTURE_2D`, image);
    
    // 環境のテクスチャに画像を転送する
    camera.transmit();
    glGenerateMipmap(`GL_TEXTURE_2D`);
    
    // 法線方向のサンプル点の数を設定する
    glUniform1i(diffuseSamplesLoc, diffuseSamples);
    
    // ミップマップのレベルを設定する
    glUniform1i(diffuseLodLoc, diffuseLod);
    
    // 矩形を描く
    glBindVertexArray(rectangle);
    glDrawArrays(`GL_TRIANGLE_STRIP`, 0, 4);
    
    // カラーバッファを入れ替えてイベントを取り出す
    window.swapBuffers();
  }
```

## 二回目のパスのフラグメントシェーダ [pass2.frag](https://github.com/tokoik/irmap/blob/irradiance/irmap/pass2.frag) も、まずミップマップに対応するよう書き換えます。これまで使用してきた光源はもう使わないので、光源のパラメータを受け取っている uniform 変数の宣言は削除します。また、環境のテクスチャをサンプリングする点の数とミップマップのレベルを受け取る uniform 変数を宣言を追加します。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass2.frag
//
//   フレームバッファオブジェクトの内容を描画するシェーダ
//
 
#define NONE      0
#define PANORAMA  1
#define FISHEYE   2
#define THETA     3
#define MODE THETA
 
// カラーのレンダーターゲットのテクスチャ
uniform sampler2D color[4];
 
// 環境のテクスチャ
uniform sampler2D image;
 
// 法線方向のサンプル点の数
uniform int diffuseSamples;
 
// 法線方向のミップマップのレベル
```

## 環境のテクスチャをサンプリングする関数を、ミップマップに対応します。テクスチャをサンプリングする GLSL の組み込み関数 [texture()](https://www.opengl.org/sdk/docs/man4/html/texture.xhtml) を、ミップマップのレベルを指定する [textureLod()](https://www.opengl.org/sdk/docs/man4/html/textureLod.xhtml) に変更します。

```cpp
vec4 sample(in vec3 vector, in int lod)
{
#if MODE == PANORAMA
  
  //
  // 正距円筒図法のパノラマ画像の場合
  //
  
  // 経度方向のベクトル
  vec2 u = vector.xy;
  
  // 緯度方向のベクトル
  vec2 v = vec2(vector.z, length(vector.xz));
  
  // 緯度と経度からテクスチャ座標を求める
  vec2 t = atan(u, v) * vec2(-0.15915494, -0.31830989) + 0.5;
  return textureLod(image, t, lod);
  
#elif MODE == FISHEYE
  
  //
  // 等距離射影方式の魚眼レンズ画像の場合
  //
  
  // レンズを上に向けた場合のテクスチャ座標を求める
  vec2 t = fisheye_fov * acos(vector.y) * normalize(vector.xz) + 0.5;
  return textureLod(image, t, lod);
  
#elif MODE == THETA
  
  //
  // RICOH THETA S のライブストリーミング画像の場合
  //
  
  // この方向ベクトルの相対的な仰角
  float angle = 1.0 - acos(vector.z) * 0.63661977;
  
  // 前後のテクスチャの混合比
  float blend = smoothstep(-0.02, 0.02, angle);
  
  // この方向ベクトルの yx 上での方向ベクトル
  vec2 orientation = normalize(vector.yx) * 0.885;
  
  // 裏と表のテクスチャ座標を求める
  vec2 t_b = (1.0 - angle) * orientation * radius_b + center_b;
  vec2 t_f = (1.0 + angle) * orientation * radius_f + center_f;
  
  // 裏と表の環境のテクスチャをサンプリングする
  vec4 color_b = textureLod(image, t_b, lod);
  vec4 color_f = textureLod(image, t_f, lod);
  
  // サンプリングした色をブレンドする
  return mix(color_f, color_b, blend);
  
#else
  
  // そのままテクスチャを貼る
  return textureLod(image, texcoord, lod);
  
#endif
```

## 一様乱数が必要になるので、まず、その種になるノイズ関数を作ります。これには [wgld.org](https://wgld.org/) さまが紹介されていた[フラグメントシェーダノイズ](https://wgld.org/d/glsl/g007.html)を使ってみます。ただし、この後で使う Xorshift 法は種が 0 だと 0 しか発生してくれなくなるので、最小値が 1 になるようにします (最大値 2<sup>32</sup> - 1 = 4294967295)。最初、これに GLSL の組み込み関数の [noise 関数](https://www.opengl.org/sdk/docs/man/html/noise.xhtml)を使おうとしたのですが、ありえんくらい遅かったのでやめました。

```cpp
uint rand(in vec2 co)
{
  return uint(fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453) * 4294967294.0) + 1u;
```

## これで生成した種から、その系列の一様乱数を発生します。これには高速で品質が良いといわれる Xorshift 法 ([PDF](https://www.jstatsoft.org/article/view/v008i14/xorshift.pdf)) を使います。値は [0, 1] の実数値として得ます (1 / (2<sup>32</sup> - 1) = 2.3283064 × 10<sup>-10</sup>)。

```cpp
float xorshift(inout uint y)
{
  // shift して xor する
  y = y ^ (y << 13);
  y = y ^ (y >> 17);
  y = y ^ (y << 5);
  
  // [0, 1] に正規化して返す
  return float(y) * 2.3283064e-10;
```

## そして前述の逆関数法を使って、環境のテクスチャのサンプリングに使う点群を生成します。

```cpp
vec4 sampler(inout uint seed, in float e)
{
  float z = pow(xorshift(seed), e);
  float r = sqrt(1.0 - z * z);
  float t = 6.2831853 * xorshift(seed);
  vec3 s = normalize(vec3(vec2(cos(t), sin(t)) * r, z));
  return vec4(s, 0.0);
```

## フラグメント色を求めます。まず、マルチプルレンダーターゲットから物体表面のアルベドを取り出します。今のところ、これには Alias OBJ 形式の形状データのマテリアルの拡散反射係数を格納しています。このアルファ値 (不透明度) を、マテリアル全体のアルファ値として扱います。これはオブジェクトを背景画像との合成するときに使いますが、今は少しでもパフォーマンスを稼ぐために、これが 0 のときは完全に透明だとして、背景色を出力します。

```cpp
{
  // color[0] から albedo を取得
  vec4 albedo = texture(color[0], texcoord);
  
  // albedo のアルファ値が 0 なら背景色
  if (albedo.a == 0.0)
  {
    fc = vec4(0.0);
    return;
```

## フレネル項も取り出しておきます。今のところ、これには Alias OBJ 形式の形状データのマテリアルの鏡面反射係数を格納しています。

```cpp
  vec3 p = texture(color[2], texcoord).xyz;           // 頂点の位置
  vec3 n = texture(color[3], texcoord).xyz;           // 頂点の法線
  
  // 陰影
```

## 環境のテクスチャをサンプリングする点群 (光線方向ベクトル <span style="font-weight: bold;">l</span>) を、オブジェクト表面の法線方向に向ける回転の変換行列を求めます。まず、視点座標系の z 軸 z = (0, 0, 1) と法線ベクトル <span style="font-weight: bold;">n</span> に直交するベクトル <span style="font-weight: bold;">z</span><span style="font-style: italic;"><sub>n</sub></span> を求め、これを使って接空間の接線ベクトル <span style="font-weight: bold;">t</span> および従接線ベクトル <span style="font-weight: bold;">b</span> を求めます。そして、この (<span style="font-weight: bold;">t</span>, <span style="font-weight: bold;">b</span>, <span style="font-weight: bold;">n</span>) により回転の変換行列 <span style="font-weight: bold;">m</span> を求めます。ただし、この方法だと法線ベクトルが視点座標系の z 軸に近いとき (回転がわずかなとき) に回転の変換行列の誤差が大きくなるようで、陰影に「へそ」ができてしまいます。何か間違っているのかもしれませんが、回転行列の算出方法を変更したほうがいいような気がします。

```cpp
  vec3 zn = vec3(-n.y, n.x, 0.0);
  float len = length(zn);
  vec3 t = mix(vec3(1.0, 0.0, 0.0), zn / len, step(0.001, len));
  vec3 b = cross(n, t);
```

## 先ほど作ったノイズの関数を使って、乱数の種を作ります。でも、なんかジッタリングっぽくなってなめらかな陰影にならなかったので、実は定数でもいいのかもしれません (コメント部分)。

```cpp
  uint seed = rand(gl_FragCoord.xy);
```

## 環境のテクスチャをサンプリングする点を生成し、回転行列を乗じてから環境のテクスチャをサンプリングします。そして、得られた色を idiff に合計します。関数 sampler() の引数 0.5 は、cos<span style="font-style: italic;"><sup>n</sup>θ</span> の <span style="font-style: italic;">n</span> = 1 のときの <span style="font-style: italic;">e</span> = 1 /(<span style="font-style: italic;">n</span> + 1) です。

```cpp
  vec4 idiff = vec4(0.0);
  
  // 法線側の個々のサンプル点について
  for (int i = 0; i < diffuseSamples; ++i)
  {
    // サンプル点の生成
    vec4 d = sampler(seed, 0.5);
    
    // サンプル点を法線側に回転する
    vec3 l = m * d.xyz;
    
    // 法線側のサンプル点方向の色を累積する
    idiff += sample(l, diffuseLod);
```

## 拡散反射光強度として、法線側のサンプル点方向の色を累積した idiff の平均を用います。鏡面反射光強度は、現段階では環境のテクスチャをそのまま使います。この環境のテクスチャはぼかさないので、ミップマップのレベルは 0 にしておきます。鏡面反射係数は kspec の代わりにフレネル項 fresnel に格納しています。このアルファ値には輝き係数 kshi が入っていますが、ここでは使わないので 0 にしておきます。そして環境による放射照度から求めた拡散反射光強度と環境のテクスチャをサンプリングした値を fresnel でブレンドします。また、これまで加えていた鏡面反射光強度 ispec は削除します。

```cpp
  vec3 r = reflect(v, n);
  
  // 正反射方向の色
  vec4 s = sample(r, 0);
  
  // 画素の陰影を求める
  fresnel.a = 0.0;
  fc = mix(albedo * idiff / float(diffuseSamples), s, fresnel);
```

## 陰影がちょっとはっきりしなくなりましたが、地面が天空光を受けて明るくなっています (光源はこれまで視点側にありました)。

## ![ライブ放射照度マッピング](/images/20161231_6.jpg)

<ul>
<li>[ライブビデオで放射照度マッピング行うプログラム](https://github.com/tokoik/irmap/tree/irradiance)</li>
</ul>

## 環境マップのフィルタリング

ライブビデオを光源環境に用いて放射照度マッピングを行うのに加えて、正反射方向を表面粗さに合わせてサンプリングして、ぼけた映り込みを実現します。正反射方向をサンプリングする範囲は法線方向より狭くなるので、正反射方向のサンプリング数は法線方向より減らしても構わないと思います。以下のプログラム ([main.cpp](https://github.com/tokoik/irmap/blob/specular/irmap/main.cpp)) では、とりあえず 16 (specularSamples) にしています。ボケの量も少ないので、ミップマップのレベルも少し下げて 3 くらいにしてみます。

```cpp
#include <iostream>
#include <vector>
 
// ウィンドウ関連の処理
#include "Window.h"
 
...
 
// 法線方向のサンプル数
const GLsizei diffuseSamples(32);
 
// 法線方向のミップマップのレベル
const GLint diffuseLod(5);
 
// 正反射方向のサンプル数
const GLsizei specularSamples(16);
 
// 正反射方向のミップマップのレベル
```

## 正反射方向の環境のテクスチャをサンプリングする点の数とミップマップのレベルの uniform 変数の場所を得ておきます。

```cpp
  const auto colorLoc(glGetUniformLocation(pass2, "color"));
  const auto imageLoc(glGetUniformLocation(pass2, "image"));
  const auto diffuseSamplesLoc(glGetUniformLocation(pass2, "diffuseSamples"));
  const auto diffuseLodLoc(glGetUniformLocation(pass2, "diffuseLod"));
  const auto specularSamplesLoc(glGetUniformLocation(pass2, "specularSamples"));
```

## 正反射方向の環境のテクスチャをサンプリングする点の数とミップマップのレベルをシェーダプログラムに渡します。

```cpp
  while (!window.shouldClose())
  {
    ...
    
    // 法線方向のサンプル点の数を設定する
    glUniform1i(diffuseSamplesLoc, diffuseSamples);
    
    // ミップマップのレベルを設定する
    glUniform1i(diffuseLodLoc, diffuseLod);
    
    // 正反射方向のサンプル点の数を設定する
    glUniform1i(specularSamplesLoc, specularSamples);
    
    // 正反射方向のミップマップのレベルを設定する
    glUniform1i(specularLodLoc, specularLod);
    
    // 矩形を描く
    glBindVertexArray(rectangle);
    glDrawArrays(`GL_TRIANGLE_STRIP`, 0, 4);
    
    // カラーバッファを入れ替えてイベントを取り出す
    window.swapBuffers();
  }
```

## 二回目のパスのフラグメントシェーダ [pass2.frag](https://github.com/tokoik/irmap/blob/specular/irmap/pass2.frag) に、正反射方向の環境テクスチャをサンプリングする処理を追加します。正反射方向の環境のテクスチャをサンプリングする点の数とミップマップのレベルを受け取る uniform 変数を宣言を追加します。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass2.frag
//
//   フレームバッファオブジェクトの内容を描画するシェーダ
//
 
#define NONE      0
#define PANORAMA  1
#define FISHEYE   2
#define THETA     3
#define MODE THETA
 
// カラーのレンダーターゲットのテクスチャ
uniform sampler2D color[4];
 
// 環境のテクスチャ
uniform sampler2D image;
 
// 法線方向のサンプル点の数
uniform int diffuseSamples;
 
// 法線方向のミップマップのレベル
uniform int diffuseLod;
 
// 正反射方向のサンプル点の数
uniform int specularSamples;
 
// 正反射方向のミップマップのレベル
```

## 鏡面反射係数が格納されている fresnel のアルファ値には 128 分の 1 した輝き係数が格納されているので、これを使うときには 128 倍します。分子と分母の両方を、この 128 分の 1 にしてもよいと思います。

```cpp
  vec4 idiff = vec4(0.0);
  
  // 法線側の個々のサンプル点について
  for (int i = 0; i < diffuseSamples; ++i)
  {
    // サンプル点を生成する
    vec4 d = sampler(seed, 0.5);
    
    // サンプル点を法線側に回転する
    vec3 l = m * d.xyz;
    
    // 法線側のサンプル点方向の色を累積する
    idiff += sample(l, diffuseLod);
  }
  
  // 鏡面反射の正規化係数
```

## 正反射方向の環境のテクスチャをサンプリングする点を生成します。これは正反射方向の確率密度関数を求め、逆関数法によりサンプル点を生成する必要があります。でも、もう考えるのがめんどくさくなってきたので、サンプル点を法線方向に生成して回転行列を乗じ、それを法線に使って GLSL の組み込み関数 [reflect()](https://www.opengl.org/sdk/docs/man4/html/reflect.xhtml) により視線の正反射方向を求めます。

<blockquote>だったら何も Phong のモデルを使わなくても、正規分布でも [Beckmann 分布](http://asura.iaigiri.com/OpenGL/gl30.html)でも構わんわけで、正規分布なら乱数発生に [Box-Muller 法](http://aidiary.hatenablog.com/entry/20140706/1404646793)が使えますし、そうするとこれは放射照度の算出方法とは別の処理になるので、放射照度の方は exp() を使わずとも sqrt() で決め打ちして構わないということになります。そこで、いろいろ無駄なことしてるなと空を仰ぎ見ます。</blockquote>

## ![環境マップのフィルタリング](/images/20161231_14.jpg)

## これにより環境のテクスチャをサンプリングして、得られた色を ispec に合計します。

```cpp
  vec4 ispec = vec4(0.0);
  
  // 正反射側の個々のサンプル点について
  for (int i = 0; i < specularSamples; ++i)
  {
    // サンプル点の生成
    vec4 s = sampler(seed, e);
    
    // サンプル点を法線側に回転したものを法線ベクトルに用いて正反射方向を求める
    vec3 r = reflect(v, m * s.xyz);
    
    // 正反射側のサンプル点方向の色を累積する
    ispec += sample(r, specularLod);
```

## 鏡面反射光強度を、正反射側のサンプル点方向の色を累積した ispec の平均に置き換えます。

```cpp
  fresnel.a = 0.0;
  fc = mix(albedo * idiff / float(diffuseSamples), ispec / float(specularSamples), fresnel);
```

## ![ライブ環境マップのフィルタリング](/images/20161231_7.jpg)

<ul>
<li>[ライブビデオで環境マップのフィルタリングを行うプログラム](https://github.com/tokoik/irmap/tree/specular)</li>
</ul>

## 環境遮蔽 (Ambient Occlusion) と反射遮蔽 (Reflection Occlusion)

環境遮蔽を実現します。また映り込みに対しても occlusion を考慮します。 [SSAO (Screen Space Ambient Occlusion)]({{ site.baseurl }}{% post_url 2010-11-22-post %}) は環境光が物体表面の局所形状によって遮られることによって発生する陰影をスクリーン空間上で再現する手法です。以前は CryEngine 2 の手法<%=fn "Mittring, M. (2007, August). Finding next gen: Cryengine 2. In ACM SIGGRAPH 2007 courses (pp. 97-121). ACM." %> ([PDF](https://developer.amd.com/wordpress/media/2013/02/Chapter8-Mittring-Finding_NextGen_CryEngine2.pdf), [PPT](http://crytek.com/cryengine/presentations/finding-next-gen-cryengine--2)) について解説しましたが、今回は StarCraft II の方法<%=fn "Filion, D., & McNaughton, R. (2008, August). Effects & techniques. In ACM SIGGRAPH 2008 Games (pp. 133-164). ACM." %> ([PDF](https://developer.amd.com/wordpress/media/2013/01/Chapter05-Filion-StarCraftII.pdf)), [PPT](http://amd-dev.wpengine.netdna-cdn.com/wordpress/media/2012/10/S2008-Filion-McNaughton-StarCraftII.pdf)) を使いました。でも、たぶん他の方法を使った方がいいと思います。これついては [アンビエントオクルージョンちゃん](http://ambientocclusion.hatenablog.com/)が[詳しく説明](http://ambientocclusion.hatenablog.com/entry/2013/11/07/152755)してくれています。
Ambient Occulusion は物体表面の局所形状の環境光に対する影響を見積もりますが、今回は天空光による放射照度への影響を求めます。放射照度の算出に用いたサンプル点を、局所形状による遮蔽の検出にも使います。サンプル点は単位球の表面上に散布していますが、その中心からの距離も変化させます。([main.cpp](https://github.com/tokoik/irmap/blob/ssao/irmap/main.cpp)) では、まず、その最大値 (散布半径) を決めておきます。これは物体のスケールや表面形状の複雑さにもとづいて適当に決定します。

```cpp
#include <iostream>
#include <vector>
 
// ウィンドウ関連の処理
#include "Window.h"
 
...
 
// 法線方向のサンプル数
const GLsizei diffuseSamples(32);
 
// 法線方向のミップマップのレベル
const GLint diffuseLod(5);
 
// 正反射方向のサンプル数
const GLsizei specularSamples(16);
 
// 正反射方向のミップマップのレベル
const GLint specularLod(3);
 
// サンプル点の散布半径
```

## Ambient Occulusion では、OpenGL のシャドウマッピングの機能を使います。陰影を決定するフラグメントの周囲にサンプル点を散布し、それがその点におけるデプスバッファの値より小さければ、その点は「日向」にあるとします。ここでは、その延長方向の天空の放射輝度を取得します。

## ![法線方向の遮蔽](/images/20161231_15.jpg)

## そのため、フレームバッファオブジェクトのデプスバッファに用いるテクスチャに対して、テクスチャ座標の xy の位置にある内容 (深度) を取り出す代わりに、その値とテクスチャ座標の z 値を比較して (`GL_COMPARE_REF_TO_TEXTURE`)、テクスチャ座標の z の方が小さければ真 (1)、大きければ偽 (0) を返すようにします (`GL_LEQUAL`)。

```cpp
  const auto depth([] { GLuint t; glGenTextures(1, &t); return t; } ());
  glBindTexture(`GL_TEXTURE_2D`, depth);
  glTexImage2D(`GL_TEXTURE_2D`, 0, `GL_DEPTH_COMPONENT`, fboWidth, fboHeight, 0, `GL_DEPTH_COMPONENT`, `GL_FLOAT`, NULL);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_MAG_FILTER`, `GL_LINEAR`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_MIN_FILTER`, `GL_LINEAR`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_WRAP_S`, `GL_CLAMP_TO_BORDER`);
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_WRAP_T`, `GL_CLAMP_TO_BORDER`);
  
  // 書き込むポリゴンのテクスチャ座標値のＲとテクスチャとの比較を行うようにする
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_COMPARE_MODE`, `GL_COMPARE_REF_TO_TEXTURE`);
  
  // もしＲの値がテクスチャの値以下なら真 (すなわち日向)
  glTexParameteri(`GL_TEXTURE_2D`, `GL_TEXTURE_COMPARE_FUNC`, `GL_LEQUAL`);
  
  // デプスマップの境界色はデプスの最大値 (1) にする
  static const GLfloat depthBorder[] = { 1.0f, 1.0f, 1.0f, 1.0f };
```

## シェーダには、このテクスチャ (デプスマップ) depth と前述のサンプル点の散布半径 radius、および投影変換行列 mp を uniform 変数で渡します。

```cpp
  const auto colorLoc(glGetUniformLocation(pass2, "color"));
  const auto imageLoc(glGetUniformLocation(pass2, "image"));
  const auto depthLoc(glGetUniformLocation(pass2, "depth"));
  const auto radiusLoc(glGetUniformLocation(pass2, "radius"));
  const auto mpLoc(glGetUniformLocation(pass2, "mp"));
  const auto diffuseSamplesLoc(glGetUniformLocation(pass2, "diffuseSamples"));
  const auto diffuseLodLoc(glGetUniformLocation(pass2, "diffuseLod"));
  const auto specularSamplesLoc(glGetUniformLocation(pass2, "specularSamples"));
```

## 描画ループ内でこれらの値をシェーダに渡します。デプスマップについては、ほかのテクスチャとテクスチャユニットが重ならないようにします。

```cpp
  while (!window.shouldClose())
  {
    ...
    
    // 法線方向のサンプル点の数を設定する
    glUniform1i(diffuseSamplesLoc, diffuseSamples);
    
    // ミップマップのレベルを設定する
    glUniform1i(diffuseLodLoc, diffuseLod);
    
    // 正反射方向のサンプル点の数を設定する
    glUniform1i(specularSamplesLoc, specularSamples);
    
    // 正反射方向のミップマップのレベルを設定する
    glUniform1i(specularLodLoc, specularLod);
    
    // デプスマップを指定する
    glUniform1i(depthLoc, colorCount + 1);
    glActiveTexture(`GL_TEXTURE0` + colorCount + 1);
    glBindTexture(`GL_TEXTURE_2D`, depth);
    
    // サンプル点の散布半径を設定する
    glUniform1f(radiusLoc, radius);
    
    // 投影変換行列を設定する
    glUniformMatrix4fv(mpLoc, 1, `GL_FALSE`, mp.get());
    
    // 矩形を描く
    glBindVertexArray(rectangle);
    glDrawArrays(`GL_TRIANGLE_STRIP`, 0, 4);
    
    // カラーバッファを入れ替えてイベントを取り出す
    window.swapBuffers();
```

## 二回目のパスのフラグメントシェーダ ([pass2.frag](https://github.com/tokoik/irmap/blob/ssao/irmap/pass2.frag)) では、デプスマップ depth、サンプル点の散布半径 radius、および投影変換行列 mp を受け取る uniform 変数を宣言します。デプスマップのサンプラ depth はシャドウマップ用の sampler2DShadow を用いて宣言します。

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
//
// pass2.frag
//
//   フレームバッファオブジェクトの内容を描画するシェーダ
//
 
...
 
// ラスタライザから受け取る頂点属性の補間値
in vec2 texcoord;                                     // テクスチャ座標
 
// フレームバッファに出力するデータ
layout (location = 0) out vec4 fc;                    // フラグメントの色
 
// カラーのレンダーターゲットのテクスチャ
uniform sampler2D color[4];
 
// デプスマップ
uniform sampler2DShadow depth;
 
// サンプル点の散布半径
uniform float radius;
 
// 投影変換行列
```

## サンプル点を生成する際に、w 要素にも最大値が radius の乱数を格納しておきます。これを一様乱数にすれば、サンプル点の密度は中心からの距離の二乗に反比例します。

```cpp
vec4 sampler(inout uint seed, in float e)
{
  float z = pow(xorshift(seed), e);
  float r = sqrt(1.0 - z * z);
  float t = 6.2831853 * xorshift(seed);
  vec3 s = normalize(vec3(vec2(cos(t), sin(t)) * r, z));
  return vec4(s, radius * xorshift(seed));
  //return vec4(s, radius * pow(xorshift(seed), 0.33333333));
```

## そのフラグメントの視点座標系における位置 p に、サンプル点の位置にその w 要素、すなわちそのサンプル点の中心からの距離を掛けたものを加え、投影変換行列を乗じてクリッピング座標系の位置を求めます。クリッピング座標系の範囲は x, y, z とも [-1, 1] なので、0.5 倍して 0.5 を足して [0, 1] のテクスチャ座標系の位置に変換します。これを sampler2DShadow のサンプラ depth でサンプリングすれば、z 値がデプスマップより小さければ 1、大きければ 0 が返りますから、天空マップから得た放射輝度にこれを乗じます。

```cpp
  uint seed = rand(gl_FragCoord.xy);
  //uint seed = 2463534242u;
  
  // 放射照度
  vec4 idiff = vec4(0.0);
  
  // 法線側の個々のサンプル点について
  for (int i = 0; i < diffuseSamples; ++i)
  {
    // サンプル点を生成する
    vec4 d = sampler(seed, 0.5);
    
    // サンプル点を法線側に回転する
    vec3 l = m * d.xyz;
    
    // サンプル点の位置を p からの相対位置に平行移動した後その点のクリッピング座標系上の位置 q を求める
    vec4 q = mp * vec4(p + l * d.w, 1.0);
    
    // テクスチャ座標に変換する
    q = q * 0.5 / q.w + 0.5;
    
    // q の深度がデプスマップ (depth) の値より小さければ法線側のサンプル点方向の色を累積する
    idiff += sample(l, diffuseLod) * texture(depth, q.xyz);
```

## 正反射方向についても同じ処理をします。これにより、映り込みにも局所的な形状の影響を反映することができます。

## ![正反射方向の遮蔽](/images/20161231_16.jpg)

```cpp
  float e = 1.0 / (fresnel.a * 128.0 + 1.0);
  
  // 鏡面反射
  vec4 ispec = vec4(0.0);
  
  // 正反射側の個々のサンプル点について
  for (int i = 0; i < specularSamples; ++i)
  {
    // サンプル点の生成
    vec4 s = sampler(seed, e);
    
    // サンプル点を法線側に回転したものを法線ベクトルに用いて正反射方向を求める
    vec3 r = mat3(mt) * reflect(v, m * s.xyz);
    
    // サンプル点の位置を p からの相対位置に平行移動した後その点のクリッピング座標系上の位置 q を求める
    vec4 q = mp * vec4(p + r * s.w, 1.0);
    
    // テクスチャ座標に変換する
    q = q * 0.5 / q.w + 0.5;
    
    // q の深度がデプスマップ (depth) の値より小さければ正反射側のサンプル点方向の色を累積する
    ispec += sample(r, specularLod) * texture(depth, q.xyz);
```

## ![ライブ環境遮蔽と反射遮蔽](/images/20161231_8.jpg)

<ul>
<li>[ライブビデオで環境遮蔽と反射遮蔽を行うプログラム](https://github.com/tokoik/irmap/tree/ssao)</li>
</ul>

<blockquote class="twitter-tweet tw-align-center" data-conversation="none" data-lang="ja"><p lang="ja" dir="ltr">背景を合成してみた [pic.twitter.com/2kusrRB2Gi](https://t.co/2kusrRB2Gi)</p>— 床井浩平 (@tokoik) [2017年1月5日](https://twitter.com/tokoik/status/816933655469694976)</blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

## (AO が暗すぎることを含め、まだ修正すると思います。ごめんなさい。[GitHub](https://github.com/tokoik/irmap) でブランチ間の差分を見れば、何をしているかわかると思います。)
