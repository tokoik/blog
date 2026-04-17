---
lang: ja
title: 記事一覧
published: true
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
<h2>講義資料</h2>
<ul>
  <li><a href="/gg/">ゲームグラフィックス特論</a></li>
  <li><a href="/cg/">コンピュータグラフィックス</a></li>
  <li><a href="/cgpe/">CG 制作演習</a></li>
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
  <li><a href="/opengl/libglut.html">手抜き OpenGL 入門</a></li>
  <li><a href="/GLFWdraft.pdf">GLFW による OpenGL 入門 (PDF)</a></li>
  <li><a href="https://1drv.ms/b/c/97b5162e87b0c344/IQBEw7CHLha1IICXv4gDAAAAAbixVF-19IhBls8pfmQic_k?e=qy6sAS">CG 制作演習資料 (PDF)</a></li>
  <li><a href="/mpe2020.pdf">メディアプログラミング演習資料 (PDF)</a></li>
  <li><a href="/ray/">安直レイトレーシング入門</a></li>
  <li><a href="/shori1/latex.html">LaTeX の概要</a></li>
  <li><a href="/vr/vrmlintro.pdf">VRML に触ってみる (PDF)</a></li>
  <li>Processing 入門: <a href="/mdextercise1.pdf">1 日目</a>, <a href="/mdextercise2.pdf">2 日目</a>　(PDF)</li>
  <li>WebGL 入門: <a href="/cg1.pdf">第１回</a>, <a href="/cg2.pdf">第２回</a> (PDF)</li>
</ul>
<h2>その他</h2>
<ul>
  <li><a href="/ramen.pdf">和歌山ラーメンという物語</a> (うどん学会, PDF)</li>
  <li><a href="/baton.pdf">バトン</a>(PDF)</li>
</ul>
</div>
