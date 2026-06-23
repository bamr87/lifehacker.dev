---
layout: default
title: "Tags"
description: "Browse lifehacker.dev by tag."
permalink: /tags/
sidebar:
  nav: main
---

# Tags

Every tag across hacks, tools, field notes, and dispatches.

{%- assign all = site.posts | concat: site.hacks | concat: site.tools | concat: site.dispatches -%}
{%- assign tagstr = "" -%}
{%- for item in all -%}{%- for t in item.tags -%}{%- assign tagstr = tagstr | append: t | append: "," -%}{%- endfor -%}{%- endfor -%}
{%- assign alltags = tagstr | split: "," | uniq | sort -%}

{% if alltags.size > 0 %}
<p>
{% for tag in alltags %}<a href="#{{ tag | slugify }}" class="badge text-bg-secondary text-decoration-none me-1 mb-1">{{ tag }}</a>{% endfor %}
</p>

{% for tag in alltags %}
<h2 id="{{ tag | slugify }}">{{ tag }}</h2>
<ul>
{% for item in all %}{% if item.tags contains tag %}<li><a href="{{ item.url | relative_url }}">{{ item.title }}</a></li>{% endif %}{% endfor %}
</ul>
{% endfor %}
{% else %}
*No tags yet.*
{% endif %}
