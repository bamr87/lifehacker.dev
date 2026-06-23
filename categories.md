---
layout: default
title: "Categories"
description: "Browse lifehacker.dev by category."
permalink: /categories/
sitemap: false
sidebar:
  nav: main
---

# Categories

Hand-authored, like the [sitemap](/sitemap/) and search index — GitHub Pages
won't run the archive-generating plugin, so this page lists posts by category
with Liquid the safe-mode build can render.

{% assign cats = site.categories | sort %}
{% for cat in cats %}
<h2 id="{{ cat[0] | slugify }}">{{ cat[0] }}</h2>
<ul>
{% for post in cat[1] %}<li><a href="{{ post.url | relative_url }}">{{ post.title }}</a> <span class="text-body-secondary small">— {{ post.date | date: "%Y-%m-%d" }}</span></li>{% endfor %}
</ul>
{% endfor %}
{% unless cats.size > 0 %}<p class="text-body-secondary">No categories yet.</p>{% endunless %}
