---
title: "MFC によるダイアログベースのアプリケーション（２）"
date: 2010-08-25
categories: [OpenGL]
published: true
---

## 昼食

昨日, 久しぶりに昼に食堂に行ったら (いつもは弁当なので), ある先生が研究室の学生さんと楽しそうにしゃべってました. うーん, 私も昼食に学生さんを誘わんといかんな. 私の師匠もそうしてたし (って, この話, 以前にも書いたな). でも, ま, いいや. 今度の飲み会でおしゃべりしよう. 私の演説は極力控えるようにして.

## 今回はこういうものを作ります.

![実行結果]({{ site.baseurl }}/assets/images/mfc68.gif)

## 以下は[【 G.Ishihara流 】Visual C++ (MFC)超入門](http://www.g-ishihara.com/) 様に非常にお世話になりました. ありがとうございました.

## 図形を描画するクラスを作る

Picture Control に結びつけた `OpenGL` の描画領域に描くシーンのクラスを作成します. 「クラスの追加」を選びます. 別にクラスにする必要はなんにもない気がするんですけど.

![クラスの追加]({{ site.baseurl }}/assets/images/mfc33.gif)

## 「カテゴリ」から「C++」を選び, 「C++クラス」のテンプレート鵜を選んで「追加」をクリックします. `OpenGL` のクラスなので, MFC なんかの流儀は気にしないことにします.

![C++クラスのテンプレート]({{ site.baseurl }}/assets/images/mfc34.gif)

## クラス名は「`Scene`」とします. 「仮想デストラクタ」にするのはデフォだという話ですが, これについてはいろいろ議論もあるようです. でも, ここでは日和ります.

 
![クラス名の設定]({{ site.baseurl }}/assets/images/mfc35.gif)

## `Scene` クラスの宣言を行います. `Scene`.h を開きます.

![`Scene` クラスの宣言]({{ site.baseurl }}/assets/images/mfc36.gif)

## ユーザインタフェース機能はクラス変数として `GLfloat` 型の `rotateZ` を１個だけ宣言します. クラス変数って, メンバ関数にとってのグローバル変数なんだなって MFC を使ってると意識させられます. コンストラクタとデストラクタは, ここではあまり仕事がないので, インラインで定義してしまいます. あと, コンストラクタで `rotateZ` を初期化するようにします. メンバ関数には `rotateZ` に値を設定する `setRotateZ`() とシーンを描画する `draw`() を用意することにします.

個人的には #`pragma` `once` じゃなくて #ifndef 〜 #define 〜 #endif を使いたいところですが, ここでは Visual Studio の流儀に従います.

```c
#pragma once

class Scene

{
GLfloat rotateZ;
public:
Scene(void) : rotateZ(0.0f) {}
virtual ~Scene(void) {}
void setRotateZ(float angle) { rotateZ = angle; }
void draw(void);
};
```

## `Scene`.cpp を開いて `Scene` クラスの実装を行います. コンストラクタとデストラクタは自動生成されていますが, `Scene`.h でインラインにしちゃったので消してしまいます. ここでは `draw`() の実装だけを行います．

![`Scene` クラスの実装]({{ site.baseurl }}/assets/images/mfc37.gif)

## 描画する図形はなんでもいいんですけど, GLUT も AUX も使ってないので (GLU は使えますけど) 自分で定義することにします. もうちょっとこだわってシーングラフっぽくしたくなるのですが, そんなことをしていたら終わらないので我慢します.

