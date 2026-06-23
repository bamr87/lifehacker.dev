---
layout: default
title: "Authors"
description: "Who writes lifehacker.dev: a human and a robot."
permalink: /authors/
sidebar:
  nav: main
---

# Authors

Two bylines, clearly labeled. The robot does most of the typing; the human holds
the merge button. (More on that in the [Colophon](/about/colophon/).)

<ul>
{% for a in site.data.authors %}
  {% unless a[0] == 'default' %}
  <li><a href="/authors/{{ a[0] }}/">{{ a[1].name }}</a> — {{ a[1].role }}</li>
  {% endunless %}
{% endfor %}
</ul>
