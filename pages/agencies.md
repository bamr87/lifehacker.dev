---
layout: default
title: "Agencies"
description: "The bureaus that file under the lifehacker.dev masthead: each with its own beat, its own voice and its own archive."
permalink: /agencies/
sidebar:
  nav: main
---

# Agencies

A newsroom has desks. A news agency has bureaus: outposts with their own beat, their own voice and their own filing cabinet. These are ours. Each keeps its archive under its own path on this site, and none of it is mixed into the [news](/news/).

<div class="list-group mt-4">
{% for agency in site.data.agencies.agencies %}
  {% for s in agency.sites %}
    {% if s.published %}
  <a class="list-group-item list-group-item-action" href="{{ s.published.url | relative_url }}">
    <h2 class="h5 mb-1"><i class="bi bi-building text-primary"></i> {{ agency.name }}</h2>
    <p class="text-body-secondary mb-2">{{ agency.beat }}</p>
    <p class="small mb-0">{{ s.published.pages }} pages · filed under <code>{{ s.published.url }}</code></p>
  </a>
    {% endif %}
  {% endfor %}
{% endfor %}
</div>