```c
#include "StdAfx.h"
#include "Scene.h"

static void pinwheel(void)
{
static const GLfloat v[] = {
0.0f,  0.0f,  1.0f,  0.0f,  0.5f,  0.5f,
0.0f,  0.0f,  0.0f,  1.0f, -0.5f,  0.5f,
0.0f,  0.0f, -1.0f,  0.0f, -0.5f, -0.5f,
0.0f,  0.0f,  0.0f, -1.0f,  0.5f, -0.5f,
};

glEnableClientState(GL_VERTEX_ARRAY);

glVertexPointer(2, GL_FLOAT, 0, v);
glDrawArrays(GL_TRIANGLES, 0, sizeof v / sizeof v[0] / 2);
glDisableClientState(GL_VERTEX_ARRAY);
}

void Scene::draw(void)

{
glPushMatrix();
glRotatef(rotateZ, 0.0f, 0.0f, 1.0f);
glColor3f(1.0f, 1.0f, 0.0f);
pinwheel();
glPopMatrix();
}
```

## 図形の描画を組み込む

`Scene` クラスをダイアログウィンドウで使うので, クラスビューで Cプロジェクト名Dlg クラス (ここでは `CGLsampleDlg`) をダブルクリックして定義を開きます.

![ダイアログクラスの修正]({{ site.baseurl }}/assets/images/mfc38.gif)

## `Scene`.h を #`include` します.

```c
// GLsampleDlg.h : ヘッダー ファイル
//

#pragma once

#include "afxwin.h"
#include "Scene.h"

// CGLsampleDlg ダイアログ

class CGLsampleDlg : public CDialog
{
...
};
```

## クラスビューで Cプロジェクト名Dlg クラス (ここでは `CGLsampleDlg`) を右クリックして「追加」から「変数の追加」を選びます.

![クラス変数の追加]({{ site.baseurl }}/assets/images/mfc39.gif)

## 「アクセス」は "private", 変数の種類は "`Scene` *"として, "`m_pScene`" という変数を追加します. "m_" はメンバ変数, "p" はポインタを表すそうです. このように変数名で変数の「立場」を表しておくことを「ハンガリアン記法」というそうです. これもいろいろ議論があるみたいですが, MFC の流儀に従うことにします. 最後に「完了」をクリックします.

![追加する変数]({{ site.baseurl }}/assets/images/mfc40.gif)

## クラスビューで `OnInitDialog`(void) をダブルクリックして, その定義を変更します.

![インスタンスの生成]({{ site.baseurl }}/assets/images/mfc41.gif)

## `OpenGL` の初期化が終わった後で `Scene` クラスのインスタンスを生成して, `m_pScene` に代入します. `Scene` のコンストラクタは `OpenGL` 的な処理を何もしていないので, 実はこのインスタンスはどこで生成しても構わないのですが, 気分的な問題と将来の拡張 (あるのか) に備えて, ここで生成することにします.

```c
BOOL CGLsampleDlg::OnInitDialog()
{
CDialog::OnInitDialog();

...

// TODO: 初期化をここに追加します。

m_pDC = new CClientDC(&m_glView);

if (SetupPixelFormat(m_pDC->m_hDC) != FALSE) {

m_GLRC = wglCreateContext (m_pDC->m_hDC);
wglMakeCurrent (m_pDC->m_hDC, m_GLRC);

CRect rc;

m_glView.GetClientRect(&rc);
GLint width = rc.Width();
GLint height = rc.Height();
GLdouble aspect = (GLdouble)width / (GLdouble)height;

// OpenGL の初期設定

glClearColor(0.0f, 0.0f, 0.5f, 1.0f);
glViewport(0, 0, width, height);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glOrtho(-aspect, aspect, -1.0, 1.0, -10.0, 10.0);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity();

// シーンの生成
m_pScene = new Scene;
}

return TRUE;  // フォーカスをコントロールに設定した場合を除き、TRUE を返します。

}
```

## クラスビューで `OnPaint`(void) をダブルクリックして, その定義を変更します.

<blockquote>2014 年 6 月 3 日修正：`OnInitDialog`() で `m_pDC`->`m_hDC` = `m_glView`.GetDC()->GetSafeHdc(); という代入は不要だというご指摘を頂きました．ありがとうございます．</blockquote>

![シーンの描画]({{ site.baseurl }}/assets/images/mfc42.gif)

