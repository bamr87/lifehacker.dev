---
layout: default
title: "Sitemap"
description: "Everything on lifehacker.dev, in one place."
permalink: /sitemap/
sitemap: false
sidebar:
  nav: main
---

# Sitemap

Every page on the site. (The machine-readable version for search engines lives at [/sitemap.xml](/sitemap.xml).)

The [Newsroom](/news/) collects it all; each section below is also its own landing: [Hacks](/news/hacks/) · [Tools](/news/tools/) · [Field Notes](/news/field-notes/).

## Hacks
<ul>
{% assign hacks = site.posts | where_exp: "p", "p.categories contains 'Hacks'" | sort: 'title' %}
{% for h in hacks %}<li><a href="{{ h.url | relative_url }}">{{ h.title }}</a></li>{% endfor %}
{% unless hacks.size > 0 %}<li class="text-body-secondary">Nothing here yet.</li>{% endunless %}
</ul>

## Tools
<ul>
{% assign tools = site.posts | where_exp: "p", "p.categories contains 'Tools'" | sort: 'title' %}
{% for t in tools %}<li><a href="{{ t.url | relative_url }}">{{ t.title }}</a></li>{% endfor %}
{% unless tools.size > 0 %}<li class="text-body-secondary">Nothing here yet.</li>{% endunless %}
</ul>

## Field Notes
<ul>
{% assign notes = site.posts | where_exp: "p", "p.categories contains 'Field Notes'" | sort: 'date' | reverse %}
{% for p in notes %}<li><a href="{{ p.url | relative_url }}">{{ p.title }}</a> <span class="text-body-secondary small">— {{ p.date | date: "%Y-%m-%d" }}</span></li>{% endfor %}
{% unless notes.size > 0 %}<li class="text-body-secondary">Nothing here yet.</li>{% endunless %}
</ul>

## About &amp; Docs
<ul>
{% assign abouts = site.about | sort: 'title' %}
{% for p in abouts %}<li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>{% endfor %}
{% assign docpages = site.docs | sort: 'title' %}
{% for p in docpages %}<li><a href="{{ p.url | relative_url }}">{{ p.title }}</a></li>{% endfor %}
  <li><a href="/search/">Search</a></li>
</ul>
{% comment %}Self-healing: About/Docs pages list themselves from their collections,
so this block can no longer drift. The fleet needs no unattended writer for it.{% endcomment %}
