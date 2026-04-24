---
title: "ゼブラパターンの映り込み"
date: 2010-01-31
categories: [OpenGL,GLSL]
published: true
---

## 曲面の評価

風邪ひいて寝転がっていてふと思いついたのでメモ．原田研のひろぴこさんが曲面を評価するときに縞模様 (ゼブラパターン) の映り込みを表示してましたけど, これは [GLSL による環境マッピング]({% post_url 2008-12-20-post %})のフラグメントシェーダのプログラムを以下のように書き換えるだけで実現できます. (2月1日 車の画像を追加)

```c
// reflect.frag

varying vec3 r;  // 視線の反射ベクトル

void main(void)

{
gl_FragColor = vec4(step(0.5, fract(2.0 * r.z / r.y)));
}
```

## これは平面上に縞模様を貼付けた場合です. 初期値は y 軸と直交した平面ですが, マウスの右ボタンで動かすことができます. 定数の 2.0 は縞模様の密度です. 下図は不要なものを削除しています.

<div class="figure">
![縞模様を平面に貼付けた場合 (1)]({{ site.baseurl }}/assets/images/zebra0.gif)
![縞模様を平面に貼付けた場合 (2)]({{ site.baseurl }}/assets/images/zebra1.gif)
</div>
<div class="figure">
![縞模様を平面に貼付けた場合 (3)]({{ site.baseurl }}/assets/images/zebra2.gif)
![縞模様を平面に貼付けた場合 (4)]({{ site.baseurl }}/assets/images/zebra3.gif)
</div>

## ただ, これだと r.y = 0 に近い面の縞模様がぐしゃぐしゃになるので, かわりに次のように書き換えてもいいのではないかと思います.

```c
// reflect.frag

varying vec3 r;  // 視線の反射ベクトル

void main(void)

{
gl_FragColor = vec4(step(0.5, fract(2.0 * atan(r.z, r.y))));
}
```

## この場合は円柱面上に縞模様を貼付けたことになります. 初期値は x 軸を中心軸とする円柱面ですが, これもマウスの右ボタンで動かすことができます. 定数の 2.0 は縞模様の密度です.

<div class="figure">
![縞模様を円柱面に貼付けた場合 (1)]({{ site.baseurl }}/assets/images/zebra4.gif)
![縞模様を円柱面に貼付けた場合 (2)]({{ site.baseurl }}/assets/images/zebra5.gif)
</div>
<div class="figure">
![縞模様を円柱面に貼付けた場合 (3)]({{ site.baseurl }}/assets/images/zebra6.gif)
![縞模様を円柱面に貼付けた場合 (4)]({{ site.baseurl }}/assets/images/zebra7.gif)
</div>

## 課題

思いつきで書いているので煮詰まってないところが色々あります. サンプルの bunny はでこぼこなので, 縞模様がだいぶつぶれてしまっています. きれいな縞模様を出すには滑らかな曲面を細かくポリゴンに分割したものを使ってください. これがそのまま使えるとは思いませんけど, 立体視に対応させるとかいろいろ工夫できると思います. ですが今日のところはこれで限界です. また寝ます.
