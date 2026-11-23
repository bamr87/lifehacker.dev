---
title: AI World View
description: >-
  A federated network of self-growing knowledge bases — one country at a time,
  each published as its own site, all rendered with the shared zer0-mistakes theme.
layout: home
permalink: /
sidebar: false
hide_intro: true
---

<section class="text-center py-5">
  <h1 class="display-4 fw-bold mb-3">AI World View</h1>
  <p class="lead text-body-secondary mx-auto" style="max-width: 46rem;">
    A federated, self-growing knowledge base of the world — <strong>one country at
    a time</strong>. Each country is its own repository that researches and writes
    its own content, daily, and publishes its own site with the shared
    <a href="https://github.com/bamr87/zer0-mistakes">zer0-mistakes</a> theme.
    The geographic mirror of <a href="https://year-of-ai.github.io/">Year of AI</a>,
    planted from the same organizational genome.
  </p>
  <div class="d-flex justify-content-center gap-2 mt-4">
    <a class="btn btn-primary btn-lg" href="https://github.com/ai-world-view"><i class="bi bi-github me-1"></i>Organization</a>
  </div>
</section>

{% assign hub = site.data.hub_index %}
{% if hub and hub.repos and hub.repos.size > 0 %}
<div class="row row-cols-2 row-cols-md-3 row-cols-lg-4 g-3 mb-5">
  {% for repo in hub.repos %}
  <div class="col"><a class="card h-100 text-decoration-none text-reset shadow-sm" href="{{ repo.site_url | default: repo.url }}">
    <div class="card-body text-center"><div class="h4 fw-bold mb-1 text-capitalize">{{ repo.name | replace: '-', ' ' }}</div>
    <div class="small text-body-secondary">{% if repo.page_count == 0 %}seeded{% else %}{{ repo.page_count }} pages{% endif %}</div></div>
  </a></div>
  {% endfor %}
</div>
{% else %}
<p class="text-center text-body-secondary">The knowledge base is being seeded — countries are generated automatically, one growth tick at a time. The first is <strong>Japan</strong>.</p>
{% endif %}
