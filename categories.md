---
layout: default
title: "Categories"
description: "Browse lifehacker.dev by category."
permalink: /categories/
sidebar:
  nav: main
---

# Categories

Browse posts by category. (Hacks and Tools have their own sections:
[Hacks](/hacks/), [Tools](/tools/).)

{% assign cats = site.categories | sort %}
{% if cats.size > 0 %}
{% for cat in cats %}
<h2 id="{{ cat[0] | slugify }}">{{ cat[0] }} <small class="text-body-secondary">({{ cat[1].size }})</small></h2>
<ul>
{% for post in cat[1] %}
  <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a> <span class="text-body-secondary small">— {{ post.date | date: "%b %-d, %Y" }}</span></li>
{% endfor %}
</ul>
{% endfor %}
{% else %}
*No categories yet.*
{% endif %}