## 画面クリアの後でシーンを描画する `draw`() メソッドを呼び出します.

```c
void CGLsampleDlg::OnPaint()
{
if (IsIconic())
{
...
}
else
{
CDialog::OnPaint();

// OpenGL による描画

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// ここでシーンを描く

m_pScene->draw();

SwapBuffers(m_pDC->m_hDC);

}
}
```

## クラスビューで `OnDestroy`(void) をダブルクリックして, その定義を変更します.

![インスタンスの削除]({{ site.baseurl }}/assets/images/mfc43.gif)

## `OnDestroy`() はウィンドウを閉じるときに呼び出されるので, `OnInitDialog`() で生成したインスタンスをここで削除します.

```c
void CGLsampleDlg::OnDestroy()
{
CDialog::OnDestroy();

// TODO: ここにメッセージ ハンドラ コードを追加します。

delete m_pScene;
wglMakeCurrent(NULL, NULL);
wglDeleteContext(m_GLRC);
delete m_pDC;
}
```

## ここでプロジェクトを一旦ビルドして, プログラムが正常に動作するか確認します.

![プログラムのビルド]({{ site.baseurl }}/assets/images/mfc44.gif)

## Picture Contol 上の `OpenGL` の描画領域に図形が表示されると思います.

![プログラムの実行]({{ site.baseurl }}/assets/images/mfc45.gif)

## 「Slider Control」を追加する

ダイアログエディタに切り替えます.

![ダイアログエディタに切り替え]({{ site.baseurl }}/assets/images/mfc46.gif)

## 「ツールボックス」のウィンドウから「Slider Control」を選びます．

![Slider Control の選択]({{ site.baseurl }}/assets/images/mfc47.gif)

## マウスを使って「Slider Control」を配置します. ちなみに, 縦方向の「Slider Control」を配置するには, 「プロパティ」の "Orientation" に「垂直方向」を設定します.

![Slider Control の配置]({{ site.baseurl }}/assets/images/mfc48.gif)

## 配置した「Slider Control」を右クリックして，「変数の追加」を選びます.

![Slider Control に変数を追加]({{ site.baseurl }}/assets/images/mfc49.gif)

## 「アクセス」は "private", 「変数の種類」は最初から設定されている "CSliderCtrl" として, `m_xcRotateZ` という変数を追加します. コントロールと変数とのデータのやり取りに DDX というメカニズムを使うので, 変数名に "x" を付けています. また "c" はこの変数のカテゴリが「Control」であることを示すんじゃないかと思います. 最後に「完了」をクリックします.

![変数 `m_xcRotateZ` の設定]({{ site.baseurl }}/assets/images/mfc50.gif)

## 再び「Slider Control」を右クリックして，「変数の追加」を選びます.

![変数の追加]({{ site.baseurl }}/assets/images/mfc51.gif)

## 最初に「カテゴリ」から "Value" を選択します. そのあと「アクセス」に "private", 変数の種類に "int" を選びます. この変数を使って「Slider Control」と値をやり取りします. 変数名は "`m_xvRotateZ`" とします. "v" は変数のカテゴリが "Value" ということを表すんじゃないかと思います. なお, この変数には -180 度〜 180 度の「角度」を入れるつもりなので, 最大値と最小値をそれに設定します. が, 意味あるのかな？

![変数 `m_xvRotateZ` の追加]({{ site.baseurl }}/assets/images/mfc52.gif)

## 「Slider Control」を使って図形を回転する

水平の「Slider Control」のツマミを動かすと WM_HSCROLL イベントが発生するので (垂直の「Slider Control」では WM_VSCROLL イベントが発生します), それを処理するハンドラを用意します. クラスビューで Cプロジェクト名Dlg クラス (ここでは `CGLsampleDlg`) を選択して, プロパティで WM_HSCROLL に `OnHScroll` を追加します.

![WM_HSCROLL イベントに対するハンドラの追加]({{ site.baseurl }}/assets/images/mfc53.gif)

