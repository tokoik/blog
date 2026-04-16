---
title: 記事一覧
draft: false
---

<div class="main">
<ul>
  {% for post in site.posts %}
    <li>
      {{ post.date | date: "%Y年%m月%d日" }} - 
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    </li>
  {% endfor %}
</ul>
</div>

<div class="sidebar">

<h3>講義</h3>
<ul>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/gg/">ゲームグラフィックス特論</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/cg/">コンピュータグラフィックス</a></li>
  <li><a href="https://www.wakayama-u.ac.jp/~tokoi/lecture/cgpe/">ＣＧ制作演習</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/cgintro/">ＣＧ入門</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/intro/">デザイン情報入門セミナー</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/gairon/">デザイン情報概論</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/vd/">ビジュアルデザイン</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/mm/">マルチメディア技術</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/msb/">メディアサイエンス基礎</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/mdp/">メディアデザイン演習</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~itou/IMDE/top/">情報メディア総合演習</a></li>
  <li><a href="https://www.wakayama-u.ac.jp/~tokoi/lecture/seminar1/">メディアデザインセミナーI</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/seminar2/">メディアデザインセミナーII</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/shori1/">情報処理I</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/shori2/">情報処理II</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/kiso2/">情報基礎演習II</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/kpro2/">基礎プログラミングII</a></li>
</ul>
<h3>その他</h3>
<ul>
  <li><a href="https://tokoik.github.io/opengl/libglut.html">手抜き OpenGL 入門</a></li>
  <li><a href="https://tokoik.github.io/GLFWdraft.pdf">GLFW による OpenGL 入門 (PDF)</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/cgpe2020.pdf">ＣＧ制作演習資料 (PDF)</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/mpe2020.pdf">メディアプログラミング演習資料 (PDF)</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/ray/">安直レイトレーシング入門</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/shori1/latex.html">LaTeX の概要</a></li>
  <li><a href="https://web.wakayama-u.ac.jp/~tokoi/lecture/vr/vrmlintro.pdf">VRMLに触ってみる(PDF)</a></li>
</ul>
<h3>リンク</h3>
<ul>
  <li><a href="https://media.sys.wakayama-u.ac.jp/tokoi-lab/">相互作用的電脳図画研究室</a></li>
  <li><a href="https://www.wakayama-u.ac.jp/sys/major/md/">メディアデザインメジャー</a></li>
  <li><a href="https://www.wakayama-u.ac.jp/sys/">システム工学部</a></li>
  <li><a href="https://www.wakayama-u.ac.jp/">和歌山大学</a></li>
  <li><a href="https://ccnwakayama.blog.jp/">和歌山 障害児とコンピュータ・ネットワーク利用研究会</a></li>
</ul>

</div>
