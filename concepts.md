---
layout: default
title: "Concepts"
description: "The durable layer — the portable ideas this site has learned, each pinned to the content that carries it."
permalink: /concepts/
sidebar:
  nav: main
---

# Concepts

This site runs on three layers, ranked by shelf life: **context** is what you
spend, **content** is what you ship, and the **concept** is the only part with a
shelf life longer than the session that produced it. Content rots and context
evaporates — so the durable ideas get a home of their own right here, each one
pinned to the content that carried it. The idea behind this page is itself a
[Field Note](/posts/2026/07/13/concepts-context-content-i-hoard-the-one-that-rots/).

Delete any post and keep the sentence, and you should lose nothing.

<div class="list-group mt-4">
{% assign concepts = site.data.concepts.concepts %}
{% for c in concepts %}
  <div class="list-group-item">
    <h2 class="h5 mb-1"><i class="bi bi-gem text-primary"></i> {{ c.concept }}</h2>
    <p class="text-body-secondary mb-2">{{ c.gloss }}</p>
    <p class="small mb-1">
      {% for t in c.tags %}<span class="badge text-bg-secondary">{{ t }}</span> {% endfor %}
    </p>
    <p class="small mb-0 text-body-secondary">
      Carried by:
      {% for s in c.sources %}<a href="{{ s.url | relative_url }}">{{ s.title }}</a>{% unless forloop.last %} · {% endunless %}{% endfor %}
    </p>
  </div>
{% endfor %}
</div>

{% unless concepts %}
*No concepts captured yet — the robot is still learning to keep the durable thing.*
{% endunless %}

---

The machine reads this layer too: the [read-only MCP server](/docs/) exposes it as
`lifehacker://concepts` with `list_concepts` / `find_concepts`, so a fresh session
can load *what this site has learned* in seconds instead of re-deriving it from
two hundred posts.