## `OnHScroll`() を実装します.

![関数 `OnHScroll`() の実装]({{ site.baseurl }}/assets/images/mfc54.gif)

## ウィンドウ上に (水平方向の)「Slider Control」や「Scroll Bar」が複数存在するとき, そのどれを動かしてもこの `OnHScroll`() が呼ばれます (Vista 以降であればコントロールごとにハンドラを指定できるみたいですけど). したがって, `OnHScroll`() ではどのコントロールが操作されたのかを判断する必要があります. `pScrollBar` にコントロール変数のポインタが入っているので, これを使ってコントロールを識別します.

「Slider Control」のツマミを動かしているときは `nSBCode` に `SB_THUMBPOSITION` か `SB_THUMBTRACK` が入っているので, この時は現在の位置 `nPos` を `m_xvRotateZ` に代入します. `nSBCode` が `SB_PAGELEFT` あるいは `SB_PAGERIGHT` は「Slider Control」上のツマミ以外の部分をクリックしたときなので, 「１ページ分のジャンプ量 (「Slider Control」の実態はスクロールバーなので)」を求めて `m_xvRotateZ` に加算 / 減算します. 
最後に `UpdateData`(`FALSE`) によりコントロールの設定値をコントロール自体に反映し, `Invalidate`(`FALSE`) で画面の再表示を行います. `OpenGL` の表示領域は `OpenGL` 自体で画面クリアを行いますので, `Invalidate`() の引数を `FALSE` にして, ここでは画面クリアを行わないようにします (ちらつくので).

```c
void CGLsampleDlg::OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar)
{
// TODO: ここにメッセージ ハンドラ コードを追加するか、既定の処理を呼び出します。
if (*pScrollBar == m_xcRotateZ) {
int pageSize, min, max;

switch (nSBCode) {

case SB_THUMBPOSITION:
case SB_THUMBTRACK:
m_xvRotateZ = nPos;
break;
case SB_PAGELEFT:
pageSize = m_xcRotateZ.GetPageSize();
m_xcRotateZ.GetRange(min, max);
if ((m_xvRotateZ -= pageSize) < min) m_xvRotateZ = min;
break;
case SB_PAGERIGHT:
pageSize = m_xcRotateZ.GetPageSize();
m_xcRotateZ.GetRange(min, max);
if ((m_xvRotateZ += pageSize) > max) m_xvRotateZ = max;
break;
default:
break;
}

UpdateData(FALSE);

Invalidate(FALSE);
}

CDialog::OnHScroll(nSBCode, nPos, pScrollBar);

}
```

## `OnInitDialog`(void) をダブルクリックして, その定義を変更します. ここでは `m_xcRotateZ` と `m_xvRotateZ` の初期設定を行います.

![関数 `OnInitDialog`() の変更]({{ site.baseurl }}/assets/images/mfc55.gif)

## `SetRange`() メソッドはツマミの上限値と下限値を設定します. `OnHScroll`() の引数 `nPos` で得られる値はこの範囲を変化します.

```c
BOOL CGLsampleDlg::OnInitDialog()
{
CDialog::OnInitDialog();

...

// TODO: 初期化をここに追加します。

m_xcRotateZ.SetRange(-180, 180, TRUE);
m_xvRotateZ = 0;
UpdateData(FALSE);

m_pDC = new CClientDC(&m_glView);

if (SetupPixelFormat(m_pDC->m_hDC) != FALSE) {

m_GLRC = wglCreateContext (m_pDC->m_hDC);
wglMakeCurrent (m_pDC->m_hDC, m_GLRC);

CRect rc;

m_glView.GetClientRect(&rc);
GLint width = rc.Width();
GLint height = rc.Height();
GLdouble aspect = (GLdouble)width / (GLdouble)height;

// OpenGL の初期設定

glClearColor(0.0f, 0.0f, 0.5f, 1.0f);
glViewport(0, 0, width, height);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glOrtho(-aspect, aspect, -1.0, 1.0, -10.0, 10.0);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity();

// シーンの生成

m_pScene = new Scene;
}

return TRUE;  // フォーカスをコントロールに設定した場合を除き、TRUE を返します。

}
```

