---
title: Lineage — the living year knowledge-base family
description: >-
  Every self-growing year repo in the year-of-ai lineage, its growth state,
  and how each was spawned — orchestrated centrally by the hub.
keywords:
  - year of ai lineage
  - self-growing knowledge base
  - year repos
  - growth ticks
  - central orchestration
layout: default
permalink: /lineage/
sidebar:
  nav: hub
lastmod: 2026-07-29
---

# Lineage

Every repository here is a **self-growing knowledge base** that researches and writes its own content one daily *tick* at a time. This hub is the central orchestrator — it reads each repo's lifecycle state, triggers their growth, and presents the result. Each repo grows **perpetually** and is never retired; new ones are spawned tangentially from the frontier, so the lineage only ever grows.
See [**AI Orchestration**]({{ '/orchestration/' | relative_url }}) for the full
model, the growth process, and the strategy behind it.

{% assign lin = site.data.lineage %}
{% if lin and lin.members and lin.members.size > 0 %}

<p class="text-body-secondary">
  <i class="bi bi-diagram-3 me-1"></i>
{{ lin.totals.repos }} living knowledge bases · {{ lin.totals.ticks }} growth ticks logged · org <a href="https://github.com/{{ lin.org }}">{{ lin.org }}</a> · refreshed by
  <a href="https://github.com/{{ site.repository | join: '' }}/blob/main/scripts/sync-lineage-state.rb">sync-lineage-state</a>
</p>

{% comment %} status → badge colour {% endcomment %}
<div class="row row-cols-1 row-cols-md-2 g-4 mb-5">
  {% assign members = lin.members | sort: "name" %}
  {% for m in members %}
  <div class="col">
    <div class="card h-100">
      <div class="card-body">
        <h2 class="card-title h5 mb-1 d-flex align-items-center">
          <i class="bi bi-journal-richtext me-2"></i>
          <span class="flex-grow-1">{{ m.name }}</span>
          {% case m.status %}
            {% when 'growing' %}<span class="badge text-bg-success" title="Actively growing">growing</span>
            {% when 'mature' %}<span class="badge text-bg-primary" title="Fully grown; shepherds the frontier">mature</span>
            {% when 'consolidated' %}<span class="badge text-bg-info" title="Consolidated group; deepening">consolidated</span>
            {% else %}<span class="badge text-bg-secondary">{{ m.status | default: 'seeded' }}</span>
          {% endcase %}
        </h2>
        <p class="card-text text-body-secondary mb-2">{{ m.subject }}</p>

        <p class="card-text small mb-2">
          <span class="badge text-bg-light me-1"><i class="bi bi-activity me-1"></i>{{ m.ticks_logged | default: 0 }} ticks</span>
          {% if m.granularity and m.granularity != '' %}<span class="badge text-bg-light me-1"><i class="bi bi-rulers me-1"></i>{{ m.granularity }}</span>{% endif %}
          {% if m.lineage_size and m.lineage_size > 0 %}<span class="badge text-bg-light me-1"><i class="bi bi-collection me-1"></i>{{ m.lineage_size }} in lineage</span>{% endif %}
          {% if m.last_activity and m.last_activity != '' %}<span class="text-body-secondary">· last grew {{ m.last_activity }}</span>{% endif %}
        </p>

        {% comment %} lineage edges — how this repo relates to the others {% endcomment %}
        <ul class="list-unstyled small mb-0">
          {% if m.spawned_from and m.spawned_from != '' %}
          <li><i class="bi bi-arrow-up-right-circle me-1 text-body-secondary"></i>spawned from
            <a href="https://github.com/{{ m.spawned_from }}">{{ m.spawned_from | split: '/' | last }}</a></li>
          {% endif %}
          {% if m.spawned_lineage and m.spawned_lineage != '' %}
          <li><i class="bi bi-arrow-down-right-circle me-1 text-body-secondary"></i>spawned the lineage
            <a href="https://github.com/{{ m.spawned_lineage }}">{{ m.spawned_lineage | split: '/' | last }}</a></li>
          {% endif %}
          {% if m.consolidated_from and m.consolidated_from.size > 0 %}
          <li><i class="bi bi-diagram-2 me-1 text-body-secondary"></i>consolidates
            {% for c in m.consolidated_from %}<a href="https://github.com/{{ c }}">{{ c | split: '/' | last }}</a>{% unless forloop.last %}, {% endunless %}{% endfor %}</li>
          {% endif %}
        </ul>
      </div>
      <div class="card-footer bg-transparent d-flex gap-2">
        <a class="btn btn-sm btn-outline-primary" href="{{ m.site_url }}" target="_blank" rel="noopener">
          <i class="bi bi-box-arrow-up-right me-1"></i>Site
        </a>
        <a class="btn btn-sm btn-outline-secondary" href="{{ m.url }}" target="_blank" rel="noopener">
          <i class="bi bi-github me-1"></i>Source
        </a>
        {% comment %} Member repos carry no workflows under the central model —
           the growth heartbeat lives in the hub's grow-lineage engine. {% endcomment %}
        <a class="btn btn-sm btn-outline-secondary" href="https://github.com/{{ lin.org }}/{{ lin.org }}.github.io/actions/workflows/grow-lineage.yml" target="_blank" rel="noopener" title="Growth heartbeat (hub engine)">
          <i class="bi bi-activity me-1"></i>Ticks
        </a>
      </div>
    </div>
  </div>
  {% endfor %}
</div>

> **How it grows:** each year repo holds only its content + a GitHub Pages
> `_config.yml` + `.claude/` + `telemetry/`. The **seed** for every year lives
> here in the hub under
> [`lineage/seeds/`](https://github.com/{{ site.repository | join: '' }}/tree/main/lineage/seeds),
> and the hub is the central orchestrator: it researches and writes each year's
> content through a Haiku → Sonnet → Opus escalation, then publishes to the
> year's own Pages site. See the [content hub]({{ '/hub/' | relative_url }}) for
> published-page counts per year.

{% else %}

> No lineage data yet. Run `ruby scripts/sync-lineage-state.rb` to read each
> repo's `lifecycle.yml` + `seed.md` and populate
> [`_data/lineage.yml`](https://github.com/{{ site.repository | join: '' }}/blob/main/_data/lineage.yml).

{% endif %}
