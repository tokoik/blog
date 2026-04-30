---
title: "ステンシルバッファを使った立体視"
date: 2004-02-08
categories: [OpenGL,3D液晶]
published: true
---

## NEC Lavie G Type S

3D液晶を搭載したノートパソコンを導入したので，仕事の合間に[サンプルプログラム](https://gist.github.com/tokoik/4c62bd63e6c080bc68437bb3f2cfaea6)を書いてみました．実行したら，**3Dボタン** を押してください．cとoのキーで視差を調整できます．もし気分が悪くなったら，すぐにやめてください．

## 実装

プログラムは[こういう考え方]({{ site.baseurl }}/assets/pdfs/3dlcd.pdf)で実装してみました．まず，ステンシルバッファに１ピクセルおきに縦の線を描き，これをマスクに使います．`w` と `h` はウィンドウのサイズです．ゲームモード（フルスクリーン）を使うので，これは液晶のサイズになります．`BARRIERBIT` はこのマスクに使うステンシルバッファのビットで，とりあえず 1 です．

```cpp
/* ステンシルバッファだけに必ず描く */
glDisable(GL_DEPTH_TEST);
glDrawBuffer(GL_NONE);

/* ステンシルバッファだけをクリアする */
glClear(GL_STENCIL_BUFFER_BIT);

/* ステンシルバッファの１ビット目に常に書き込む */
glStencilFunc(GL_ALWAYS, BARRIERBIT, BARRIERBIT);
glStencilOp(GL_REPLACE, GL_REPLACE, GL_REPLACE);

/* モデリング変換はしない */
glMatrixMode(GL_MODELVIEW);
glLoadIdentity();

/* スクリーン座標を画面の解像度に合わせて直交投影する */
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glOrtho(-0.5, (GLdouble)w, -0.5, (GLdouble)h, -1.0, 1.0);

/* １画素おきに縦線を描く */
glBegin(GL_LINES);
for (x = 0; x < w; x += 2)
{
  glVertex2d(x, 0);
  glVertex2d(x, h - 1);
}
glEnd();
glFlush();

/* ステンシルバッファにはもう描かない */
glStencilOp(GL_KEEP, GL_KEEP, GL_KEEP);

/* カラーバッファへの描画に戻して隠面消去処理を有効にする */
glDrawBuffer(GL_BACK);
glEnable(GL_DEPTH_TEST);
```

そして，次の手順で右目から見たシーンを描きます．

```cpp
/* RGBA すべてのチャネルとデプスバッファをクリア */
glColorMask(GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE);
glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

/* 奇数ラインにＲ・Ｂを表示 */
glStencilFunc(GL_NOTEQUAL, BARRIERBIT, BARRIERBIT);
glColorMask(GL_TRUE, GL_FALSE, GL_TRUE, GL_TRUE);

//
//（右目の位置を視点にしてシーンを描く）
//

/* 偶数ラインにＧを表示 */
glStencilFunc(GL_EQUAL, BARRIERBIT, BARRIERBIT);
glColorMask(GL_FALSE, GL_TRUE, GL_FALSE, GL_FALSE);

//
//（右目の位置を視点にしてシーンを描く）
//
```

同様にして，左目から見たシーンを描きます．

```cpp
/* カラーバッファを残したままデプスバッファだけをクリア */
glClear(GL_DEPTH_BUFFER_BIT);

/* 偶数ラインにＲ・Ｂを表示 */
glStencilFunc(GL_EQUAL, BARRIERBIT, BARRIERBIT);
glColorMask(GL_TRUE, GL_FALSE, GL_TRUE, GL_TRUE);

//
//（左目の位置を視点にしてシーンを描く）
//

/* 奇数ラインにＧを表示 */
glStencilFunc(GL_NOTEQUAL, BARRIERBIT, BARRIERBIT);
glColorMask(GL_FALSE, GL_TRUE, GL_FALSE, GL_FALSE);

//
//（左目の位置を視点にしてシーンを描く）
//
```

これを見てお分かりのとおり，一方の目ごとにシーンを２回ずつ描いています．両目のシーンを作るのに，計４回描くことになります．これはさすがに効率が悪いですね．

## ドライバの対応

効率のいいプログラムを書くには，やはりドライバレベルのサポートが必要だと感じます（Quad Buffer Stereo に対応してくれたらなぁ）．あるいは，ピクセルシェーダで実装するとか．もし，何かいい方法をご存知の方がいらっしゃったら教えてください．そういえばSHARPのノートパソコンならnVIDIAのステレオドライバが対応するとか，どこかに書いてあった気がします．それにSHARPは，StereoGLなるものも用意しているようですね．うーむ．

## 資料が欲しい

ドライバもそうですけど，やっぱり資料が欲しいですね．例えば，このLavie本体にはソフトウェアでコントロールできる「3Dボタン」なるものが付いているのですが，このコントロール方法がわかりません．また，この「3Dボタン」を押して画面を3Dモードに切り替えると画面の下部に「最適視認位置インジケータ」が表示されるのですが，この使い方も今ひとつよくわかりません．コンシューマ向けノートパソコンだから，そんなに詳しい技術資料が添付されているわけがないとは思いますが，そういうのって，どこかに頼んだらもらえるものなのでしょうか．

## MOBILITY RADEON 9600

このノートパソコンを（わがままを言って）導入した理由は，手持ちの古いノートパソコンがDirectX9を使って[研究している学生さん](http://media.sys.wakayama-u.ac.jp/tokoi-lab/studies.html)のデモでは使えないために，彼がでっかいデスクトップパソコンをえっちらおっちら運んでいたのを見かねたことにあります．ところが，そのデスクトップパソコンのビデオカードがnVIDIAのせいか，ATIのLavieでは実行結果がかなり違ってきます．本人は「機種依存しないように作った」と言うんですけど．実数計算の精度の違いかなぁ．

## ファイナルファンタジーXI

ところで，このノートパソコンには3D液晶を生かすアプリケーションとして，ファイナルファンタジーXIがバンドルされてました．このゲームで3D表示をどんなふうに生かすのか興味はあるのですが，学校でこれにはまってしまうわけにもいかないんで，まだ封を切ってません．どーすっかな．

- [ステンシルバッファを使った立体視](https://github.com/tokoik/pitcher)