## `OnPaint`(void) をダブルクリックして, その定義を変更します.

![関数 `OnPaint`() の変更]({{ site.baseurl }}/assets/images/mfc56.gif)

## ここでは `m_xvRotateZ` の値を `setRotateZ`() メソッドの引数に与えて. シーンの回転角を設定します.

```c
void CGLsampleDlg::OnPaint()
{
if (IsIconic())
{
...
}
else
{
CDialog::OnPaint();

// OpenGL による描画

glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

// ここでシーンを描く

m_pScene->setRotateZ((float)m_xvRotateZ);
m_pScene->draw();

SwapBuffers(m_pDC->m_hDC);

}
}
```

## ここまでできたら一旦ビルドして, プログラムを実行します. 「Slider Control」のツマミを動かすと, 図形が回転するでしょうか.

![プログラムを実行してスライダを動かす]({{ site.baseurl }}/assets/images/mfc57.gif)

## 「Edit Control」を追加する

またダイアログエディタに切り替えます.

![ダイアログエディタに切り替え]({{ site.baseurl }}/assets/images/mfc58.gif)

## ツールボックスから, 今度は「Edit Control」を選択します. 「Edit Control」は文字の表示や入力を行います.

![Edit Control の選択]({{ site.baseurl }}/assets/images/mfc59.gif)

## マウスを使って「Edit Control」を配置します. 

![Edit Control の配置]({{ site.baseurl }}/assets/images/mfc60.gif)

## 配置した「Edit Control」を右クリックして，「変数の追加」を選びます.

![Edit Control に変数を追加]({{ site.baseurl }}/assets/images/mfc61.gif)

## 最初に「カテゴリ」から "Value" を選択します. そのあと「アクセス」に "private", 「変数の種類」に "CString" を設定して, `m_xvEditZ` という変数を追加します. この変数を使って「Edit Control」に文字列を表示したり文字列を取得したりします. 最後に「完了」をクリックします.

![変数 `m_xvEditZ` の設定]({{ site.baseurl }}/assets/images/mfc62.gif)

## `OnInitDialog`(void) をダブルクリックして, その定義を変更します. ここでは `m_xvEditZ` の初期設定を行います.

![変数 `m_xvEditZ` の初期化]({{ site.baseurl }}/assets/images/mfc63.gif)

## `m_xvEditZ` は CString 型すなわち文字列なので, 角度を保持している `m_xvRotateZ` を文字列に変換してこれに格納します. `Format`() メソッドの第１引数は printf() と同様の書式文字列です. このプロジェクトは文字集合として (デフォルトの)  Unicode を使用する設定になっているので, `_T`() を使って変換しています.

```c
BOOL CGLsampleDlg::OnInitDialog()
{
CDialog::OnInitDialog();

...

// TODO: 初期化をここに追加します。

m_xcRotateZ.SetRange(-180, 180, TRUE);
m_xvRotateZ = 0;
m_xvEditZ.Format(_T("%6.1f"), (double)m_xvRotateZ);
UpdateData(FALSE);

m_pDC = new CClientDC(&m_glView);

if (SetupPixelFormat(m_pDC->m_hDC) != FALSE) {

m_GLRC = wglCreateContext (m_pDC->m_hDC);
wglMakeCurrent (m_pDC->m_hDC, m_GLRC);

CRect rc;

m_glView.GetClientRect(&rc);
GLint width = rc.Width();
GLint height = rc.Height();
GLdouble aspect = (GLdouble)width / (GLdouble)height;

// OpenGL の初期設定

glClearColor(0.0f, 0.0f, 0.5f, 1.0f);
glViewport(0, 0, width, height);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glOrtho(-aspect, aspect, -1.0, 1.0, -10.0, 10.0);
glMatrixMode(GL_MODELVIEW);
glLoadIdentity();

// シーンの生成

m_pScene = new Scene;
}

return TRUE;  // フォーカスをコントロールに設定した場合を除き、TRUE を返します。

}
```

