---
title: "MFC によるダイアログベースのアプリケーション（１）"
date: 2010-08-20
categories: [OpenGL]
published: true
---

## MFC って

実は私, 使ったことないんです. それに, いまさら MFC というのもなんだかなあとは思います. 実際, 某所で UI 用のツールキットって何がいいかなって聞いてみたら Qt 一択みたいに教えてもらいました. でも私, 自分の Linux マシンから KDE 関係排除しようとして Qt も全部消しちゃったくらい Qt には近づかんとこうとしてました. んで, 今回なぜか MFC を使っちゃったんですね. いろいろ事情もあったんですけど（でもその目論見は失敗したのですけど). で, そのプログラムを以前に私自身が FLTK 使えばってアドバイスした学生さんに送っちゃったから, 罪滅ぼしに勉強した MFC の使い方をメモっておきます. もちろん, 間違ってるところがあると思います.

## 今回はこういうものを作ります.

![実行結果]({{ site.baseurl }}/assets/images/mfc32.gif)

## 以下は[数学と計算](http://mail2.nara-edu.ac.jp/~asait/)さまに大変お世話になりました. 他にもお世話になったところがたくさんあるのですけど, ありすぎて覚えてないので, 後々追加させてください.

## プロジェクトの作成

Visual Studio を起動して, 新しいプロジェクトを作成します.

![新規プロジェクトの作成]({{ site.baseurl }}/assets/images/mfc00.gif)

## プロジェクトの種類は MFC アプリケーションにします. 「プロジェクト名」を設定した後「OK」をクリックしてください. 「ソリューションのディレクトリ」は作成するまでもないでしょう.

![新しいプロジェクト]({{ site.baseurl }}/assets/images/mfc01.gif)

## MFC アプリケーションウィザードが起動したら「次へ >」をクリックして先に進みます.

 
![MFC アプリケーションウィザード]({{ site.baseurl }}/assets/images/mfc02.gif)

## アプリケーションの種類は「ダイアログベース」にします. これが一番簡単みたいです.

![アプリケーション種類]({{ site.baseurl }}/assets/images/mfc03.gif)

## ユーザインタフェース機能は「最小化ボタン」だけ付けておくことにします. サイズ変更や最大化ができるようにすると, 後の処理が少し面倒になります. 例によって手抜きですね. ウィンドウを隠すために「最小化ボタン」は付けておきます. あと, ウィンドウのタイトルバーなどに表示する「ダイアログタイトル」も設定します.

![ユーザインタフェース機能]({{ site.baseurl }}/assets/images/mfc04.gif)

## 「高度な機能」は一切使わないので, チェックボックスを全部外します.

![高度な機能]({{ site.baseurl }}/assets/images/mfc05.gif)

## これで終わりです. 「Cプロジェクト名App」と「Cプロジェクト名Dlg」の二つのクラスができていると思います. 「完了」をクリックします.

![生成されたクラス]({{ site.baseurl }}/assets/images/mfc06.gif)

## ソリューションのビルド

試に, ここで一度アプリケーションをビルドしてみます. 「ビルド」メニューから「ソリューションのビルド」を選ぶか <`em`>[F7] をタイプします.

![ソリューションのビルド]({{ site.baseurl }}/assets/images/mfc07.gif)

## コンパイルエラーが出なければ (まだ自分でコード書いてないので多分出ないと思いますが), <`em`>[F5] をタイプするなどして実行してみます.

![デバッグ開始]({{ site.baseurl }}/assets/images/mfc08.gif)

## プログラムの変更

プログラムが正常に実行できるようなら, このコードに変更を加えていきます. 最初に「プロジェクト名.cpp」ファイル (ここでは GLsample.cpp) の初期化のところで SetRegistryKey() の引数を変更します. これは別にどうでもいいんでしょうね.

![GLsample.cpp の変更]({{ site.baseurl }}/assets/images/mfc09.gif)

## `OpenGL` を使うので, ヘッダファイルやライブラリの指定を stdafx.h の最後に追加します.

```c
#pragma comment (lib, "opengl32.lib")
#pragma comment (lib, "glu32.lib")

#include <GL/gl.h>
```

## GLEW やそのほかの標準ライブラリのヘッダファイルを #`include` する場合も, ここに書けばいいんじゃないでしょうか.

![stdafx.h の変更]({{ site.baseurl }}/assets/images/mfc10.gif)

## ソースコードの上のタブをクリックして, ダイアログエディタに切り替えます.

![ダイアログエディタに切り替え]({{ site.baseurl }}/assets/images/mfc11.gif)

