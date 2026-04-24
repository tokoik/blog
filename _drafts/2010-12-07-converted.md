---
title: "フレームバッファオブジェクトの使い方あげいん"
date: 2010-12-07
categories: [OpenGL]
published: true
---

## フレームバッファオブジェクト (Framebuffer Object, FBO)

フレームバッファオブジェクトの使い方については, [キューブマッピング]({% post_url 2006-07-15-post %})で使ってみたり, [シャドウマッピング]({% post_url 2006-07-18-post %})で使ってみたり, [デプスバッファを表示]({% post_url 2008-12-07-post %})させてみたりしてきていますが, どうも使い方がよくわからんとおっしゃる学生さんのために, もういっぺん書いときます. じーっくりと読んでね.

## ティーポットを描くプログラム

とりあえず, いつものようにティーポットを描くプログラムを作ります. ただし, モデルビュー変換行列や透視変換行列, ビューポートなどは, シーンの描画時にいちいち設定するようにします. このため glutReshapeFunc() のコールバック関数 `resize()` では, 開いたウィンドウのサイズの保存だけを行います.

<ul>
<li>[ティーポットを描くプログラム](texture/fbo2.zip)</li>
</ul>

```c
...

static int width, height;   // ウィンドウの幅と高さ

/*
** 初期化
*/
static void init(void)
{
// 背景色
glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

// 光源

glEnable(GL_LIGHT0);
}

/*
** 画面表示
*/
static void display(void)
{
// 透視変換行列の設定
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
gluPerspective(30.0, (GLdouble)width / (GLdouble)height, 1.0, 10.0);

// モデルビュー変換行列の設定

glMatrixMode(GL_MODELVIEW);
glLoadIdentity();
gluLookAt(3.0, 4.0, 5.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);

// 隠面消去を有効にする

glEnable(GL_DEPTH_TEST);

// 陰影付けを有効にする

glEnable(GL_LIGHTING);

// ビューポートの設定

glViewport(0, 0, width, height);

// カラーバッファとデプスバッファをクリア

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// シーンの描画

glutSolidTeapot(1.0);
glFlush();
}

/*
** ウィンドウサイズの変更
*/
static void resize(int w, int h)
{
// ウィンドウのサイズを保存する
width = w;
height = h;
}
```

## このプログラムに以降の変更を加えます.

## フレームバッファオブジェクトを作る

フレームバッファオブジェクトはカラーバッファやデプスバッファなど, いくつかのバッファの集合体 (collection) です. ここではカラーバッファとデプスバッファからなるフレームバッファオブジェクトを作成します. カラーバッファにレンダリングされた画像を後でテクスチャとして使うので, カラーバッファにはテクスチャを割り当てます. デプスバッファは隠面消去処理だけのために使う (内容をテクスチャとして参照しない) ので, レンダーバッファを割り当てます.
最初に, フレームバッファオブジェクトやテクスチャ, それにレンダーバッファの名前 (番号) を保存する変数を用意します. また, 作成するフレームバッファオブジェクトのサイズ (= テクスチャのサイズ) を定義しておきます.

```c
...

static int width, height;   // スクリーンの幅と高さ

#define FBOWIDTH  512       // フレームバッファオブジェクトの幅
#define FBOHEIGHT 512       // フレームバッファオブジェクトの高さ

static GLuint fb;           // フレームバッファオブジェクト
static GLuint cb;           // カラーバッファ用のテクスチャ
static GLuint rb;           // デプスバッファ用のレンダーバッファ
```

## 想定している OpenGL のバージョンは 2.1 です. フレームバッファオブジェクトは拡張機能なので, Windows の場合は [`GLEW`](http://glew.sourceforge.net/) を使って拡張機能を使えるようにしておきます.

```c
/*
** 初期化
*/
static void init(void)
{
#if defined(WIN32)
// GLEW の初期化
GLenum err = glewInit();
if (err != GLEW_OK) {
fprintf(stderr, "Error: %s\n", glewGetErrorString(err));
exit(1);
}
#endif
```

## まず, カラーバッファに使うテクスチャを作成します. テクスチャのサイズはフレームバッファオブジェクトのサイズにします. これは通常のテクスチャの作成と同じですが, 確保したテクスチャメモリに画像データを転送する必要はない (レンダリングによって描き込まれるから) ので, 画像データを渡すのに使う [`glTexImage2D()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexImage2D.xhtml) の最後の引数は 0 (NULL) にしておきます. なお, [`glTexParameteri()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glTexParameteri.xhtml) を一つも指定しないと, テクスチャが正常に使用できない場合があります.

```c
// カラーバッファ用のテクスチャを用意する
glGenTextures(1, &cb);
glBindTexture(GL_TEXTURE_2D, cb);
glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, FBOWIDTH, FBOHEIGHT, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
glBindTexture(GL_TEXTURE_2D, 0);
```

## 次に, デプスバッファに使うレンダーバッファを作成します. このサイズもフレームバッファオブジェクトと同じにしておきます. もし[デプスバッファを表示]({% post_url 2008-12-07-post %})する場合のように, デプスバッファの内容をテクスチャとして参照する必要があるなら, レンダーバッファではなくテクスチャを作成します.

```c
// デプスバッファ用のレンダーバッファを用意する
glGenRenderbuffersEXT(1, &rb);
glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, rb);
glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT, FBOWIDTH, FBOHEIGHT);
glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, 0);
```

## 最後にフレームバッファおオブジェクトを作成し, それにテクスチャとレンダーバッファを結合します.

