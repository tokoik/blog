---
title: "GL_SEPARATE_SPECULAR_COLOR"
date: 2008-08-20
categories: [OpenGL,テクスチャ]
published: true
---

## シス工猫その後

２年前くらいから大学のキャンパスのシステム工学部付近に住み着いている[シス工猫]({% post-url 2006-04-27-post %})ですが，今もなんとか生き延びているようです．ただ，この盆休みに食べ物にありつけなかったのか，とても飢えているようです．コロコロとした体格の猫なんですが，お腹の辺りがへこんでいました．よく見ると，後ろ足の付け根あたりに２センチくらいの怪我もしています．ちょっとかわいそうに思えたので，こっそりおやつをあげました．

![シス工猫]({{ '/assets/images/cat2.jpg' | relative_url }})

## 書き忘れ

[テクスチャマッピング入門]({% post-url 2004-09-13-post %})を後から読んでみて，書き忘れたことがいくつもあるなぁと思ったので，思いついたことを書きとめておこうと思います．今回は `GL_SEPARATE_SPECULAR_COLOR` について書きます．この機能は[スフィアマッピングで Phong シェーディング]({% post-url 2005-01-14-post %})で使っているのですが，本来の使い道はテクスチャマッピングの時にハイライトをきれいに出すことにあります．

## `GL_MODULATE` とテクスチャマッピング

OpenGL の陰影付けは，頂点における陰影を計算した後，その線形補間によりポリゴン内の画素の陰影を求めます（グーローのスムーズシェーディング）．通常，頂点における陰影は，拡散反射光成分（および環境光成分と自己発光成分）と鏡面反射光成分を合計して求めます．したがって，ポリゴン内の陰影値はこの合計値を線形補間して求めることになります．
テクスチャをマッピングした物体に陰影を付ける場合，求めたポリゴンの陰影によってテクスチャの明度を [`GL_MODULATE`]({% post-url 2004-09-15-post %}) により変調します．しかし，こうすると元々のポリゴンの陰影に含まれるハイライト（鏡面反射光成分）もテクスチャの変調に使われてしまい，ハイライトにもテクスチャがマッピングされてしまいます．ハイライトは光源の映り込みであり，光源の光が物体内部に侵入せずに物体表面で正反射したものととらえられますから，ハイライトにはテクスチャ等で与えられた物体の表面の色を反映させたくない場合もあります．

## `GL_SEPARATE_SPECULAR_COLOR`

[`glLightModeli()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glLightModeli.xhtml) を使って `GL_LIGHT_MODEL_COLOR_CONTROL` に `GL_SEPARATE_SPECULAR_COLOR` を設定する（デフォルト値は `GL_SINGLE_COLOR`）と，頂点の陰影の拡散反射光成分（および環境光成分と自己発光成分）と鏡面反射光成分を別々に補間するようになります．そして，テクスチャをマッピングしたときには，拡散反射光成分（および環境光成分と自己発光成分）によりテクスチャの明度を変調し，鏡面反射光成分はそれに加算されるようになります．これによりハイライトがテクスチャの影響を受けなくなります．

## 試してみる

まず，球にハイライトを付けてレンダリングしてみます．この球には後でテクスチャをマッピングしますが，glutSolidSphere() ではテクスチャ座標が生成されないため，ここではテクスチャ座標を生成できる gluSphere() を使用します．

![球に鏡面反射光をつけて陰影付け]({{ '/assets/images/sepspec1.jpg' | relative_url }})

## これに次のようなテクスチャを `GL_MODULATE` によりマッピングします．

![球にマッピングするテクスチャ]({{ '/assets/images/sepspec2.jpg' | relative_url }})

## すると，次のような陰影が得られます．

![球にテクスチャをマッピングして陰影付け]({{ '/assets/images/sepspec3.jpg' | relative_url }})

## この状態では下地の色（ポリゴンの陰影）そのものでテクスチャの明度が変調されており，ハイライト部分もそのままテクスチャの明度の変調に使われています．そこで，光源の設定の段階で [`glLightModeli()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glLightModeli.xhtml) を使って `GL_LIGHT_MODEL_COLOR_CONTROL` に `GL_SEPARATE_SPECULAR_COLOR` を設定します．

```c
/* 拡散反射光と鏡面反射光を別々に補間する */
glLightModeli(GL_LIGHT_MODEL_COLOR_CONTROL, GL_SEPARATE_SPECULAR_COLOR);
```

## こうすると，拡散反射光成分（および環境光成分と自己発光成分）と鏡面反射光成分が別々に補間され，陰影の拡散反射光成分（および環境光成分と自己発光成分）により変調されたテクスチャの色に，鏡面反射光成分が加算されるようになります．

![`GL_SEPARATE_SPECULAR_COLOR` を使った場合]({{ '/assets/images/sepspec4.jpg' | relative_url }})

<ul>
<li>[Linux 版](texture/sepspec.tar.gz)</li>
<li>[Mac OS X 版](texture/sepspec.zip)</li>
<li>[Windows 版](texture/sepspec.lzh)</li>
</ul>
