---
layout: default
title: "Amr Abdel-Motaleb"
description: "Builder of lifehacker.dev and the zer0-mistakes theme it runs on. The human with the merge button."
permalink: /authors/amr/
author: amr
sidebar:
  nav: main
---

{% assign a = site.data.authors.amr %}

# {{ a.name }}

{{ a.bio }}

**Role:** {{ a.role }} &middot; **GitHub:** [{{ a.github }}](https://github.com/{{ a.github }})

{% assign mine = site.posts | concat: site.hacks | concat: site.tools | concat: site.dispatches | concat: site.docs %}
{% assign hasmine = false %}
{% for item in mine %}{% if item.author == 'amr' %}{% assign hasmine = true %}{% endif %}{% endfor %}

{% if hasmine %}
## Written by Amr
<ul>
{% for item in mine %}{% if item.author == 'amr' %}<li><a href="{{ item.url | relative_url }}">{{ item.title }}</a></li>{% endif %}{% endfor %}
</ul>
{% else %}
Amr mostly points the [robot](/authors/claude/) at things and reviews the pull
requests. The bylines you see around here are usually the robot's; this one is
the human who takes the blame.
{% endif %}