## ウィンドウの中央にある「`TODO`: ダイアログのコントロールをここに配置」という文字を選択し, [Delete] キーをタイプするなどして削除します. 「OK」や「キャンセル」も使わないので削除してしまいたいところですが, なんかもったいない気がする？ので今は置いておくことにします.

![ダイアログの編集]({{ site.baseurl }}/assets/images/mfc12.gif)

## ダイアログエディタの上と左にあるルーラをマウスでクリック・ドラッグして, ガイドを設定します. グリッドシステムは画面設計の基本ですね.

![ガイドの設定]({{ site.baseurl }}/assets/images/mfc13.gif)

## 「ツールボックス」のウィンドウから「Picture Control」を選びます.

![ピクチャコントロールの選択]({{ site.baseurl }}/assets/images/mfc14.gif)

## ガイドに沿ってマウスをドラッグして, 「Picture Control」を配置します.

![ピクチャコントロールの配置]({{ site.baseurl }}/assets/images/mfc15.gif)

## 「プロパティ」のウィンドウの「ID」を「IDC_STATIC」から「IDC_GLVIEW」などほかの名前に変更します. 「IDC_STATIC」は内容が変更されないコントロールの ID だそうです.

![ピクチャコントロールの ID の変更]({{ site.baseurl }}/assets/images/mfc16.gif)

## メンバ変数 (クラス変数) の追加

「クラスビュー」の中にある「Cプロジェクト名Dlg」クラス (ここでは `CGLsampleDlg`) を右クリックして, 「追加」から「変数の追加」を選びます.

![変数の追加]({{ site.baseurl }}/assets/images/mfc17.gif)

## このクラスのメンバ変数を追加します. この変数の「アクセス」は "private", 「変数の種類」は "CStatic" とします. 「変数名」は, ここでは "`m_glView`" にすることにします. その後「コントロール変数」にチェックを入れ, 「コントロールID」に "IDC_GLVIEW"  (Picture Control に設定した ID) を選択して「完了」をクリックします.

![変数 `m_glView` の追加]({{ site.baseurl }}/assets/images/mfc18.gif)

## 「Cプロジェクト名Dlg」クラス (ここでは `CGLsampleDlg`) にもう一つメンバ変数を追加します. これに Picture Control のデバイスコンテキストを保持します.

![変数の追加]({{ site.baseurl }}/assets/images/mfc19.gif)

## この変数の「アクセス」は "private", 「変数の種類」は "CDC *" にします. 「変数名」は "`m_pDC`" とかにするのが習わしなのでしょうか. 最後に「完了」をクリックします.

![変数 `m_pDC` の追加]({{ site.baseurl }}/assets/images/mfc20.gif)

## 「Cプロジェクト名Dlg」クラス (ここでは `CGLsampleDlg`) に更にもう一つメンバ変数を追加します. これに Picture Control 上に表示する `OpenGL` の領域のレンダリングコンテキストを保持します.

![変数の追加]({{ site.baseurl }}/assets/images/mfc21.gif)

## この変数の「アクセス」は "private", 「変数の種類」は "HGLRC" とします. 「変数名」は "`m_GLRC`" ということにします. 最後に「完了」をクリックします.

![変数 `m_GLRC` の追加]({{ site.baseurl }}/assets/images/mfc22.gif)

## メンバ関数 (メソッド) の追加

同じようにして, メンバ関数も追加します. 「クラスビュー」の中にある「Cプロジェクト名Dlg」クラス (ここでは `CGLsampleDlg`) を右クリックして, 「追加」から「関数の追加」を選びます.

![関数の追加]({{ site.baseurl }}/assets/images/mfc23.gif)

## この関数の「戻り値の型」は "`BOOL`" とし, 「関数名」は "SetUpPixelFormat" にすることにします. 次に「パラメータの型」に "`HDC`" を設定し, 「パラメータ名」に "`hdc`" を設定した後, 「追加」を<strong>忘れずに</strong>クリックします. また, 「アクセス」は "private" にします. 最後に「完了」をクリックします.

![関数 `SetupPixelFormat` の追加]({{ site.baseurl }}/assets/images/mfc24.gif)

## すると「プロジェクト名Dlg.cpp」ファイル (ここでは GLsampleDlg.cpp) にメンバ関数 (ここでは `SetupPixelFormat`()) が追加され, ソースコードを編集する状態になります. ここで `SetupPixelFormat`() の内容を実装します.