## 「Slider Control」の設定値を「Edit Control」に表示する

`OnHScroll`(`UINT` `nSBCode`, `UINT` `nPos`, `CScrollBar`* `pScrollBar`) をダブルクリックして, その定義を変更します.

![関数 `OnHScroll`() の変更]({{ site.baseurl }}/assets/images/mfc64.gif)

## 「Slider Control」のツマミを動かした位置 `m_xvRotateZ` を文字列に直して `m_xvEditZ` に設定します. これでツマミを動かしたときに, その値が「Edit Control」に表示されます.

```c
void CGLsampleDlg::OnHScroll(UINT nSBCode, UINT nPos, CScrollBar* pScrollBar)
{
// TODO: ここにメッセージ ハンドラ コードを追加するか、既定の処理を呼び出します。
if (*pScrollBar == m_xcRotateZ) {
int pageSize, min, max;

switch (nSBCode) {

case SB_THUMBPOSITION:
case SB_THUMBTRACK:
m_xvRotateZ = nPos;
break;
case SB_PAGELEFT:
pageSize = m_xcRotateZ.GetPageSize();
m_xcRotateZ.GetRange(min, max);
if ((m_xvRotateZ -= pageSize) < min) m_xvRotateZ = min;
break;
case SB_PAGERIGHT:
pageSize = m_xcRotateZ.GetPageSize();
m_xcRotateZ.GetRange(min, max);
if ((m_xvRotateZ += pageSize) > max) m_xvRotateZ = max;
break;
default:
break;
}

m_xvEditZ.Format(_T("%6.1f"), (double)m_xvRotateZ);
UpdateData(FALSE);
Invalidate(FALSE);
}

CDialog::OnHScroll(nSBCode, nPos, pScrollBar);

}
```

## プログラムをビルドして, 「Slider Control」のツマミを動かしてみます. 図形が回転すると同時に, 「Edit Control」の数値が変化すると思います. 【8月26日追記】`Invalidate`(`FALSE`); の後で UpdateWindow(); を実行すれば, ツマミの操作がすぐに「Edit Control」に反映されます. 処理が重くなる気がしますけど.

![実行結果]({{ site.baseurl }}/assets/images/mfc65.gif)

## 「Edit Control」に数値を入力する

逆に, 「Edit Control」に入力した数値が「Slider Control」や表示されている図形に反映されるようにします. ここで重要な問題があります. ダイアログアプリケーションの場合, リターン (Enter) キーや `ESC` キー, Tab キーなどは, フォーカスされている (操作の対象となっている) コントロールがどれであっても, そのキーに割り当てられた操作が実行されてしまいます. リターンキーには「`OK`」ボタンのクリック, `ESC` キーには「キャンセル」ボタンのクリック, Tab キーにはフォーカスの移動が割り当てられています. このため, 特定のコントロールでリターンキーの入力を検出することができなかったり, `ESC` をタイプするといつでもダイアログウィンドウが閉じてしまったりします.
そこで, キー入力がコントロールで処理される前に呼び出される `PreTranslateMessage`() をオーバーライドして, キー入力を補足するようにします. まずクラスビューで Cプロジェクト名Dlg クラス (ここでは `CGLsampleDlg`) を選択して, プロパティの左から５つ目のボタンをクリックし, PreTranslateMassage を選択して右の▼から `PreTranslateMessage` を追加してください.

![関数 `PreTranslateMessage`() のオーバーライド]({{ site.baseurl }}/assets/images/mfc66.gif)

## `PreTranslateMessage`() を実装します.

![関数 `PreTranslateMessage`() の実装]({{ site.baseurl }}/assets/images/mfc67.gif)

