---
title: "第７回 カメラパラメータ"
date: 2009-09-07
categories: [OpenGL,GLSL,ゼミ]
published: true
---

## レンズの画角

スクリーン上の表示領域を指定して視野錐台を設定する方法は, 柔軟ですが, 直感的に理解しやすいとは言えません. そこで, カメラの投影方法にならって透視投影の変換行列を決める方法が用いられます. 現実のカメラではスクリーン (フィルムや撮像素子) の大きさが固定されてるので, スクリーンに投影される範囲は (`near` に相当する) レンズの焦点距離によって決まります. しかし, コンピュータでは決まった大きさのスクリーンを想定する必要がありませんから, スクリーンの大きさに依存しない方法としてレンズの画角 (field of view - fov ですが, ここでは `fovy` とします) を用います.

## スクリーン上の表示領域

レンズの画角から視野錐台の left, right, bottom, top を決定します. `aspect` は表示領域の縦横比 (表示領域の高さに対する幅の割合) です. 通常はビューポートの縦横比と一致させることが多いようです.

![画角と前方面の関係]({{ site.baseurl }}/assets/images/camera.gif)

## 視線は表示領域の中心を通っているので, left = -right, bottom = -top です. 視点とスクリーン (前方面) との距離は `near` なので, top は次式で求めることができます.

![画角から表示領域の大きさを求める]({{ site.baseurl }}/assets/images/cameramatrix0.gif)

## これを視野錐台にもとづく[透視投影変換行列]({% post_url 2009-08-29-post %})に代入します.

![投影変換行列の要素に代入]({{ site.baseurl }}/assets/images/cameramatrix1.gif)

## これにより, 次のような透視投影変換行列が得られます.

![画角から求めた投影変換行列]({{ site.baseurl }}/assets/images/cameramatrix2.gif)

## それでは, 画角 `fovy`, 表示領域の縦横比 `aspect`, 前方面の位置 `near`, 後方面の位置 `far` を指定して透視投影変換行列を作成し, 引数 `matrix` に与えられた配列に格納する関数 `cameraMatrix()` を作成してください. なお, 画角が弧度法 (radian) だとわかりにくいので, `fovy` は度数法 (degree, 度) で指定できるようにしてください.

```c
/*
** 画角から透視投影変換行列を求める
*/
void cameraMatrix(float fovy, float aspect, float near, float far,
GLfloat *matrix)
{
/* この部分を考えましょう */
}
```

<ul>
<li>[【解答例】](summer/camera.txt)</li>
</ul>

## この関数も orthogonalMatrix() と同じファイルに書いておきましょう.

## 画角を指定した透視投影

それでは, perspectiveMatrix() をこの `cameraMatrix()` に置き換えて, 透視投影により図形を描いてください. `fovy` は 30 度, `aspect` は 1 としてください. また `far` と `near` には以前の値を使用してください. あと, メインプログラムの先頭部分に `cameraMatrix()` の宣言を書くのを忘れないでください. これで下のような図形が描かれれば OK です.

![画角を指定して描画]({{ site.baseurl }}/assets/images/camera_result.gif)

## 時間が余ったら立方体を描いてみて. あと[前回]({% post_url 2009-09-02-post %})の lookAt() が間違っていたから, これも修正しといてくんろ.

<ul>
<li>[Linux 版](summer/summer04.tar.gz)</li>
<li>[Mac OS X 版](summer/summer04.zip)</li>
<li>[Windows 版](summer/summer04.lzh)</li>
</ul>
