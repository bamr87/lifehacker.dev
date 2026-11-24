---
title: Content Hub — Year of AI Site Dashboard
description: >-
  Browse and monitor every content site in the year-of-ai org. Each repo
  publishes its own GitHub Pages site; this dashboard tracks them all in
  one place.
keywords:
  - year of ai hub
  - content dashboard
  - github pages fleet
  - self-growing knowledge bases
  - org site directory
layout: default
permalink: /hub/
sidebar:
  nav: hub
lastmod: 2026-07-08
---

# Content Hub

{% assign theme_repo = site.data.hub.pages.theme_repo | split: '@' | first %}
{% assign hub_repo = site.data.hub.org | append: '/' | append: site.data.hub.org | append: '.github.io' %}
Every repository in the organization publishes **its own** GitHub Pages site — content stays in each repo and renders with the shared [zer0-mistakes](https://github.com/{{ theme_repo }}) theme via `remote_theme`. This page is the dashboard that tracks them all; the data below is refreshed automatically by the [hub metadata sync](https://github.com/{{ hub_repo }}/blob/main/scripts/sync-hub-metadata.rb).

{% assign hub = site.data.hub_index %}
{% if hub and hub.repos and hub.repos.size > 0 %}

<p class="text-body-secondary">
  <i class="bi bi-collection me-1"></i>
{{ hub.totals.repos }} repositories · {{ hub.totals.pages }} content pages · org <a href="https://github.com/{{ hub.org }}">{{ hub.org }}</a>
</p>

<div class="row row-cols-1 row-cols-md-2 g-4 mb-5">
  {% for repo in hub.repos %}
  {% comment %} Until a repo's Pages site is live, link to the GitHub source
     (which renders the same markdown) so nothing is a dead link. {% endcomment %}
  {% assign live = repo.pages_enabled %}
  <div class="col">
    <div class="card h-100">
      <div class="card-body">
        <h2 class="card-title h5 mb-2 d-flex align-items-center">
          <i class="bi bi-journal-richtext me-2"></i>
          <span class="flex-grow-1">{{ repo.title | default: repo.name }}</span>
          {% if live %}
          <span class="badge text-bg-success" title="GitHub Pages is live">live</span>
          {% else %}
          <span class="badge text-bg-warning" title="GitHub Pages not enabled yet">pending</span>
          {% endif %}
        </h2>
        {% if repo.description and repo.description != "" %}
        <p class="card-text">{{ repo.description }}</p>
        {% endif %}
        <p class="card-text small text-body-secondary mb-2">
          {{ repo.page_count }} pages · {{ repo.sections.size }} sections
          {% if repo.pushed_at and repo.pushed_at != "" %}
          · updated {{ repo.pushed_at | date: "%Y-%m-%d" }}
          {% endif %}
          {% unless repo.scaffolded %}
          · <span class="text-warning">not scaffolded</span>
          {% endunless %}
        </p>

        {% if repo.page_count == 0 %}
        <p class="card-text small text-body-secondary fst-italic mb-0">
          <i class="bi bi-moisture me-1"></i>Freshly seeded — content is still being generated.
        </p>
        {% else %}
          {% if repo.sections.size > 0 %}
          <div class="mb-2">
          {% for section in repo.sections %}
            <a class="badge text-bg-light text-decoration-none me-1 mb-1"
               href="{% if live %}{{ section.url }}{% else %}{{ section.source_url }}{% endif %}"
               {% unless live %}target="_blank" rel="noopener"{% endunless %}>{{ section.title }} ({{ section.count }})</a>
          {% endfor %}
          </div>
          {% endif %}

          {% if repo.root_pages and repo.root_pages.size > 0 %}
          <p class="card-text small mb-0">
            <span class="text-body-secondary">Key pages:</span>
            {% for page in repo.root_pages %}
            <a href="{% if live %}{{ page.url }}{% else %}{{ page.source_url }}{% endif %}"
               {% unless live %}target="_blank" rel="noopener"{% endunless %}>{{ page.title }}</a>{% unless forloop.last %} ·{% endunless %}
            {% endfor %}
          </p>
          {% endif %}
        {% endif %}
      </div>
      <div class="card-footer bg-transparent d-flex gap-2">
        {% if live %}
        <a class="btn btn-sm btn-primary" href="{{ repo.site_url }}" target="_blank" rel="noopener">
          <i class="bi bi-box-arrow-up-right me-1"></i>Visit site
        </a>
        <a class="btn btn-sm btn-outline-secondary" href="{{ repo.url }}" target="_blank" rel="noopener">
          <i class="bi bi-github me-1"></i>Source
        </a>
        {% else %}
        <a class="btn btn-sm btn-primary" href="{{ repo.url }}" target="_blank" rel="noopener">
          <i class="bi bi-github me-1"></i>Browse on GitHub
        </a>
        <span class="btn btn-sm btn-outline-secondary disabled" title="GitHub Pages not enabled yet">
          <i class="bi bi-hourglass-split me-1"></i>Site pending
        </span>
        {% endif %}
      </div>
    </div>
  </div>
  {% endfor %}
</div>

> **Add a repository:** auto-discovery picks up new org repos on the next
> metadata sync. To publish one as a Pages site, run
> `./scripts/provision-org-sites.sh --enable-pages` from the theme repo.

{% else %}

> No hub data yet. Run `./scripts/sync-hub-metadata.sh` to populate the
> dashboard from the repositories registered in
> [`_data/hub.yml`]({{ site.repository | join: '' | prepend: "https://github.com/" }}/blob/main/_data/hub.yml),
> or wait for the scheduled **Hub Metadata Sync** workflow.

{% endif %}
