---
layout: default
title: Entries
permalink: /entries/
description: >
  Every entry in the vault, grouped by branch — forms, works, figures,
  instances, paradoxes, mirrors, futures, and the nursery of drafts awaiting judgment.
---

Every irony states an **expectation** and a **reversal**; every paradox states **premises**, an **inference**, a **conclusion**, and the **collision** that makes it unacceptable. A candidate that cannot fill its fields is not an entry — it goes to the compost with a verdict, as [merely unfortunate]({{ site.baseurl }}/entries/the-merely-unfortunate/) or [merely puzzling]({{ site.baseurl }}/entries/the-merely-puzzling/).

{% assign sections = "forms|works|figures|instances|paradoxes|mirrors|futures|nursery" | split: "|" %}
{% assign labels = "The Trunk — Forms and Ways|Works|Figures|Instances|Paradoxes — premises accepted, conclusions refused|Mirrors — this machine's own ironies|Futures — expectations on record, reversals pending|Nursery — drafts awaiting the gate and a human hand" | split: "|" %}

<nav class="mb-4" aria-label="Jump to section">
  {% for s in sections %}
    {% assign items = site.entries | where: "section", s %}
    {% if items.size > 0 %}<a class="btn btn-sm btn-outline-secondary me-1 mb-1" href="#{{ s }}">{{ s }} <span class="badge bg-secondary">{{ items.size }}</span></a>{% endif %}
  {% endfor %}
</nav>

{% for s in sections %}
  {% assign items = site.entries | where: "section", s | sort: "title" %}
  {% if items.size > 0 %}
<h2 id="{{ s }}">{{ labels[forloop.index0] }}</h2>
<div class="list-group mb-4">
  {% for e in items %}
  {% assign gate = e.alanis | default: e.epimenides %}
  <a class="list-group-item list-group-item-action" href="{{ e.url | relative_url }}">
    <div class="d-flex w-100 justify-content-between align-items-start">
      <h3 class="h6 mb-1">{{ e.title }}</h3>
      <small class="text-nowrap ms-2">
        {% if gate %}<span class="badge bg-light text-dark">{{ gate }}</span>{% endif %}
        {% if e.kind %}<span class="badge bg-light text-dark">{{ e.kind }}</span>{% endif %}
        {% if e.standing %}<span class="badge bg-light text-dark">{{ e.standing }}</span>{% endif %}
        {% if e.veracity %}<span class="badge bg-light text-dark">{{ e.veracity }}</span>{% endif %}
      </small>
    </div>
    {% if e.premises %}
    <p class="mb-1 small"><strong>Premises:</strong> {% for p in e.premises %}{{ p | strip_newlines }}{% unless forloop.last %} · {% endunless %}{% endfor %}</p>
    {% if e.conclusion %}<p class="mb-0 small text-muted"><strong>Conclusion:</strong> {{ e.conclusion | strip_newlines | truncate: 160 }}</p>{% endif %}
    {% else %}
    {% if e.expectation %}<p class="mb-1 small"><strong>Expectation:</strong> {{ e.expectation | strip_newlines | truncate: 160 }}</p>{% endif %}
    {% if e.reversal %}<p class="mb-0 small text-muted"><strong>Reversal:</strong> {{ e.reversal | strip_newlines | truncate: 160 }}</p>{% endif %}
    {% endif %}
  </a>
  {% endfor %}
</div>
  {% endif %}
{% endfor %}
