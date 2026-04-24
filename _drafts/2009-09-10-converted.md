---
title: "第９回 球を線で描く"
date: 2009-09-10
categories: [OpenGL,GLSL,ゼミ]
published: true
---

## 3D プログラミングは難しい

shi3z さんの日記「[僕が3Dプログラマをやめた理由　または3Dプログラミングを学ぶべき6つの理由](http://d.hatena.ne.jp/shi3z/20090909/1252478906)」に, うなずくところがたくさんありました. 本当に, 3D プログラミングは難しいんです. 意義のある成果を出そうとすると, とてつもなく難しいところに分け入らなければなりません. それで, いつもへこたれてしまいます. だから１年生向けの授業で, つい「3D CG ってこんなに難しいんだよ, だからいっぱい勉強しよう」みたいなことを言って, 嫌われてしまいます. でも, CG って面白いんです. 私が CG に出会った 30 年前も, 今も変わらず面白いです. みんな, 3D CG プログラミングやろうよ.

## プログラムの修正

図形を作成して頂点バッファオブジェクトに送っている部分を, 初期化の関数 `init()` に組み込んでしまったために, `init()` がかなり太ってしまいました. そこで, この部分を別の関数に分離して, ソースファイルも分けてしまいたいと思います. 行き当たりばったりでごめんなさい. 一応, このゼミ資料は全体的な見通しを立てて作っているつもりなんですけど, 走りながら作ってるんで, どうしても間違いがあったりつじつまが合わなくなってきたりして, 軌道修正しなきゃなんないことがあります. ごめんなさい.

## 図形作成部分の分離

メインプログラムの関数 `init()` の始めの方にあるデータ型 `Position` および `Edge` の定義と変数 `position` および `edge` の宣言 (下記の...の部分) を<`em`>削除します.

```c
...

/*
** 初期化
*/
static void init(void)
{
/* シェーダプログラムのコンパイル／リンク結果を得る変数 */
GLint compiled, linked;

/* 頂点バッファオブジェクトのメモリを参照するポインタ */
typedef GLfloat Position[3];
Position *position;
typedef GLuint Edge[2];
Edge *edge;

/* 一時的な変換行列 */

GLfloat temp0[16], temp1[16];

...
```

## また, その下にある頂点バッファオブジェクトにデータを転送している箇所 (下記の...の部分) も削除します. この部分は他のソースプログラムに移すので, これはエディタの「編集」メニューにある「切り取り (cut)」で削除してください. emacs なら C-k とか C-SPC と C-w とか, vi なら "ad/^} とか…

```c
...

/* 頂点バッファオブジェクトを２つ作る */

glGenBuffers(2, buffer);

/* 頂点バッファオブジェクトに８頂点分のメモリ領域を確保する */
glBindBuffer(GL_ARRAY_BUFFER, buffer[0]);
glBufferData(GL_ARRAY_BUFFER, sizeof (Position) * 8, NULL, GL_STATIC_DRAW);

/* 頂点バッファオブジェクトのメモリをプログラムのメモリ空間にマップする */
position = (Position *)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);

/* 頂点バッファオブジェクトのメモリにデータを書き込む */
position[0][0] = -1.0f;
position[0][1] = -1.0f;
position[0][2] = -1.0f;

position[1][0] =  1.0f;
position[1][1] = -1.0f;
position[1][2] = -1.0f;

position[2][0] =  1.0f;
position[2][1] = -1.0f;
position[2][2] =  1.0f;

position[3][0] = -1.0f;
position[3][1] = -1.0f;
position[3][2] =  1.0f;

position[4][0] = -1.0f;
position[4][1] =  1.0f;
position[4][2] = -1.0f;

position[5][0] =  1.0f;
position[5][1] =  1.0f;
position[5][2] = -1.0f;

position[6][0] =  1.0f;
position[6][1] =  1.0f;
position[6][2] =  1.0f;

position[7][0] = -1.0f;
position[7][1] =  1.0f;
position[7][2] =  1.0f;

/* 頂点バッファオブジェクトに１２稜線分のメモリ領域を確保する */
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer[1]);
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof (Edge) * 12, NULL, GL_STATIC_DRAW);

/* 頂点バッファオブジェクトのメモリをプログラムのメモリ空間にマップする */
edge = (Edge *)glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY);

/* 頂点バッファオブジェクトのメモリにデータを書き込む */
edge[ 0][0] = 0;
edge[ 0][1] = 1;

edge[ 1][0] = 1;
edge[ 1][1] = 2;

edge[ 2][0] = 2;
edge[ 2][1] = 3;

edge[ 3][0] = 3;
edge[ 3][1] = 0;

edge[ 4][0] = 0;
edge[ 4][1] = 4;

edge[ 5][0] = 1;
edge[ 5][1] = 5;

edge[ 6][0] = 2;
edge[ 6][1] = 6;

edge[ 7][0] = 3;
edge[ 7][1] = 7;

edge[ 8][0] = 4;
edge[ 8][1] = 5;

edge[ 9][0] = 5;
edge[ 9][1] = 6;

edge[10][0] = 6;
edge[10][1] = 7;

edge[11][0] = 7;
edge[11][1] = 4;

/* 頂点バッファオブジェクトのメモリをプログラムのメモリ空間から切り離す */
glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);

/* 頂点バッファオブジェクトを解放する */
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

/* 頂点バッファオブジェクトのメモリをプログラムのメモリ空間から切り離す */
glUnmapBuffer(GL_ARRAY_BUFFER);

/* 頂点バッファオブジェクトを解放する */
glBindBuffer(GL_ARRAY_BUFFER, 0);
}
```

## 次に, 別のソースファイルを作成し, そこに削除した部分を「貼り付け (paste)」してください. emacs なら C-y とか, vi なら "ap とか… (きりがないな) そして, その前後に以下の内容を追加し, 関数 `wireCube()` を完成させてください. この関数は, 引数に指定されたバッファオブジェクトに対して頂点情報 (座標値) と頂点の指標を設定します. 戻り値は [`glDrawElements()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glDrawElements.xhtml) の第２引数に指定する, 描画する頂点の数 (`GL_LINES` の場合は稜線の数 × 2) です.

```c
#include <math.h>
#include <stdlib.h>
#if defined(WIN32)
#  include "glew.h"
#  include "glut.h"
#  include "glext.h"
#elif defined(__APPLE__) || defined(MACOSX)
#  include <GLUT/glut.h>
#else
#  define GL_GLEXT_PROTOTYPES
#  include <GL/glut.h>
#endif

/* 頂点バッファオブジェクトのメモリを参照するポインタのデータ型 */

typedef GLfloat Position[3];
typedef GLuint Edge[2];

GLuint wireCube(const GLuint *buffer)

{
Position *position;
Edge *edge;

/* この部分に切り取ったプログラムを貼り付け */

return 24;

}
```

## メインプログラムの関数 `init()` の削除した部分では, 代わりにこの関数 `wireCube()` を呼び出しておきます. 変数 `points` に, この関数の戻り値を保存しておきます.

```c
...

/*
** 初期化
*/
static void init(void)
{
...

/* 頂点バッファオブジェクトを２つ作る */

glGenBuffers(2, buffer);

/* 図形をバッファオブジェクトに登録する */
points = wireCube(buffer);
}

...
```

## 関数 `wireCube()` や変数 `points` を, プログラムの最初の部分で宣言しておきます.

```c
...

/*
** attribute 変数 position の頂点バッファオブジェクト
*/
static GLuint buffer[2];

/*
** 図形
*/
static GLuint points;
extern GLuint wireCube(const GLuint *buffer);
```

## その後, 画面表示の [`glDrawElements()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glDrawElements.xhtml) の第２引数は 24 という定数になっているので, これを変数 `points` に変更します.

```c
/*
** 画面表示
*/
static void display(void)
{
...

/* 図形を描く */

glDrawElements(GL_LINES, points, GL_UNSIGNED_INT, 0);

...
```

## これで一度プログラムを実行し, 正しく動くことを確認してください.

## 球を線で描く

それでは, 今度は球を描いてみましょう. と言っても, OpenGL では曲線は描けませんから, 線分で近似することになります.

![線画の球]({{ site.baseurl }}/assets/images/wiresphere0.gif)

## 球は経度方向と緯度方向に分割します. 経度方向の分割数を `slices`, 緯度方向の分割数を `stacks` とします. また半径は 1 とします. この図形の頂点の数は `slices` × (`stacks` - 1) + 2 になります. 一番上 (北極点) の頂点の位置は (0, 1, 0), 一番下 (南極点) の頂点の位置は (0, -1, 0) になります. 各頂点の位置は, 以下のように定めます.

![頂点の位置]({{ site.baseurl }}/assets/images/wiresphere1.gif)

## また稜線の数は, `slices` × (`stacks` - 1) × 2 + `slices` になります. 各稜線の両端の頂点の指標 (番号) は, 以下のように定めます.

![頂点の指標]({{ site.baseurl }}/assets/images/wiresphere2.gif)

## この形状のデータを頂点バッファオブジェクトに設定する関数 `wireSphere()` を作成してください. 引数 `slices` と `stacks` は, それぞれ球の経度方向の分割数と緯度方向の分割数です. 引数 `buffer` にはデータを設定する頂点バッファオブジェクトの名前を格納した配列を指定します. `buffer`[0] には頂点位置, `buffer`[1] には指標を格納します. なお, このプログラムは `wireCube()` と同じファイルに書いてください.

```c
GLuint wireSphere(int slices, int stacks, const GLuint *buffer)
{
Position *position;
Edge *edge;

GLuint vertices = slices * (stacks - 1) + 2;

GLuint edges = slices * (stacks - 1) * 2 + slices;

/* 頂点バッファオブジェクトを有効にする */

glBindBuffer(GL_ARRAY_BUFFER, buffer[0]);
glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, buffer[1]);

/* 頂点バッファオブジェクトにメモリ領域を確保する */

glBufferData(GL_ARRAY_BUFFER, sizeof (Position) * vertices, NULL, GL_STATIC_DRAW);
glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof (Edge) * edges, NULL, GL_STATIC_DRAW);

/* 頂点バッファオブジェクトのメモリをプログラムのメモリ空間にマップする */

position = (Position *)glMapBuffer(GL_ARRAY_BUFFER, GL_WRITE_ONLY);
edge = (Edge *)glMapBuffer(GL_ELEMENT_ARRAY_BUFFER, GL_WRITE_ONLY);

/*
** 頂点バッファオブジェクトのメモリにデータを書き込むプログラムを,
** この部分に作成してください. 変数 position および edge に値を設
** 定してください.
*/

/* 頂点バッファオブジェクトのメモリをプログラムのメモリ空間から切り離す */

glUnmapBuffer(GL_ELEMENT_ARRAY_BUFFER);
glUnmapBuffer(GL_ARRAY_BUFFER);

/* 頂点バッファオブジェクトを解放する */

glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
glBindBuffer(GL_ARRAY_BUFFER, 0);

return edges * 2;

}
```

## 変数 `position` および `edge` が指している (頂点バッファオブジェクトの) メモリに値を設定するプログラムを考えてください. `wireCube()` のように, 代入文を並べるという書き方で実現するのは難しいと思います.

<ul>
<li>[【解答例】](summer/wiresphere.txt)←うーん, きれいに書けなかった</li>
</ul>

## これができたら, メインプログラムに `wireSphere()` の宣言を追加し, `wireCube()` を呼び出している部分を `wireSphere()` に置き換えてください. `slices` と `stacks` には, ともに 3 以上の整数を設定してください. ここでは 16 と 8 を設定しています.

```c
...

/*
** 図形
*/
static GLuint points;
extern GLuint wireCube(const GLuint *buffer);
extern GLuint wireSphere(int slices, int stacks, const GLuint *buffer);

...

/*
** 初期化
*/
static void init(void)
{
...

/* 頂点バッファオブジェクトを２つ作る */

glGenBuffers(2, buffer);

/* 図形をバッファオブジェクトに登録する */

points = wireSphere(16, 8, buffer);
}

...
```

## これで下のような図形が描かれれば OK です.

![球を線で描いた結果]({{ site.baseurl }}/assets/images/wiresphere_result.gif)

## こんなところです.

<ul>
<li>[Linux 版](summer/summer06.tar.gz)</li>
<li>[Mac OS X 版](summer/summer06.zip)</li>
<li>[Windows 版](summer/summer06.lzh)</li>
</ul>

## 逃げないで

3D CG プログラミングが「難しそうだから, 自分には関係ないや」って感じで逃げられてしまうと, ちょっと悲しいです. それでも, うちの研究室には「難しそうだけど, やってみる」って人が集まってくれてるので, 嬉しいです. みなさんが難しいと思うことは, 実は私にとっても難しいことなんですが, 一緒に考えますんで, 気軽に聞いてください. 私をマニュアルとして使っていただいて構いませんから.
