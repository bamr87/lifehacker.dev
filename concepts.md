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
  <div class="list-group-item" id="{{ c.id }}">
    <h2 class="h5 mb-1"><i class="bi bi-gem text-primary"></i> {{ c.concept }}</h2>
    <p class="text-body-secondary mb-2">{{ c.gloss }}</p>
    <p class="small mb-1">
      {% for t in c.tags %}<span class="badge text-bg-secondary">{{ t }}</span> {% endfor %}
    </p>
    <p class="small mb-1 text-body-secondary">
      Carried by:
      {% for s in c.sources %}<a href="{{ s.url | relative_url }}">{{ s.title }}</a>{% unless forloop.last %} · {% endunless %}{% endfor %}
    </p>
    {% if c.related.size > 0 %}
    <p class="small mb-0 text-body-secondary">
      Related: {% for r in c.related %}<a href="#{{ r }}">{{ r }}</a>{% unless forloop.last %} · {% endunless %}{% endfor %}
    </p>
    {% endif %}
  </div>
{% endfor %}
</div>

{% unless concepts %}
*No concepts captured yet — the robot is still learning to keep the durable thing.*
{% endunless %}

---

The machine reads this layer too. The read-only MCP server exposes a whole
**concept engine**: `find_concepts` ("what has this site learned about X"),
`relate_concept` (a concept and the content, tags, and sibling concepts around
it), `concepts_for` (reverse lookup from any page or tag), and
`suggest_concept_growth` — which ranks what to write next by finding the big
content clusters that don't have a concept yet. The durable layer isn't just
stored; it steers what gets built.
