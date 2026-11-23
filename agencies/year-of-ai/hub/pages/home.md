---
title: Year of AI — Self-Growing Knowledge Base Network
description: >-
  The organization hub for a federated network of self-growing, year-by-year
  knowledge bases, each published as its own site with the shared
  zer0-mistakes theme.
keywords:
  - year of ai
  - self-growing knowledge base
  - federated knowledge network
  - AI-generated encyclopedia
  - year-by-year history
layout: home
permalink: /
sidebar: false
hide_intro: true
lastmod: 2026-07-08
---

<section class="text-center py-5">
  <h1 class="display-4 fw-bold mb-3">Year of AI</h1>
  <p class="lead text-body-secondary mx-auto" style="max-width: 46rem;">
    A federated network of self-growing knowledge bases — one repository per
    year, each publishing its own site and rendered with the shared
    <a href="https://github.com/{{ site.data.hub.pages.theme_repo | split: '@' | first }}">zer0-mistakes</a>
    theme. Pick a year to explore, or open the hub dashboard to see everything
    at once.
  </p>
  <div class="d-flex justify-content-center gap-2 mt-4">
    <a class="btn btn-primary btn-lg" href="{{ '/hub/' | relative_url }}">
      <i class="bi bi-grid-1x2 me-1"></i>Open the hub dashboard
    </a>
    <a class="btn btn-outline-primary btn-lg" href="{{ '/orchestration/' | relative_url }}">
      <i class="bi bi-cpu me-1"></i>How it grows
    </a>
    <a class="btn btn-outline-secondary btn-lg" href="https://github.com/{{ site.github_user }}">
      <i class="bi bi-github me-1"></i>Organization
    </a>
  </div>
</section>

{% assign hub = site.data.hub_index %}
{% if hub and hub.repos and hub.repos.size > 0 %}

<h2 class="h4 mb-3"><i class="bi bi-calendar3 me-2"></i>The years</h2>
<p class="text-body-secondary">{{ hub.totals.repos }} knowledge bases · {{ hub.totals.pages }} pages and growing.</p>

<div class="row row-cols-2 row-cols-md-3 row-cols-lg-4 g-3 mb-5">
  {% assign years = hub.repos | sort: "name" %}
  {% for repo in years %}
  {% comment %} Live site if Pages is enabled, otherwise the GitHub source. {% endcomment %}
  {% assign live = repo.pages_enabled %}
  <div class="col">
    <a class="card h-100 text-decoration-none text-reset shadow-sm{% unless live %} opacity-75{% endunless %}"
       href="{% if live %}{{ repo.site_url }}{% else %}{{ repo.url }}{% endif %}"
       {% unless live %}target="_blank" rel="noopener"{% endunless %}>
      <div class="card-body text-center">
        <div class="display-6 fw-bold mb-1">{{ repo.name }}</div>
        <div class="small text-body-secondary">
          {% if repo.page_count == 0 %}seeded{% else %}{{ repo.page_count }} pages{% endif %}
        </div>
        {% if live %}
        <span class="badge text-bg-success mt-2">live</span>
        {% else %}
        <span class="badge text-bg-secondary mt-2"><i class="bi bi-github me-1"></i>on GitHub</span>
        {% endif %}
      </div>
    </a>
  </div>
  {% endfor %}
</div>

<p class="text-center text-body-secondary">
  <a href="{{ '/hub/' | relative_url }}">See the full dashboard →</a>
</p>

{% else %}

> The hub registry has no data yet. Run `./scripts/sync-hub-metadata.sh` to
> populate it from the repositories in
> [`_data/hub.yml`](https://github.com/{{ site.repository | join: '' }}/blob/main/_data/hub.yml).

{% endif %}
