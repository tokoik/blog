---
title: "GL_CLAMP_TO_EDGE, GL_CLAMP_TO_BORDER"
date: 2008-08-22
categories: [OpenGL,テクスチャ]
published: true
---

## CLAMP

朝日新聞の火曜日の夕刊に連載されている「熱血！マンガ学」というマンガ評を結構楽しみにしているんですが，今週は CLAMP の「カードキャプターさくら」でした．「年齢や性別を超えたつらく切ない恋も描かれる」と評されていましたが，私が子供の本を借りて読んだときは，「これを小学生相手に描くにはちょっと難しいんと違うか？」と思える部分がありました．少女漫画も進化したもんだ．そう言えばこの映画を見に行ったとき（子供連れて行ったんだよ），自分と同じような家族連れに混じって，大学生くらいの男の子のグループをちらほら見かけました．見る方も年齢や性別を超えてるんですね．

## `GL_CLAMP` の問題

CLAMP つながりというわけではないんですが（狙ってましたが），書き忘れたと思っていたことの三つ目です．ポリゴンにテクスチャをマッピングする際，テクスチャの拡大縮小に線形補間（`GL_LINEAR` 等）を指定したとします．

```c
/* テクスチャを拡大・縮小する方法の指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
```

## このときテクスチャの繰り返しに `GL_CLAMP` を指定して

```c
/* テクスチャの繰り返しの指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
```

## こういうテクスチャ

![マッピングするテクスチャ]({{ site.baseurl }}/assets/images/clamp0.gif)

## をこういうポリゴン

![マッピングするポリゴン]({{ site.baseurl }}/assets/images/clamp1.gif)

## の中央部分に周囲を余らせてマッピングすると，こういうことになってしまいます．

![`GL_CLAMP` でマッピングした結果]({{ site.baseurl }}/assets/images/clamp2.gif)

## `GL_CLAMP` ではテクスチャの範囲外をサンプリングしたとき，テクスチャの最外周の色を拡張して用います．テクスチャの拡大縮小に最近傍法（`GL_NEAREST`）を用いているときは，テクスチャ画像の最外周の画素の色がそのまま用いられるため，その色が拡張されてマッピングされます．

ところがテクスチャの拡大縮小に線形補間（`GL_LINEAR` 等）を用いた場合には，テクスチャの最外周の色が，テクスチャ画像の最外周の画素の色と，テクスチャの境界色とを混合したものになります．このため，この場合は拡張された部分の色が，テクスチャ画像の最外周の画素の色と異なってしまいます．

![`GL_CLAMP` によるサンプリング範囲]({{ site.baseurl }}/assets/images/clamp3.gif)

## `GL_CLAMP_TO_EDGE`

`GL_CLAMP` はサンプリングするテクスチャ座標を [0,1] の範囲にクランプする（範囲内に収める）のですが，`GL_CLAMP_TO_EDGE` では [1/(2N),1-1/(2N)]（N はテクスチャの画素数）の範囲にクランプします．

```c
/* テクスチャの繰り返しの指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
```

![`GL_CLAMP_TO_EDGE` によるサンプリング範囲]({{ site.baseurl }}/assets/images/clamp4.gif)

## こうすることでサンプリングされるテクスチャの範囲が `GL_CLAMP` の範囲より 1/2 画素分内側になって，最外周の色が境界色の影響を受けなくなります．

![`GL_CLAMP_TO_EDGE` でマッピングした結果]({{ site.baseurl }}/assets/images/clamp5.gif)

## `GL_CLAMP_TO_BORDER`

一方 `GL_CLAMP_TO_BORDER` では，サンプリングするテクスチャ座標を [-1/(2N),1+1/(2N)]（N はテクスチャの画素数）の範囲にクランプします．

```c
/* テクスチャの繰り返しの指定 */
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_BORDER);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_BORDER);
```

![`GL_CLAMP_TO_EDGE` によるサンプリング範囲]({{ site.baseurl }}/assets/images/clamp6.gif)

## こうすることでサンプリングされるテクスチャの範囲が `GL_CLAMP` の範囲より 1/2 画素分外側になって，最外周の色が境界色そのものになります．

![`GL_CLAMP_TO_EDGE` でマッピングした結果]({{ site.baseurl }}/assets/images/clamp7.gif)

## 境界色の指定

なお，境界色は `GL_TEXTURE_BORDER_COLOR` で指定できます．

```c
/* テクスチャの境界色 */
static const GLfloat border[] = { 0.0, 1.0, 0.0, 1.0 };

...

/* テクスチャの境界色 */

glTexParameterfv(GL_TEXTURE_2D, GL_TEXTURE_BORDER_COLOR, border);
```

## この場合，境界色は次のようになります．

![`GL_TEXTURE_BORDER_COLOR` で境界色を指定した場合]({{ site.baseurl }}/assets/images/clamp8.gif)
