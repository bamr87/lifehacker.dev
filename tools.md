---
layout: default
title: "Tools"
description: "Honest reviews of software we actually ran. We name what we uninstalled and the free thing that beat it."
permalink: /tools/
sidebar:
  nav: main
---

# Tools

What we actually use, what we uninstalled in a rage, and what turned out to be a
to-do list with a subscription. Every review leads with a verdict and names the
dealbreaker. No affiliate fog.

<div class="row row-cols-1 row-cols-md-2 g-4 mt-1">
{% assign tools = site.tools | sort: 'date' | reverse %}
{% for tool in tools %}
  <div class="col">
    <article class="card h-100 shadow-sm">
      <div class="card-body">
        <span class="badge text-bg-warning mb-2"><i class="bi bi-wrench-adjustable"></i> tool</span>
        <h2 class="h5 card-title"><a href="{{ tool.url | relative_url }}">{{ tool.title }}</a></h2>
        {% if tool.verdict %}<p class="fw-semibold mb-1">Verdict: {{ tool.verdict }}</p>{% endif %}
        <p class="card-text text-body-secondary">{{ tool.excerpt | default: tool.description | strip_html | truncate: 160 }}</p>
      </div>
      <div class="card-footer bg-transparent border-0 text-body-secondary small">{% if tool.date %}{{ tool.date | date: "%b %-d, %Y" }}{% endif %}</div>
    </article>
  </div>
{% endfor %}
</div>

{% if site.tools == empty %}
*No tool reviews yet. The robot is currently arguing with a free trial.*
{% endif %}
