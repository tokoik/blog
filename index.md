---
title: 記事一覧
draft: false
---

<ul>
  {% for post in site.posts %}
    <li>
      {{ post.date | date: "%Y年%m月%d日" }} - 
      <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    </li>
  {% endfor %}
</ul>
