---
layout: default
title: "Hacks"
description: "Real fixes for real problems — the dev kind and the life kind — with the failed attempts left in."
permalink: /hacks/
sidebar:
  nav: main
---

# Hacks

A real fix for a real problem. Every hack here was actually run, and every one
ships with the dead end that came before it. If it didn't work, it isn't here —
it became a [Field Note](/blog/) about why.

<div class="row row-cols-1 row-cols-md-2 g-4 mt-1">
{% assign hacks = site.hacks | sort: 'date' | reverse %}
{% for hack in hacks %}
  <div class="col">
    <article class="card h-100 shadow-sm">
      <div class="card-body">
        <span class="badge text-bg-info mb-2"><i class="bi bi-lightbulb"></i> hack</span>
        <h2 class="h5 card-title"><a href="{{ hack.url | relative_url }}">{{ hack.title }}</a></h2>
        <p class="card-text text-body-secondary">{{ hack.excerpt | default: hack.description | strip_html | truncate: 160 }}</p>
      </div>
      <div class="card-footer bg-transparent border-0 text-body-secondary small">{% if hack.date %}{{ hack.date | date: "%b %-d, %Y" }}{% endif %}</div>
    </article>
  </div>
{% endfor %}
</div>

{% if site.hacks == empty %}
*No hacks published yet — the robot is still testing the first batch on itself.*
{% endif %}