```c
BOOL CGLsampleDlg::SetupPixelFormat(HDC hdc)
{
PIXELFORMATDESCRIPTOR pfd = {
sizeof(PIXELFORMATDESCRIPTOR),  // PFD のサイズ
1,                              // バージョン
PFD_DRAW_TO_WINDOW |            // ウィンドウに描画する
PFD_SUPPORT_OPENGL |            // OpenGL を使う
PFD_DOUBLEBUFFER,               // ダブルバッファリングする
PFD_TYPE_RGBA,                  // RGBA モード
24,                             // カラーバッファは 24 ビット
0, 0, 0, 0, 0, 0,               //  (各チャンネルのビット数は指定しない) 
0, 0,                           // アルファバッファは使わない
0, 0, 0, 0, 0,                  // アキュムレーションバッファは使わない
32,                             // デプスバッファは 32 ビット
0,                              // ステンシルバッファは使わない
0,                              // 補助バッファは使わない
PFD_MAIN_PLANE,                 // メインレイヤー
0,                              //  (予約) 
0, 0, 0                         // レイヤーマスクは無視する
};

int pf = ChoosePixelFormat(hdc, &pfd);

if (pf != 0) return SetPixelFormat(hdc, pf, &pfd);

return FALSE;
```

## この関数では, コンピュータが備える `OpenGL` のサブシステムが用意しているピクセルフォーマットをの中から, 変数 `pfd` に設定した仕様を満たすものを `ChoosePixelFormat`() を使って選択し, 見つかったものの番号 `pf` を `SetPixelFormat`() で現在のデバイスコンテキスト `hdc` に設定します. 見つからなければ, `pf` は 0 になります.

![関数 `SetupPixelFormat`() の実装]({{ site.baseurl }}/assets/images/mfc25.gif)

## イベントハンドラの修正

次に, ダイアログウィンドウが開かれるときに呼ばれるメンバ関数 `OnInitDialog`() に処理内容を追加します. クラスビューの「Cプロジェクト名Dlg」クラス (ここでは `CGLsampleDlg`) を選択し, その下のメンバ一覧にある `OnInitDialog`(void) をダブルクリックします. 関数の本体が表示されますから, 「// `TODO`: 初期化をここに追加します。」の後に下記の内容を追加します.

```c
BOOL CGLsampleDlg::OnInitDialog()
{
CDialog::OnInitDialog();

...

// TODO: 初期化をここに追加します。

m_pDC = new CClientDC(&m_glView);

if (SetupPixelFormat(m_pDC->m_hDC) != FALSE) {
m_GLRC = wglCreateContext(m_pDC->m_hDC);
wglMakeCurrent(m_pDC->m_hDC, m_GLRC);

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
}

return TRUE;  // フォーカスをコントロールに設定した場合を除き、TRUE を返します。
```

## Picture Control に `OpenGL` による描画を行うので, そのクライアント領域にアクセスする `CClientDC` オブジェクトを, それを制御するメンバ変数 (ここでは `m_glView`) 使って生成します. これでいいんでしょうか？ 自信がアリマセン. `OpenGL` の初期設定も, ここでやってしまいます. 多分 `OpenGL` の機能の呼び出しは別の関数にまとめて, それをここで呼び出すようにしたほうがいいんでしょうけど, ここに書く手順が増えるので手を抜きます.

<blockquote>2014 年 6 月 3 日修正：`OnInitDialog`() で `m_pDC`->`m_hDC` = `m_glView`.GetDC()->GetSafeHdc(); という代入は不要だというご指摘を頂きました．ありがとうございます．</blockquote>
![関数 `OnInitDialog`() の実装]({{ site.baseurl }}/assets/images/mfc26.gif)

## 同様に, ウィンドウの描画が必要になった時に呼ばれるメンバ関数 `OnPaint`() を変更します. クラスビューの「Cプロジェクト名Dlg」クラス (ここでは `CGLsampleDlg`) を選択し, その下のメンバ一覧にある `OnPaint`(void) をダブルクリックします. 関数の本体が表示されますから, その中にある if 文の else 節に下記の内容を追加します.

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

