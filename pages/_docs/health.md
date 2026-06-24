---
layout: default
title: "Site Health"
description: "What the robots think is wrong with lifehacker.dev right now — the live triage queue, ranked."
permalink: /docs/health/
author: claude
sidebar:
  nav: tree
---

# Site Health

This page is generated. The test harness lints the site on every pull request and
writes its findings to a frozen contract; the triage bot ranks them into the queue
below. Nothing here is hand-typed — if it's wrong, that's a bug about a bug, which
is the most lifehacker.dev thing that can happen.

{% assign s = site.data.health.summary %}
{% if s %}
**Last triage:** {{ s.generated_at }} · **In the queue:** {{ s.queue_size }}
{% if s.analytics_stale %}· _analytics not yet connected — ranking by severity only_{% endif %}

## By severity

<ul>
{% for row in s.by_severity %}<li><strong>{{ row[0] }}</strong>: {{ row[1] }}</li>{% endfor %}
</ul>

## By route

<ul>
{% for row in s.by_route %}<li><strong>{{ row[0] }}</strong>: {{ row[1] }}</li>{% endfor %}
</ul>

## Top of the queue

{% assign q = site.data.health.queue %}
{% if q and q.size > 0 %}
<table>
<thead><tr><th>score</th><th>sev</th><th>type</th><th>where</th><th>route</th></tr></thead>
<tbody>
{% for item in q limit: 15 %}
<tr>
  <td>{{ item.score }}</td>
  <td>{{ item.severity }}</td>
  <td>{{ item.type }}</td>
  <td><code>{{ item.url_path | default: item.file }}</code></td>
  <td>{{ item.route }}</td>
</tr>
{% endfor %}
</tbody>
</table>
{% else %}
<p class="text-body-secondary">Queue is empty. Either everything works or the robot is lying. (It builds first, so probably the former.)</p>
{% endif %}

{% else %}
<p class="text-body-secondary">No triage run recorded yet. Run <code>scripts/triage/build_queue.rb</code> after the test harness.</p>
{% endif %}

---

The harness, the contract, and the ranking are documented in
[the Autopilot Playbook](/docs/autopilot/) and `docs/runbook-fleet.md`.
