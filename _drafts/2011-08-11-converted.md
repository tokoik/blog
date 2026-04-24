---
title: "OpenCV によるカメラ入力と OpenGL のスワップバッファ"
date: 2011-08-11
categories: [OpenGL,メモ]
published: true
---

## 暑い

なんてもんやないですね．日差しに重みすら感じます．眩しいです．非リアにはつらいものがあります．加齢とともに直射日光に当たると日焼けする前に湿疹ができてしまうようになりました．もう闇の中で生きるしかないのかもしれません．子供と一緒に自転車で片男波海水浴場まで通っていた頃が懐かしいです．ところで，数日前まで節電対応で空調なしで頑張ってたんですけど，PC がついに音を上げてクラッシュするようになってしまったので（と言い訳しながら）空調かけてます．みなさまごめんなさい．来週はお盆の一斉休業です．その間に少しでも時間を稼いでおかないと，色々詰みそうです．まー，私なんぞ他の先生に比べりゃあ暇なもんなんですけど orz バンクーバーに行きたかったぜい．

## `pthread`

一人の学生さんが `OpenCV` と OpenGL を組み合わせて何かしようと考えているらしいのですが，どうも動きがぎこちなく見えます．その学生さんは MacBook Pro を使っているのですが，1 フレームキャプチャするごとにデフォルトでは 60-70ms ブロックしてしまいます．15fps ですね．それと OpenGL のダブルバッファリングのスワップバッファのタイミングが合わないために，表示のフレームレートが一定せず，ぎこちなく見えるのではないかと思います．`CV_CAP_PROP_FPS` に 30.0 を設定しても，やっぱり微妙にガタガタします．
ということで，とりあえず自分でもテストプログラムを書いてみました．

![`OpenCV` でキャプチャした画像をテクスチャに使う]({{ site.baseurl }}/assets/images/cvtest.jpg)

## これはキャプチャした画像を回転する球にマッピングします．さらにシェーダで濃淡値から法線マップを求めて，バンプマッピングもしています．自宅の猫のたまちゃんをキャプチャしてみましたけど，怖いぜ…

```c
...

/*
* テクスチャ作成
*/
static void getTexture(void)
{
if (cvGrabFrame(capture)) {

// キャプチャ映像から画像の切り出し

IplImage *image = cvRetrieveFrame(capture);

if (image) {

// 切り出した画像をテクスチャメモリに転送
GLenum format;
if (image->nChannels == 3)
format = GL_BGR;
else if (image->nChannels == 4)
format = GL_BGRA;
else
format = GL_LUMINANCE;
glBindTexture(GL_TEXTURE_2D, texname);
for (int y = 0; y < image->height; ++y) {
glTexSubImage2D(GL_TEXTURE_2D, 0, 0, y, image->width, 1, format,
GL_UNSIGNED_BYTE, image->imageData + image->widthStep * y);
}
}
}
}

...

/*
* 画面表示
*/
static void display(void)
{
// 時刻の計測
static int firstTime = 0;
GLdouble t;
if (firstTime == 0) { firstTime = glutGet(GLUT_ELAPSED_TIME); t = 0.0; }
else t = (GLdouble)((glutGet(GLUT_ELAPSED_TIME) - firstTime) % CYCLE) / (GLdouble)CYCLE;

// テクスチャ作成

getTexture();

// 画面クリア

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// モデルビュー変換行列の設定

glLoadIdentity();
gluLookAt(0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);

// 図形描画

glBindTexture(GL_TEXTURE_2D, texname);
glBindVertexArray(vaname);
glUseProgram(progname);
glUniform1i(dmapLoc, 0);
glUniform2f(sizeLoc, TEXWIDTH, TEXHEIGHT);
glPushMatrix();
glRotated(t * 360.0, 0.0, 1.0, 0.0);
glDrawElements(GL_TRIANGLES, faces * 3, GL_UNSIGNED_INT, face);
glPopMatrix();

// ダブルバッファリング

glutSwapBuffers();
}
```

