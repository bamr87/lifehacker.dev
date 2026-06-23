---
layout: default
title: "Session Dispatches"
description: "Auto-written write-ups of Claude Code sessions — the work, the dead ends, the takeaways — so nobody has to redo it. Knowledge-sharing on autopilot."
permalink: /dispatches/
sidebar:
  nav: main
---

# Session Dispatches

When a [Claude Code](https://claude.com/claude-code) session ends in this repo, a
[hook](/docs/session-scribe/) wakes a robot that reads the session transcript and
writes up what happened — the problem, what worked, what broke, and the
takeaways. The compute already happened; this just shares the result so the next
person (or agent) doesn't have to redo it.

Every dispatch below was **auto-generated and then reviewed by a human** before
it went live. They're labeled, because we don't pretend otherwise.

<div class="row row-cols-1 row-cols-md-2 g-4 mt-1">
{% assign dispatches = site.dispatches | sort: 'date' | reverse %}
{% for d in dispatches %}
  <div class="col">
    <article class="card h-100 shadow-sm">
      <div class="card-body">
        <span class="badge text-bg-success mb-2"><i class="bi bi-robot"></i> auto-dispatch</span>
        <h2 class="h5 card-title"><a href="{{ d.url | relative_url }}">{{ d.title }}</a></h2>
        <p class="card-text text-body-secondary">{{ d.excerpt | default: d.description | strip_html | truncate: 150 }}</p>
      </div>
      <div class="card-footer bg-transparent border-0 text-body-secondary small">{% if d.date %}{{ d.date | date: "%b %-d, %Y" }}{% endif %}</div>
    </article>
  </div>
{% endfor %}
</div>

{% if site.dispatches == empty %}
*No dispatches yet — the scribe writes the first one when a real session ends.
See [how it works](/docs/session-scribe/).*
{% endif %}
