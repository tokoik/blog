---
title: "髪の毛 (2)"
date: 2015-01-01
categories: [OpenGL,GLSL]
published: true
---

## 元旦

さっきニシンそば食べました. ニシンそば食べるのは京都の風習? それにしても年越しに私なにやってるんだろうね. あけましておめでとうございます.

## 髪の陰影付け

こんなときにブログ書いてたりしたら家の人のご機嫌を損ねる可能性があるので手短に書きます. 元になるのは前回のプログラムです.

<ul>
<li>[力の計算を追加したプログラム](https://github.com/tokoik/hair/tree/step1)</li>
</ul>

## 髪の毛の陰影付け方法には [Marschner のモデル](http://www.graphics.stanford.edu/papers/hair/) 以後いろいろあるらしいんですけど, とりあえず原点とも言える Kajiya-Kay モデルを実装してみます. これは[授業](http://wwww.wakayama-u.ac.jp/~tokoi/lecture/gg/)でも説明しています. 図はこの授業のスライドです. このモデルは髪を円柱でモデル化します.

## ![円柱の反射モデル](/images/20150101_0.jpg)

## 円柱なので, 入射光のせい反射光は, 円柱の軸を中心に円錐状に広がると考えます. 円柱の裏側にも届くのはちょっと不自然な感じがしますけど, そのように考えます<%= fn "このモデルに納得していない人ももちろんいます. " %>. したがって, この反射光強度は拡散反射成分も鏡面反射成分も円柱の軸 <span style="font-weight: bold;">t</span> を用いて求めます.

## ![異方性 BRDF](/images/20150101_1.jpg)

## バーテックスシェーダでは光源の位置を決め, 節点の位置における光線ベクトル l と視線ベクトル v を求めておきます. また, 節点における軸ベクトル t は, その節点の前後の節点を結ぶベクトルにします. 前後の接点の位置はテクスチャバッファオブジェクトを介して取得します.

 
```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
// 定数
const vec4 pl = vec4(1.0, 6.0, 4.0, 1.0);           // 光源位置
 
// 頂点属性
layout (location = 0) in vec4 position;             // 節点のローカル座標系での位置
 
// uniform 変数
uniform mat4 mc;                                    // ビュープロジェクション変換行列
uniform samplerBuffer neighbor;                     // 近傍の節点を取得するテクスチャバッファオブジェクト
uniform ivec2 endpoint;                             // 一本の髪の毛の最初と最後の節点のインデックス
 
// フラグメントシェーダに送る節点の視線・光線・接線ベクトル
out vec3 v, l, t;
 
void main()
{
  // スクリーン座標系の座標値
  gl_Position = mc * position;
  
  // 視線ベクトルは頂点位置の逆ベクトル
  v = -normalize(position.xyz);
  
  // 光線ベクトルは頂点から光源に向かうベクトル
  l = normalize((pl - position * pl.w).xyz);
  
  // 接線ベクトルは処理対象の節点の前の節点から次の節点に向かうベクトル
  t = normalize((texelFetch(neighbor, max(gl_VertexID - 1, endpoint.s)) -
                 texelFetch(neighbor, min(gl_VertexID + 1, endpoint.t))).xyz);
```

## フラグメントシェーダでは補間された光線ベクトル l, 視線ベクトル v, 接線ベクトル t を使って拡散反射光強度と鏡面反射光強度を求めます.

```cpp
#extension GL_ARB_explicit_attrib_location : enable
 
// 光源
const vec4 lamb   = vec4(0.1, 0.1, 0.1, 1.0);       // 環境光成分の強度
const vec4 ldiff  = vec4(1.0, 1.0, 1.0, 0.0);       // 拡散反射成分の強度
const vec4 lspec  = vec4(1.0, 1.0, 1.0, 0.0);       // 鏡面反射成分の強度
 
// 材質
const vec4 kamb   = vec4(0.3, 0.1, 0.0, 1.0);       // 環境光の反射係数
const vec4 kdiff  = vec4(0.3, 0.1, 0.0, 1.0);       // 拡散反射係数
const vec4 kspec  = vec4(0.6, 0.6, 0.6, 1.0);       // 鏡面反射係数
const float kshi  = 80.0;                           // 輝き係数
 
// ラスタライザから受け取る頂点属性の補間値
in vec3 v;                                          // 補間された視線ベクトル
in vec3 l;                                          // 補間された光線ベクトル
in vec3 t;                                          // 補間された接線ベクトル
 
// フレームバッファに出力するデータ
layout (location = 0) out vec4 fc;                  // フラグメントの色
 
void main()
{
  vec3 nv = normalize(v);                           // 視線ベクトル
  vec3 nl = normalize(l);                           // 光線ベクトル
  vec3 nt = normalize(t);                           // 接線ベクトル
  
  // Kajiya-Kay モデルによる陰影付け
  float lt = dot(nl, nt);
  float lt2 = sqrt(1.0 - lt * lt);
  float vt = dot(nv, nt);
  float vt2 = sqrt(1.0 - vt * vt);
  vec4 iamb = kamb * lamb;
  vec4 idiff = lt2 * kdiff * ldiff;
  vec4 ispec = pow(max(lt2 * vt2 - lt * vt, 0.0), kshi) * kspec * lspec;
  
  fc = iamb + idiff + ispec;
```

## バーテックスシェーダで処理対象の節点の近傍の頂点属性を取得するために, 節点の位置の頂点バッファオブジェクトをテクスチャバッファオブジェクトとして参照できるようにします. また, ここでも髪の毛の根元の節点と先端の節点の頂点番号を uniform 変数で渡すようにします.

```cpp
  
  //
  // プログラムオブジェクト
  //
  
  // 描画用のシェーダプログラムを読み込む
  const GLuint hairShader(ggLoadShader("hair.vert", "hair.frag"));
  const GLint hairMcLoc(glGetUniformLocation(hairShader, "mc"));
  const GLint hairNeighborLoc(glGetUniformLocation(hairShader, "neighbor"));
  const GLint hairEndpointLoc(glGetUniformLocation(hairShader, "endpoint"));
  
  ...
  
  //
  // 描画
  //
  
  // 描画する頂点配列バッファ
  int buffer(0);
  
  // ウィンドウが開いている間くり返し描画する
  while (!window.shouldClose())
  {
    // 画面クリア
    window.clear();
    
    // ビュープロジェクション変換行列
    const GgMatrix mc(window.getMp() * window.getMv());
    
    //
    // 通常の描画
    //
    
    // 頂点配列オブジェクトを選択する
    glBindVertexArray(vao[buffer]);
    
    // 描画用のシェーダプログラムを使用する
    glUseProgram(hairShader);
    
    // ビュープロジェクション変換行列を設定する
    glUniformMatrix4fv(hairMcLoc, 1, `GL_FALSE`, mc.get());
    
    // 近傍の頂点の位置のテクスチャオバッファブジェクトのサンプラを指定する
    glUniform1i(hairNeighborLoc, 0);
    
    // 近傍の頂点の位置のテクスチャバッファオブジェクトを結合する
    glActiveTexture(`GL_TEXTURE0`);
    glBindTexture(`GL_TEXTURE_BUFFER`, positionTexture[buffer]);
    
    // 頂点配列を描画する
    for (int i = 0; i < hairNumber; ++i)
    {
      glUniform2i(hairEndpointLoc, first[i], first[i] + count[i] - 1);
      glDrawArrays(`GL_LINE_STRIP`, first[i], count[i]);
    }
    
    // フレームバッファを入れ替える
    window.swapBuffers();
    
```

<ul>
<li>[陰影の計算を追加したプログラム](https://github.com/tokoik/hair/tree/step2)</li>
</ul>

<img class="photo" src="http://marina.sys.wakayama-u.ac.jp/~tokoi/images/20150105_3.png" width="512" height="734" alt="陰影をつけた結果">
