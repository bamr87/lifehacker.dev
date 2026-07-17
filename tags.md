---
layout: default
title: "Tags"
description: "Browse lifehacker.dev by tag."
permalink: /tags/
sitemap: false
sidebar:
  nav: main
---

# Tags

Hand-authored (the archive plugin doesn't run on GitHub Pages). Tags are pooled across posts, hacks, and tools so every `#tag` the theme links to resolves here.

{% assign all_docs = site.posts | concat: site.hacks | concat: site.tools %}
{% capture tagblob %}{% for d in all_docs %}{% for t in d.tags %}{{ t }},{% endfor %}{% endfor %}{% endcapture %}
{% assign all_tags = tagblob | split: "," | uniq | sort %}
{% for tag in all_tags %}{% unless tag == "" %}
<h2 id="{{ tag | slugify }}">{{ tag }}</h2>
<ul>
{% for d in all_docs %}{% if d.tags contains tag %}<li><a href="{{ d.url | relative_url }}">{{ d.title }}</a></li>{% endif %}{% endfor %}
</ul>
{% endunless %}{% endfor %}
{% unless all_tags.size > 0 %}<p class="text-body-secondary">No tags yet.</p>{% endunless %}
