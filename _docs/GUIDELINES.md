# ブログ記事およびサンプルプログラム移行ガイドライン

本ドキュメントは、「床井研究室」ブログ（tDiary）から GitHub Pages への移行、および関連するサンプルプログラムの整理・移行に関する仕様と手順をまとめたガイドラインです。

---

## 1. 概要とリポジトリ構成

### 1.1 ブログリポジトリ

- **移行元ブログ「床井研究室」**: `https://marina.sys.wakayama-u.ac.jp/~tokoi/`
  - 移行元ブログデータ: `tokoi@marina.sys.wakayama-u.ac.jp:blog`
- **移行先ブログ**: `https://tokoik.github.io/blog/`
  - 移行先ローカルリポジトリ: `D:\Users\tokoi\Documents\Projects\blog`
  - 移行先リモートリポジトリ: `git@github.com:tokoik/blog.git`

### 1.2 サンプルプログラムリポジトリ

- **移行元**:
  - Windows ローカルリポジトリ群: `D:\Users\tokoi\Documents\Projects`
  - Linux ローカルリポジトリ群: `tokoi@marina.sys.wakayama-u.ac.jp:Projects`
  - リモートリポジトリ群: `tokoi@marina.sys.wakayama-u.ac.jp:git`
- **移行先**:
  - 移行先リモートリポジトリ（一次プッシュ先）: `tokoi@marina.sys.wakayama-u.ac.jp:git`
  - 最終移行先（動作確認後）: `git@github.com:tokoik`

---

## 2. ブログ記事の移行仕様 (Jekyll / GitHub Pages)

記事は 1 つずつ変換・移行し、その都度適切な日本語のコミットメッセージを付けて commit および push します。

### 2.1 ディレクトリ構成と移動

- **元記事ファイル**: `_drafts/` 配下に slug 付きのファイル名で配置されています。
- **移行先**: 変換・整形後に `_posts/` へ移動します。
- **画像・静的アセット**:
  - 記事から参照される画像ファイルは、記事のファイル名の slug にもとづいて、`assets/images/` 以下のサブディレクトリ（`texture/` や `glsl/` 等）に配置します。
  - 画像以外の静的ファイル（zip 等）は `assets/` 直下に配置します。
  - 同一ディレクトリ内でファイル名が重複する場合は連番を付与します（例: `figure-1.png`, `figure-2.png`）。

### 2.2 Front Matter の仕様

以下の項目のみを記載します（余分な項目は含めない）：

```yaml
---
title: "記事のタイトル"
category: 資料 # シリーズ連載記事の場合は連載名（例: [今風 OpenGL の使い方]）、その他は [資料] または [雑記]
tags: [OpenGL, GLSL] # 関連タグ（OpenGL, GLSL, ゼミ, FBO 等）を併記
math: true        # 数式を含む場合のみ指定
published: true
---
```

#### カテゴリ・タグの変換規則

- **シリーズ連載記事**: 連載名を `categories` に設定し、関連タグ（`OpenGL`, `GLSL`, `ゼミ`, `FBO` 等）を `tags` に併記します。
- **単発の資料記事**: tDiary のカテゴリ `[OpenGL]` → `category: 資料`、`tags: [OpenGL]`（必要に応じて `GLSL` 等も追加）
- **雑記・メモ記事**: tDiary のカテゴリ `[雑文]` や `[メモ]` → `category: 雑記`

### 2.3 本文の整形・記法ルール

1. **見出しと空行ルール**:
   - **Markdown のすべての見出し（`#`, `##`, `###`, `####` 等）の直後には必ず空行を入れます。**
2. **段落・空行の調整**:
   - Markdown として正しく段落やリストが認識されるよう、適切な空行を挿入します。
3. **プログラムコード**:
   - プログラムコードは言語指定付きのコードブロック（例: ` ```cpp `, ` ```glsl `）にします。
   - **ファイル名や GLSL のデータ型（attribute, in, out, varying, uniform, vec2, vec3, vec4, mat3, mat4, float, int 等）はインラインのコードブロックにしない**ようにします（サンプルプログラム内のソースファイル名コメントは保持します）。
   - `_CRT_SECURE_NO_WARNINGS` はソースコード内で定義し、`#pragma warning(disable: 4996)` の行は削除します。
   - GLEW を使う場合は `glext.h` をインクルードする必要はないため、`#include <GL/glext.h>` や `#include "glext.h"` の行は削除します。
4. **数式表示 (`math: true`)**:
   - インライン数式: `$ ... $`
   - ディスプレイ（ブロック）数式: `$$ ... $$`
5. **画像リンク**:
   - 書式: `![代替テキスト]({{ site.baseurl }}/assets/images/<サブディレクトリ名>/ファイル名)`
6. **記事内リンク（過去記事へのリンク）**:
   - tDiary の日付（例: `?date=YYYYMMDD`）をもとに対応する `_drafts` / `_posts` のファイル名を特定します。
   - 書式: `{{ site.baseurl }}{% post_url YYYY-MM-DD-slug %}`
   - [前回] の記事を参照するときは `[前回]({{ page.previous | relative_url }})`
   - ※ 旧 URL からのリダイレクトは旧サーバー側で処理するため、移行先での個別リダイレクト設定は不要です。
7. **サンプルプログラムへのリンク**:
   - 書式: `https://github.com/tokoik/<リポジトリ名>`
8. **tDiary 固有記法・不要要素の処理**:
   - **脚注**: `((%...%))` は `[^1]` および記事末尾の `[^1]: 注釈内容` の形式に変換します。
   - **キーワード・書籍リンク**: amazon プラグイン等の書籍リンクやキーワード自動リンクは除去します。
   - **ツッコミ（コメント）**: 元記事のコメントはすべて破棄します。

