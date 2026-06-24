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

Every page on the site. (The machine-readable version for search engines lives
at [/sitemap.xml](/sitemap.xml).)

## Hacks
<ul>
{% assign hacks = site.hacks | sort: 'title' %}
{% for h in hacks %}<li><a href="{{ h.url | relative_url }}">{{ h.title }}</a></li>{% endfor %}
{% unless hacks.size > 0 %}<li class="text-body-secondary">Nothing here yet.</li>{% endunless %}
</ul>

## Tools
<ul>
{% assign tools = site.tools | sort: 'title' %}
{% for t in tools %}<li><a href="{{ t.url | relative_url }}">{{ t.title }}</a></li>{% endfor %}
{% unless tools.size > 0 %}<li class="text-body-secondary">Nothing here yet.</li>{% endunless %}
</ul>

## Field Notes
<ul>
{% for p in site.posts %}<li><a href="{{ p.url | relative_url }}">{{ p.title }}</a> <span class="text-body-secondary small">— {{ p.date | date: "%Y-%m-%d" }}</span></li>{% endfor %}
{% unless site.posts.size > 0 %}<li class="text-body-secondary">Nothing here yet.</li>{% endunless %}
</ul>

## About &amp; Docs
<ul>
  <li><a href="/about/">What is this?</a></li>
  <li><a href="/about/colophon/">Colophon — how this runs itself</a></li>
  <li><a href="/docs/">Docs</a></li>
  <li><a href="/docs/autopilot/">The Autopilot Playbook</a></li>
  <li><a href="/docs/health/">Site Health — the live triage queue</a></li>
  <li><a href="/search/">Search</a></li>
</ul>
