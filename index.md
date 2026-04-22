---
lang: ja
title: 床井研究室アーカイブ
published: true
---

<!-- メインコンテンツは記事一覧 -->
<div class="main">
  <p>ここは「床井研究室」のアーカイブです。管理人の退職に伴い、職場のサーバで運用したものを、ここに移しました。<a href="https://tdiary.org/">tDiary</a> から <a href="https://docs.github.com/ja/pages/getting-started-with-github-pages/what-is-github-pages">GitHub Pages</a> に変更したので、頂いたコメントは失われています。また、内容も一部変更しています。</p>
  <h2>記事一覧</h2>
  <ul>
    {% for post in site.posts %}
      <li>
        {{ post.date | date: "%Y年%m月%d日" }} - 
        <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
      </li>
    {% endfor %}
  </ul>
　<h2>カテゴリ別記事一覧</h2>
  {% for category in site.categories %}
    {% capture category_name %}{{ category | first }}{% endcapture %}
    <h3 id="{{ category_name | slugize }}">{{ category_name }}</h3>
    <ul>
      {% for post in site.categories[category_name] %}
        <li>
          <span class="date">{{ post.date | date: "%Y/%m/%d" }}</span> — 
          <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
        </li>
      {% endfor %}
    </ul>
  {% endfor %}
</div>

<!-- サイドバーはリンク -->
<div class="sidebar">
  <h2>カテゴリ</h2>
  <ul>
    {% for category in site.categories %}
      {% capture category_name %}{{ category | first }}{% endcapture %}
      <li><a href="#{{ category_name | slugize }}">{{ category_name }}</a></li>
    {% endfor %}
  </ul>
  <h2>講義資料</h2>
  <ul>
    <li><a href="/gg/">ゲームグラフィックス特論</a></li>
    <li><a href="/cg/">コンピュータグラフィックス</a></li>
    <li><a href="/cgpe/">CG 制作演習</a>:
      <a href="https://1drv.ms/b/c/97b5162e87b0c344/IQBEw7CHLha1IICXv4gDAAAAAbixVF-19IhBls8pfmQic_k?e=qy6sAS">2020 年</a>,
      <a href="https://1drv.ms/b/c/97b5162e87b0c344/IQBEw7CHLha1IICXO5MDAAAAAa1C0PzSvBFeU546A2P1MBs?e=NUZFyu">2021 年</a>
    </li>
    <li><a href="/vd/">ビジュアルデザイン</a></li>
    <li><a href="/mm/">マルチメディア技術</a></li>
    <li><a href="/msb/">メディアサイエンス基礎</a></li>
    <li><a href="/mdp/">メディアデザイン演習</a></li>
    <li><a href="/seminar1/">メディアデザインセミナーI</a></li>
    <li><a href="/seminar2/">メディアデザインセミナーII</a></li>
    <li><a href="/shori1/">情報処理I</a></li>
    <li><a href="/shori2/">情報処理II</a></li>
    <li><a href="/kiso2/">情報基礎演習II</a></li>
    <li><a href="/kpro2/">基礎プログラミングII</a></li>
    <li><a href="/opengl/libglut.html">GLUT による「手抜き」OpenGL 入門</a></li>
    <li><a href="/GLFWdraft.pdf">GLFW による OpenGL 入門 (PDF)</a></li>
    <li><a href="/mpe2020.pdf">メディアプログラミング演習資料 (PDF)</a></li>
    <li><a href="/ray/">安直レイトレーシング入門</a></li>
    <li><a href="/shori1/latex.html">LaTeX の概要</a></li>
    <li><a href="/vr/vrmlintro.pdf">VRML に触ってみる (PDF)</a></li>
    <li>Processing 入門 (PDF):
      <a href="/mdextercise1.pdf">1 日目</a>,
      <a href="/mdextercise2.pdf">2 日目</a>
    </li>
    <li>WebGL 入門 (PDF):
      <a href="/cg1.pdf">第 1 回</a>,
      <a href="/cg2.pdf">第 2 回</a>
    </li>
  </ul>
  <h2>著書</h2>
  <ul>
    <li><a href="https://www.kyoritsu-pub.co.jp/book/b10006873.html">マルチメディアコミュニケーション</a></li>
    <li><a href="https://www.amazon.co.jp/dp/4542701344">デザイン情報学入門</a></li>
    <li><a href="https://link.springer.com/book/10.1007/978-94-017-1689-5">Geometric Modeling</a></li>
    <li><a href="https://www.kohgakusha.co.jp/books/detail/4-7775-1134-0">GLUT による OpenGL 入門</a></li>
    <li><a href="https://www.kohgakusha.co.jp/books/detail/978-4-7775-1332-1">GLUT による OpenGL 入門テクスチャマッピング編</a></li>
    <li><a href="https://www.kohgakusha.co.jp/books/detail/978-4-7775-1917-0">GLUT/freeglut による OpenGL 入門</a></li>
    <li><a href="https://www.kohgakusha.co.jp/books/detail/978-4-7775-2056-5">「グラフィックス・アプリ」制作のための OpenGL 入門</a></li>
    <li><a href="https://www.ohmsha.co.jp/book/9784274225574/">IT Text コンピュータグラフィックスの基礎</a></li>
    <li><a href="https://www.cgarts.or.jp/books_detail/ecc_1/">ディジタル映像表現</a> (名前は載ってた)</li>
  </ul>
  <h2>その他</h2>
  <ul>
    <li><a href="/a_little_further.pdf">少し先に行きたい</a> (PDF)</li>
    <li><a href="/ramen.pdf">和歌山ラーメンという物語</a> (PDF)</li>
    <li><a href="/baton.pdf">バトン</a> (PDF)</li>
  </ul>
</div>
