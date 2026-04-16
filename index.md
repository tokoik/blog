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

### 講義

- [ゲームグラフィックス特論](https://web.wakayama-u.ac.jp/~tokoi/lecture/gg/)
- [コンピュータグラフィックス](https://web.wakayama-u.ac.jp/~tokoi/lecture/cg/)
- [ＣＧ制作演習](https://www.wakayama-u.ac.jp/~tokoi/lecture/cgpe/)
- [ＣＧ入門](https://web.wakayama-u.ac.jp/~tokoi/lecture/cgintro/)
- [デザイン情報入門セミナー](https://web.wakayama-u.ac.jp/~tokoi/lecture/intro/)
- [デザイン情報概論](https://web.wakayama-u.ac.jp/~tokoi/lecture/gairon/)
- [ビジュアルデザイン](https://web.wakayama-u.ac.jp/~tokoi/lecture/vd/)
- [マルチメディア技術](https://web.wakayama-u.ac.jp/~tokoi/lecture/mm/)
- [メディアサイエンス基礎](https://web.wakayama-u.ac.jp/~tokoi/lecture/msb/)
- [メディアデザイン演習](https://web.wakayama-u.ac.jp/~tokoi/lecture/mdp/)
- [情報メディア総合演習](https://web.wakayama-u.ac.jp/~itou/IMDE/top/)
- [メディアデザインセミナーI](https://www.wakayama-u.ac.jp/~tokoi/lecture/seminar1/)
- [メディアデザインセミナーII](https://web.wakayama-u.ac.jp/~tokoi/lecture/seminar2/)
- [情報処理I](https://web.wakayama-u.ac.jp/~tokoi/lecture/shori1/)
- [情報処理II](https://web.wakayama-u.ac.jp/~tokoi/lecture/shori2/)
- [情報基礎演習II](https://web.wakayama-u.ac.jp/~tokoi/lecture/kiso2/)
- [基礎プログラミングII](https://web.wakayama-u.ac.jp/~tokoi/lecture/kpro2/)

### その他

- [手抜き OpenGL 入門](https://tokoik.github.io/opengl/libglut.html)
- [GLFW による OpenGL 入門 (PDF)](https://tokoik.github.io/GLFWdraft.pdf)
- [ＣＧ制作演習資料 (PDF)](https://web.wakayama-u.ac.jp/~tokoi/cgpe2020.pdf)
- [メディアプログラミング演習資料 (PDF)](https://web.wakayama-u.ac.jp/~tokoi/mpe2020.pdf)
- [安直レイトレーシング入門](https://web.wakayama-u.ac.jp/~tokoi/lecture/ray/)
- [LaTeX の概要](https://web.wakayama-u.ac.jp/~tokoi/lecture/shori1/latex.html)
- [VRMLに触ってみる(PDF)](https://web.wakayama-u.ac.jp/~tokoi/lecture/vr/vrmlintro.pdf)

### リンク

- [相互作用的電脳図画研究室](https://media.sys.wakayama-u.ac.jp/tokoi-lab/)
- [メディアデザインメジャー](https://www.wakayama-u.ac.jp/sys/major/md/)
- [システム工学部](https://www.wakayama-u.ac.jp/sys/)
- [和歌山大学](https://www.wakayama-u.ac.jp/)
- [和歌山 障害児とコンピュータ・ネットワーク利用研究会](https://ccnwakayama.blog.jp/)

</div>