---

## 3. サンプルプログラムの仕様 (C++ / CMake)

### 3.1 ファイル構成・文字コード・改行コード

- **アーカイブの展開**: 移行元のサンプルプログラムが LZH, ZIP, tar.gz 等のアーカイブのみの場合は展開して Git リポジトリ化します。
- **文字コード**:
  - C / C++ ソース・ヘッダ (`.h`, `.c`, `.cpp`): **BOM 付き UTF-8**
  - それ以外のテキストファイル (`.vert`, `.frag`, `.geom`, `.comp`, `.md`, `CMakeLists.txt`, `.gitignore` 等): **BOM 無し UTF-8**
- **改行コード**: **CRLF**（Windows 上で作業）
- **シェーダ拡張子**:
  - バーテックスシェーダ: `.vert`
  - フラグメントシェーダ: `.frag`
  - ジオメトリシェーダ: `.geom`
  - コンピュートシェーダ: `.comp`

### 3.2 開発環境とビルド仕様

- **言語標準**: C++17
- **ビルドツール**: CMake（最小要求バージョン `3.22`）
- **シェル環境**: PowerShell（`git`, `cmake`, `python` が利用可能）
- **外部ライブラリ管理**:
  - 古いサンプルプログラムで用いている GLUT は **freeglut** に移行します。
  - GLEW を使用する場合、`glext.h` は不要なため `#include <GL/glext.h>` や `#include "glext.h"` は削除します。
  - CMake 標準の `FetchContent` を利用し、プロジェクト内の `libs/` フォルダへ自動ダウンロード・構成します。
  - 主な使用ライブラリとバージョン:
    - **freeglut**: master（または安定リリース）
    - **GLFW**: 3.5.1
    - **GLEW**: 2.3.1
    - **GLM**: 1.0.3
    - **stb_image**: 最新版
    - **ImGui**: v1.92.9b
    - **Native File Dialog Extended**: v1.3.0
    - **OpenCV**: 4.13.0（v4 系最新）
- **デバッグ作業ディレクトリ**:
  - ビルド出力先またはリソース配置先を実行時カレントディレクトリに指定します（`VS_DEBUGGER_WORKING_DIRECTORY`, `XCODE_SCHEME_WORKING_DIRECTORY`）。

### 3.3 マルチプラットフォーム対応

- **Windows (Visual Studio)**:
  - Visual Studio のソリューションファイルを作成可能にします。
  - サンプルプログラムのプロジェクトをスタートアッププロジェクトに設定します。
  - GLSL ソースファイルは `"Shader Files"` フィルタに配置します。
  - その他実行に必要なファイルは `"Resource Files"` フィルタに配置します。
  - 実行時リソースはビルド時にバイナリ出力先（実行ファイルと同じ場所）へコピーします。
  - 外部ライブラリは `libs/` に自動ダウンロードします。
  - `_CRT_SECURE_NO_WARNINGS` はソースコード内で定義するため、Visual Studio の設定（プリプロセッサ定義等）には含めないでください。
  - ソースコード内の `#pragma warning(disable: 4996)` の行は削除してください。
- **macOS (Xcode)**:
  - Xcode プロジェクトファイルを作成可能にします。
  - `.app` アプリケーションバンドルを作成し、必要なリソースをバンドル内にコピーします。
  - 外部ライブラリは `libs/` に自動ダウンロードします。
- **Ubuntu Linux (Makefile)**:
  - Makefile を作成可能にします。
  - システム（ローカルマシン）にインストールされているパッケージ（`find_package`, `pkg-config`）を優先利用します。
  - 未インストールのパッケージがある場合は、インストールを促すメッセージを出力します。

### 3.4 添付必須ファイル

1. **`LICENSE`**:
   - MIT ライセンス
   - 著作権表記: `Copyright (c) 2006-2026 Kohe Tokoi`
2. **`README.md`**:
   - 見出し直後には必ず空行を入れ、以下の構成で記述します：
     1. **概要**（移行元のブログ記事へのリンクを必ず含める）
     2. **対応環境**
     3. **ビルド手順**
     4. **起動方法**
     5. **操作方法**
     6. **プログラムの解説**
3. **`.gitattributes` および `.gitignore`**:
   - 既存リポジトリに存在する場合はそれを流用し、無い場合は標準のものを作成します。
   - `.gitignore` は Visual Studio, Xcode, CMake の `build/`, VS Code などを除外します。
   - **重要**: `bunny.obj` など Wavefront OBJ 形式の 3D モデルファイルが中間オブジェクトファイル（`*.obj`）として誤って除外されないよう設定します（例: `!*.obj` や特定フォルダ指定）。

### 3.5 リポジトリ名・ブランチ・Git 運用

- **リポジトリ名 / フォルダ名**:
  - 既存プロジェクト名（`glsl0`, `texture15` など）を極力踏襲します。
  - 新規作成時は小文字統一、ハイフン区切りとし、シリーズ物の場合は連番を付与します。
- **デフォルトブランチ**:
  - 新規作成時は `main`
  - 既存リポジトリがある場合は既存のブランチ名に合わせます。
- **プッシュ手順**:
  1. サンプルプログラムの移行・整備が完了したら、適切な日本語コミットメッセージで commit します。
  2. `tokoi@marina.sys.wakayama-u.ac.jp:git/<リポジトリ名>.git` を `origin` として push します。
  3. 各プラットフォーム（Windows, macOS, Linux）でのビルド・動作確認後、GitHub（`git@github.com:tokoik/<リポジトリ名>.git`）へ push します。