## `PreTranslateMessage`(`MSG`* pMessage) がキータイプにより呼び出された場合は, `pMsg`->`message` が `WM_KEYDOWN` になっています. このとき `pMsg`->`wParam` にタイプされたキーが格納され, `pMsg`->`hwnd` にフォーカスされているコントロールの Window ハンドルが格納されています.

そこで `pMsg`->`hwnd` からそのコントロール ID を求め, それを使ってコントロールを識別します. 実はこの方法が正しいのかどうかも自信がアリマセン. `FromHandle`(`pMsg`->`hwnd`)->`GetDlgCtrlID`() とするより ::`GetDlgCtrlID`(`pMsg`->`hwnd`) とした方が手っ取り早い気がしますが, "::" が使いたくありませんでした.

```c
BOOL CGLsampleDlg::PreTranslateMessage(MSG* pMsg)
{
// TODO: ここに特定なコードを追加するか、もしくは基本クラスを呼び出してください。
if (pMsg->message == WM_KEYDOWN) {
int id;

switch (pMsg->wParam) {

case VK_RETURN:                                 // リターンキーが押されたとき
id = FromHandle(pMsg->hwnd)->GetDlgCtrlID();  // フォーカスのコントロールID
if (id == IDOK || id == IDCANCEL) {           // フォーカスが「OK」ボタンか「キャンセル」ボタンなら
break;                                      // 通常の処理（基底クラスのメソッドを呼ぶ）
}
else {                                        // フォーカスが「OK」ボタンか「キャンセル」ボタン以外
UpdateData();                               // コントロールの値の取り込み
if (id == IDC_EDIT1) {                      // フォーカスがエディットコントロール IDC_EDIT1
int min, max;                             // そのコントロールに対する処理

m_xcRotateZ.GetRange(min, max);

m_xvRotateZ = (int)_wtof(m_xvEditZ);
if (m_xvRotateZ  max)
m_xvRotateZ = max;
m_xvEditZ.Format(_T("%6.1f"), (double)m_xvRotateZ);
}
UpdateData(FALSE);                          // コントロールに値を書き戻す
Invalidate(FALSE);                          // 画面の更新
}
case VK_ESCAPE:                                 // ESC キーが押されたとき
return TRUE;                                  // 常に無視
default:                                        // それ以外のキーが押されたとき
break;                                        // 通常の処理（基底クラスのメソッドを呼ぶ）
}
}

return CDialog::PreTranslateMessage(pMsg);

}
```

## これでプログラムをビルドして実行します. 「Edit Control」に数値を入力してリターンキーをタイプすれば, 「Slider Control」と表示図形が変化するでしょうか.

![実行結果]({{ site.baseurl }}/assets/images/mfc68.gif)

## もう嫌になってきたので, 続きを書くかどうかわかりません. 多分, 書かないと思います. 他にもやらないといけないことがたくさん会あるので. ファイルオープンのダイアログくらいは書くつもりだったんだけど, 渡したソースに書いてあるから自分で考えてちょんまげ＞某君.

## プログラミングのスキルについて

実は今いるシステム工学部に移る前, 経済学部にいた時から感じていたんだけど, うちの研究室から出た人は, 就職先で「とてもプログラムが書ける人」になっていることが時々あります. もちろん, そうでない人もいます. でも, 私がとても敵わないと思える人 (まれに出る) ならまだしも, 見るからに痛い「若気の至りプログラム」を書いていた人 (しょっちゅう出る) でも結構そっち方面で頑張ってるみたいです.
だから, みんなそれなりに自信を持ちゃいいんじゃないでしょうか. 自分の思う通り, 好きなようにプログラムを書くようにしていれば, 気負わずともそれなりにプログラムが書けるようになるんじゃないかと思ってます. それで壁にぶち当たったら, 「ソフトウェア工学」の本なんかを紐解けばいいんじゃないでしょうか.