```c
// フレームバッファオブジェクトを作成する
glGenFramebuffersEXT(1, &fb);
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb);

// フレームバッファオブジェクトにカラーバッファとしてテクスチャを結合する
glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, cb, 0);

// フレームバッファオブジェクトにデプスバッファとしてレンダーバッファを結合する
glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, rb);

// フレームバッファオブジェクトの結合を解除する
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);

// 背景色

glClearColor(0.0f, 0.0f, 0.0f, 1.0f);

// 光源

glEnable(GL_LIGHT0);
}
```

## これでフレームバッファオブジェクトの準備は終わりです.

## フレームバッファオブジェクトにレンダリングする

描画処理の直前にフレームバッファオブジェクトを有効にすれば, 図形はフレームバッファオブジェクトにレンダリングされ, ディスプレイには表示されなくなります (オフスクリーンレンダリング). ビューポートのサイズはフレームバッファオブジェクトに合わせておきます.

```c
/*
** 画面表示
*/
static void display(void)
{
// 透視変換行列の設定
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
gluPerspective(30.0, (GLdouble)width / (GLdouble)height, 1.0, 10.0);

// モデルビュー変換行列の設定

glMatrixMode(GL_MODELVIEW);
glLoadIdentity();
gluLookAt(3.0, 4.0, 5.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);

// ビューポートの設定

glViewport(0, 0, FBOWIDTH, FBOHEIGHT);

// 隠面消去を有効にする

glEnable(GL_DEPTH_TEST);

// 陰影付けを有効にする

glEnable(GL_LIGHTING);

// フレームバッファオブジェクトを結合する
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fb);

// カラーバッファとデプスバッファをクリア

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// シーンの描画

glutSolidTeapot(1.0);
glFlush();

// フレームバッファオブジェクトの結合を解除する
glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
```

## ここで一旦プログラムをコンパイルし, 実行してみてください. 何も表示されないと思います.

## テクスチャにレンダリングされた画像をマッピングする

このままでは何も表示されないので, クリッピング空間いっぱいに一枚のポリゴンを描き, それにテクスチャをマッピングします.
クリッピング空間は<%= a "コンピュータグラフィックスの授業" %>や去年の夏休みゼミ資料の[第５回 座標変換]({% post_url 2009-08-29-post %})で説明したように, 中心が原点にある一辺の長さが 2 の立方体の空間です. この空間内に描かれているものが画面に表示されます. 物体形状は, モデルビュー変換や透視変換を経て, この空間に投影されます. したがってモデルビュー変換行列と透視変換行列が単位行列なら, 物体の座標はクリッピング空間中の座標になります.
そこで, モデルビュー変換行列と透視変換行列を単位行列にします.

```c
// 透視変換行列を単位行列にする
glMatrixMode(GL_PROJECTION);
glLoadIdentity();

// モデルビュー変換行列を単位行列にする
glMatrixMode(GL_MODELVIEW);
glLoadIdentity();
```

## ビューポートはウィンドウのサイズに合わせます.

```c
// ビューポートはウィンドウのサイズに合わせる
glViewport(0, 0, width, height);
```

## 陰影付けや隠面消去処理は行わないようにします. また, 画面いっぱいにポリゴンを描くので, 画面消去は不要になります. デプスバッファも使わないので, 消去する必要はありません.

```c
// 陰影付けと隠面消去処理は行わない
glDisable(GL_LIGHTING);
glDisable(GL_DEPTH_TEST);
```

## レンダリングされた画像が入っているテクスチャを結合して, テクスチャマッピングを有効にします.

```c
// テクスチャマッピングを有効にする
glBindTexture(GL_TEXTURE_2D, cb);
glEnable(GL_TEXTURE_2D);
```

## xy 平面上に (-1, -1) と (1, 1) を対角線上の頂点とする正方形を白色で描きます. このとき, (-1, -1) の頂点のテクスチャ座標を (0, 0), (1, 1) の頂点のテクスチャ座標を (1, 1) とします.

```c
// 正方形を描く
glColor3d(1.0, 1.0, 1.0);
glBegin(GL_TRIANGLE_FAN);
glTexCoord2d(0.0, 0.0);
glVertex2d(-1.0, -1.0);
glTexCoord2d(1.0, 0.0);
glVertex2d( 1.0, -1.0);
glTexCoord2d(1.0, 1.0);
glVertex2d( 1.0,  1.0);
glTexCoord2d(0.0, 1.0);
glVertex2d(-1.0,  1.0);
glEnd();
```

## テクスチャマッピングを無効にします.

```c
// テクスチャマッピングを無効にする
glDisable(GL_TEXTURE_2D);
glBindTexture(GL_TEXTURE_2D, 0);
```

## 最後に [`glFlush()`](https://registry.khronos.org/OpenGL-Refpages/gl4/html/glFlush.xhtml) (アニメーションするなら glutSwapBuffers()) を実行します.

```c
glFlush();
}
```

## このポリゴンの描画の際にシェーダプログラムを指定すれば, フラグメントシェーダでレンダリング結果を加工することができます. バーテックスシェーダもうまく使えば, ポリゴンの描画処理を簡略化できます. このテクニックは[デプスバッファの輪郭線抽出]({% post_url 2008-12-08-post %})や [SSAO]({% post_url 2010-11-22-post %}), [似非 SSS]({% post_url 2010-12-03-post %}) などで使っています. いわゆる遅延レンダリング (deferred rendering) です.