SwapBuffers(m_pDC->m_hDC);
}
```

## シーンの描画はこの部分で行います. 今のところは, 画面クリアだけしておきます. これも別の関数にまとめておいた方がいいでしょうね.

![関数 `OnPaint`() の実装]({{ site.baseurl }}/assets/images/mfc27.gif)

## イベントハンドラの追加

ウィンドウを閉じた時に発生するイベント WM_DESTROY に対するハンドラを追加します. クラスビューの「Cプロジェクト名Dlg」クラス (ここでは `CGLsampleDlg`) を選択し, 「プロパティ」ウィンドウの「メッセージ」のボタン (左から６個目のボタン) をクリックします. イベントのリストの中から WM_DESTORY を選び, その右側の▼のボタンをクリックして, 「<追加>> `OnDestroy`」を選びます.

![WM_DESTROY イベントハンドラの追加]({{ site.baseurl }}/assets/images/mfc30.gif)

## すると「プロジェクト名Dlg.cpp」ファイル (ここでは GLsampleDlg.cpp) にメンバ関数 `OnDestroy`() が追加され, ソースコードを編集する状態になります. ここで `OnDestroy`() の内容を実装します.

```c
void CGLsampleDlg::OnDestroy()
{
CDialog::OnDestroy();

// TODO: ここにメッセージ ハンドラ コードを追加します。

wglMakeCurrent(NULL, NULL);
wglDeleteContext(m_GLRC);
delete m_pDC;
}
```

## レンダリングコンテキストをウィンドウのデバイスコンテキストから結合解除し, そのレンダリングコンテキストを削除します. またクライアント領域のデバイスコンテキストを保持している `CClientDC` オブジェクトを削除します.

![関数 `OnDestroy`() の実装]({{ site.baseurl }}/assets/images/mfc31.gif)

## 最後に, ウィンドウのサイズを変えた時に発生するイベント WM_SIZE に対するハンドラを追加します. ですが, 今作っているプログラムはウィンドウサイズの変更や最大化ができないようにしているので, 現時点ではこのイベントは発生しません. なので, <`em`>ここは省略してかまいません. 

クラスビューの「Cプロジェクト名Dlg」クラス (ここでは `CGLsampleDlg`) を選択し, 「プロパティ」ウィンドウの「メッセージ」のボタン (左から５個目のボタン) をクリックします. イベントのリストの中から WM_SIZE を選び, その右側の▼のボタンをクリックして, 「<追加> `OnSize`」を選びます.

![WM_SIZE イベントハンドラの追加]({{ site.baseurl }}/assets/images/mfc28.gif)

## すると「プロジェクト名Dlg.cpp」ファイル (ここでは GLsampleDlg.cpp) にメンバ関数 `OnSize`() が追加され, ソースコードを編集する状態になります. ここで `OnSize`() の内容を実装します.

```c
void CGLsampleDlg::OnSize(UINT nType, int cx, int cy)
{
CDialog::OnSize(nType, cx, cy);

// TODO: ここにメッセージ ハンドラ コードを追加します。

if (wglGetCurrentContext() != NULL) {
CRect rc;
m_glView.GetClientRect(&rc);
GLint width = rc.Width();
GLint height = rc.Height();
GLdouble aspect = (GLdouble)width / (GLdouble)height;

// OpenGL の初期設定
glViewport(0, 0, width, height);
glMatrixMode(GL_PROJECTION);
glLoadIdentity();
glOrtho(-aspect, aspect, -1.0, 1.0, -10.0, 10.0);
glMatrixMode(GL_MODELVIEW);
}
}
```

## `OnSize`() は `OnInitDialog`() の実行より前に一度実行されます. しかし, その時点ではまだ `OpenGL` が初期化されていないため, ここで `OpenGL` の機能を使おうとするとエラーになってしまいます (はまりました). そこで `wglGetCurrentContext`() を使って `OpenGL` が使えるかどうか確かめていますが, このやり方がいいのかどうかは知りません.

![関数 `OnSize`() の実装]({{ site.baseurl }}/assets/images/mfc29.gif)

## しかし, 繰り返しになりますが, このプログラムでは WM_SIZE イベントが `OnInitDialog`() 実行後に呼び出されることはありません. もし, ウィンドウのサイズを変更できるようにした場合は, `OnSize`() の引数 `cx`, `cy` を使って MoveWindow() などにより `OpenGL` の表示を行っている Picture Control のサイズを変更することになります. その場合は, 変更するサイズを使って `width` や `height` を求めればよいので, わざわざ `GetClientRect`() を使う必要はありません.

でも, ウィンドウのサイズを変更できるようにするには, すべてのコントロールの配置を計算し直さないといけないんですかね. もう考えるのはめんどくさいので, これは考えないことにします．

## プログラムの実行

ここで一旦プログラムをビルドし, 実行してみます. 動くかな.

![実行結果]({{ site.baseurl }}/assets/images/mfc32.gif)

## 今日は疲れたのでここまでにします. 次回以降, この `OpenGL` のウィンドウに描いた図形を Control で制御する方法をまとめる予定です.