<ul>
<li>[元のプログラム](https://github.com/tokoik/cvtest/tree/sync)</li>
</ul>

## この辺みんなどうやってんのかなーと調べてみてもよくわからず（どうすべきなのかご存知でしたら教えてください），仕方なくキャプチャを別スレッドで回して，キャプチャと表示を非同期に行うということを試してみました．

まず，カメラからのキャプチャを無限ループにします．`cvGrabFrame()` がすぐに帰ってくるとループがぶんぶん回ってしまってまずい気がしますが，必ず１フレーム分の時間がかかっているみたいなので，何も考えずに回します．また，キャプチャした画像は配列 `texture` に保存しておきます．このタイミングがクリティカルセクションになるので，`mutex` でロックしておきます．

```c
...

// テクスチャ
static GLenum format;
static GLsizei width, height;
static GLubyte texture[TEXHEIGHT * TEXWIDTH * 4];

// スレッド
#include <pthread.h>
static pthread_t thread;
static pthread_mutex_t mutex;

/*
* テクスチャ作成
*/
static void *getTexture(void *arg)
{
CvCapture *capture = reinterpret_cast<CvCapture *>(arg);

for (;;) {
if (cvGrabFrame(capture)) {

// キャプチャ映像から画像を切り出す

IplImage *image = cvRetrieveFrame(capture);

if (image) {

// 切り出した画像の書式を保存する
width = image->width;
height = image->height;
if (image->nChannels == 3)
format = GL_BGR;
else if (image->nChannels == 4)
format = GL_BGRA;
else
format = GL_LUMINANCE;

// 切り出した画像を保存する

GLsizei size = image->width * image->nChannels;
pthread_mutex_lock(&mutex);
for (int y = 0; y < image->height; ++y)
memcpy(texture + size * y, image->imageData + image->widthStep * y, size);
pthread_mutex_unlock(&mutex);
}
}

pthread_testcancel();
}

return 0;
}
```

## これを別スレッドで走らせます．`mutex` も作っておきます．また，プログラム終了時の処理も用意しておきます．

```c
...

/*
* プログラム終了時の処理
*/
static void releaseCapture(void)
{
// スレッドを停止する
pthread_cancel(thread);

// スレッドの停止を待つ
pthread_join(thread, 0);

// ミューテックスを破棄する
pthread_mutex_destroy(&mutex);

// image の release

cvReleaseCapture(&capture);
}

/*
* OpenCV の初期化
*/
static void cvInit(void)
{
// カメラを初期化する
capture = cvCreateCameraCapture(CV_CAP_ANY);
if (capture == 0) {
std::cerr << "cannot capture image" << std::endl;
exit(1);
}
cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_WIDTH, WIDTH);
cvSetCaptureProperty(capture, CV_CAP_PROP_FRAME_HEIGHT, HEIGHT);
cvSetCaptureProperty(capture, CV_CAP_PROP_FPS, 30.0);

// スレッドを生成する
pthread_mutex_init(&mutex, 0);
pthread_create(&thread, 0, getTexture, capture);

// プログラム終了時に capture を release する

atexit(releaseCapture);
}
```

## 描画の際には，配列 `texture` のロックを獲得してから，`texture` の内容をテクスチャメモリにコピーします．

```c
...

/*
* 画面表示
*/
static void display(void)
{
// 時刻の計測
static int firstTime = 0;
GLdouble t;
if (firstTime == 0) { firstTime = glutGet(GLUT_ELAPSED_TIME); t = 0.0; }
else t = (GLdouble)((glutGet(GLUT_ELAPSED_TIME) - firstTime) % CYCLE) / (GLdouble)CYCLE;

// テクスチャ取得

pthread_mutex_lock(&mutex);
glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, format, GL_UNSIGNED_BYTE, texture);
pthread_mutex_unlock(&mutex);

// 画面クリア

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// モデルビュー変換行列の設定

glLoadIdentity();
gluLookAt(0.0, 0.0, 3.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);

// 図形描画

glBindTexture(GL_TEXTURE_2D, texname);
glBindVertexArray(vaname);
glUseProgram(progname);
glUniform1i(dmapLoc, 0);
glUniform2f(sizeLoc, TEXWIDTH, TEXHEIGHT);
glPushMatrix();
glRotated(t * 360.0, 0.0, 1.0, 0.0);
glDrawElements(GL_TRIANGLES, faces * 3, GL_UNSIGNED_INT, face);
glPopMatrix();

// ダブルバッファリング

glutSwapBuffers();
}
```

<ul>
<li>[非同期化したプログラム (2013/8/28 追記: Windows 対応したので上記とは異なっています)](https://github.com/tokoik/cvtest/tree/async)</li>
</ul>

## 「[static おじさん](http://d.hatena.ne.jp/ryoasai/20110702/1309600182)」ですみません．ただ，これだと `texture` に書き込んでいる最中（ロックされているとき）に `texture` を読み出そうとするとブロックしてしまうので，その場合は `texture` を読まずに以前に読み込んだテクスチャを使うようにしたいと思いました．

```c
// テクスチャ取得
if (pthread_mutex_trylock(&mutex) == 0) {
glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, format, GL_UNSIGNED_BYTE, texture);
pthread_mutex_unlock(&mutex);
}
```

## ですが `pthread_mutex_trylock()` がずーっと EBUSY を返してたまにしか 0 を返さないので，テクスチャが全然更新されません．カメラ側のスレッドでもロックされているみたいで，フレームを取りこぼすこともあります．そもそも `OpenCV` がスレッドセーフかどうかも知らないし（今回はカメラ１台だから大丈夫だと思ったんだけど）．謎が多い．教えて偉い人．

## ラベル付け

「static おじさん」世代の私たちですら，団塊の世代からは「新人類」って呼ばれてたんよ．みんなラベル付け好きよね．CV の話でなくてすまん．
