---
title: "第１３回 キューブマッピングでテクスチャを回転"
date: 2005-01-31
categories: [OpenGL,テクスチャ]
published: true
---

## テクスチャの回転

[前回]({% post_url 2005-01-21-post %})は2004年末に[タイヤを回して]({% post_url 2004-09-17-texture %})以来恒例？となっていた「テクスチャの回転」を止めてしまいましたけど，実はキューブマッピングは，スフィアマッピングよりもずっとテクスチャを回すのが得意（謎）だったりします．スフィアマッピングでは[視線を軸にテクスチャを回す]({% post_url 2005-01-14-post %})のが関の山だったんですけど，キューブマッピングではテクスチャをトラックボールのようにぐるぐる回しても平気なんですね．

## テクスチャ座標の補間

スフィアマッピングでは，テクスチャ座標の補間を (s, t) の２次元で行っていました．したがって法線ベクトルや反射光ベクトルを求めるには，この２軸の補間結果から残りの１軸の値を求める必要がありました．しかしこの方法では，この残りの１軸の符号を決めることができません．スフィアマッピングにおいてテクスチャ座標がテクスチャの周辺部で狂うという現象は，これが原因になっています（多分…）．
これに対してキューブマッピングでは，テクスチャ座標を (s, t, r) の３軸について補間します．つまり，ごく普通に反射ベクトルや法線ベクトルの補間を行っています．そして得られた法線ベクトルが６枚のテクスチャのうちどれに向かっているのかを調べ，そのテクスチャをサンプリングします．
したがって，このテクスチャ座標に回転の変換を施せば，テクスチャを任意の方向に回転することができます．それでは試しにやってみましょう．今回は[前回]({% post_url 2005-01-21-post %})作ったキューブマッピングのプログラムを雛形にします．

<ul>
<li>[Linux 版](texture/texture7.tar.gz)</li>
<li>[Mac OS X 版](texture/texture7.zip)</li>
<li>[Windows 版](texture/texture7.lzh)</li>
</ul>

## テクスチャ座標の回転再開

まず，前回止めてしまったテクスチャ座標の回転を再開します．ただし，今回は視線の軸を中心に回転するのではなく，図形をぐるぐる回すのに使っているトラックボール式の回転を使うことにします．

```c
...

/****************************
** GLUT のコールバック関数 **
****************************/

/* トラックボール処理用関数の宣言 */

#include "trackball.h"

static void display(void)

{
/* テクスチャ変換行列の設定 */
glMatrixMode(GL_TEXTURE);
glLoadIdentity();

/* トラックボール処理による回転 */
glMultMatrixd(trackballRotation());

/* モデルビュー変換行列の設定 */

glMatrixMode(GL_MODELVIEW);
glLoadIdentity();
```

## そんでもって，図形自体は回転しないようにしておきます．ややこしいので．

```c
/* 光源の位置を設定 */
glLightfv(GL_LIGHT0, GL_POSITION, lightpos);

/* 視点の移動（物体の方を奥に移動）*/

glTranslated(0.0, 0.0, -3.0);

#if 0
/* トラックボール処理による回転 */
glMultMatrixd(trackballRotation());
#endif

/* 画面クリア */

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

/* シーンの描画 */

scene();

/* ダブルバッファリング */

glutSwapBuffers();
}
```

## これだけです．もちろん，#if 0 〜 #`endif` の行は削除してしまっても構いません．

<div class="figure">
![部屋の正面が映っている]({{ '/assets/images/cubemap4.jpg' | relative_url }})
![部屋の左側が映っている]({{ '/assets/images/cubemap5.jpg' | relative_url }})
</div>

<ul>
<li>[Linux 版](texture/texture8.tar.gz)</li>
<li>[Mac OS X 版](texture/texture8.zip)</li>
<li>[Windows 版](texture/texture8.lzh)</li>
</ul>
