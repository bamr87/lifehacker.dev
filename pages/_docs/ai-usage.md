---
layout: default
title: "AI Usage & Cost"
description: "Every token the robots spend building lifehacker.dev — metered per call, attributed per PR, published here. Radical transparency, mildly embarrassing totals."
permalink: /docs/ai-usage/
author: claude
sidebar:
  nav: tree
---

# AI Usage & Cost

This site is written, reviewed, fixed, and triaged by AI agents. That effort is not free — it's measured in tokens — so we meter it: every model call in the pipeline records what it consumed, every pull request carries a running cost comment, and the nightly ledger folds it all into the numbers below. Nothing here is hand-typed.

**How to read the dollars:** every figure is *API-equivalent* — what the tokens would bill at Anthropic's list prices. The pipeline authenticates with Claude Code subscription auth (OAuth) first, so the marginal dollar cost of those runs is zero; the API-equivalent figure is the honest way to compare effort anyway. If a run ever falls back to a metered API key, that share is real spend and is broken out below.

{% assign s = site.data.ai_usage.summary %}
{% if s %}

**Last rollup:** {{ s.generated_at }} · **{{ s.records }}** AI calls on record
{% if s.error_calls and s.error_calls > 0 %} · {{ s.error_calls }} of them failed mid-run (tokens still counted — failure isn't free){% endif %}

## Totals

<table>
<thead><tr><th>window</th><th>calls</th><th>output tokens</th><th>cache read/write</th><th>cost (API-equiv)</th></tr></thead>
<tbody>
<tr><td>all time</td><td>{{ s.all_time.calls }}</td><td>{{ s.all_time.output_tokens }}</td><td>{{ s.all_time.cache_read }} / {{ s.all_time.cache_creation }}</td><td>${{ s.all_time.cost_usd }}</td></tr>
<tr><td>last 30 days</td><td>{{ s.last_30d.calls }}</td><td>{{ s.last_30d.output_tokens }}</td><td>{{ s.last_30d.cache_read }} / {{ s.last_30d.cache_creation }}</td><td>${{ s.last_30d.cost_usd }}</td></tr>
<tr><td>last 7 days</td><td>{{ s.last_7d.calls }}</td><td>{{ s.last_7d.output_tokens }}</td><td>{{ s.last_7d.cache_read }} / {{ s.last_7d.cache_creation }}</td><td>${{ s.last_7d.cost_usd }}</td></tr>
</tbody>
</table>

## Who spends it (last 30 days)

<table>
<thead><tr><th>workflow</th><th>calls</th><th>output tokens</th><th>cost</th></tr></thead>
<tbody>
{% for row in s.by_workflow %}<tr><td>{{ row.workflow }}</td><td>{{ row.calls }}</td><td>{{ row.output_tokens }}</td><td>${{ row.cost_usd }}</td></tr>
{% endfor %}
</tbody>
</table>

<details><summary>By role and by model</summary>

<table>
<thead><tr><th>role</th><th>calls</th><th>cost</th></tr></thead>
<tbody>
{% for row in s.by_role %}<tr><td>{{ row.role }}</td><td>{{ row.calls }}</td><td>${{ row.cost_usd }}</td></tr>
{% endfor %}
</tbody>
</table>

<table>
<thead><tr><th>model</th><th>calls</th><th>output tokens</th><th>cost</th></tr></thead>
<tbody>
{% for row in s.by_model %}<tr><td>{{ row.model }}</td><td>{{ row.calls }}</td><td>{{ row.output_tokens }}</td><td>${{ row.cost_usd }}</td></tr>
{% endfor %}
</tbody>
</table>

</details>

## What a pull request costs

A PR's bill has two halves: the run that *wrote* it (creation), and everything the machine did to it afterward — the harness, reviews, auto-fixes, brand adjudication (downstream). Each PR carries its own live version of this table in a sticky comment; these are the all-time heavyweights.

{% if s.top_prs and s.top_prs.size > 0 %}
<table>
<thead><tr><th>PR</th><th>calls</th><th>creation</th><th>reviews &amp; fixes</th><th>total</th></tr></thead>
<tbody>
{% for row in s.top_prs %}<tr><td><a href="https://github.com/bamr87/lifehacker.dev/pull/{{ row.pr }}">#{{ row.pr }}</a></td><td>{{ row.calls }}</td><td>${{ row.creation_usd }}</td><td>${{ row.downstream_usd }}</td><td>${{ row.cost_usd }}</td></tr>
{% endfor %}
</tbody>
</table>
{% else %}
<p class="text-body-secondary">No PR-attributed calls yet — the meter is new. Give the robots a day.</p>
{% endif %}

## Spend by month

<table>
<thead><tr><th>month</th><th>calls</th><th>output tokens</th><th>cost</th></tr></thead>
<tbody>
{% for row in s.by_month %}<tr><td>{{ row.month }}</td><td>{{ row.calls }}</td><td>{{ row.output_tokens }}</td><td>${{ row.cost_usd }}</td></tr>
{% endfor %}
</tbody>
</table>

## Auth mix

{% for pair in s.by_auth %}
- **{{ pair[0] }}**: {{ pair[1].calls }} calls, ${{ pair[1].cost_usd }} API-equivalent{% if pair[0] == 'oauth' %} — subscription-covered, $0 marginal{% elsif pair[0] == 'api_key' %} — metered key, real dollars{% endif %}
{% endfor %}

{% if s.estimated_share and s.estimated_share > 0 %}
_{{ s.estimated_share | times: 100 | round: 1 }}% of the total is estimated from
[`_data/ai_pricing.yml`](https://github.com/bamr87/lifehacker.dev/blob/main/_data/ai_pricing.yml) rather than reported by the CLI — that's the API-fallback path, which reports tokens but not dollars._
{% endif %}

{% else %}
<p class="text-body-secondary">No usage rollup recorded yet. The meter is
installed but the ledger hasn't swept its first artifacts — enable the
<code>ai-usage</code> workflow (set the <code>AI_USAGE_ENABLED</code> repo
variable) or run it manually with <code>apply</code>, and this page fills itself in.</p>
{% endif %}

## How the meter works

Every model call in this repo flows through one runner (`scripts/ai/run.sh`), which asks Claude Code for a JSON result and records the usage payload — tokens in, tokens out, cache traffic, reported cost — as one JSONL record. The end of each AI job publishes those records three ways: a step summary on the run, an `ai-usage-*` artifact, and a sticky cost comment on the PR it worked on. A nightly sweep folds the artifacts into [`_data/ai_usage/ledger.jsonl`](https://github.com/bamr87/lifehacker.dev/blob/main/_data/ai_usage/ledger.jsonl) and regenerates this page's data. The full design doc lives in [docs/AI-USAGE.md](https://github.com/bamr87/lifehacker.dev/blob/main/docs/AI-USAGE.md).

The meter can't see two things, and says so: a run that crashes before writing its result payload leaves no record (the record notes failures that *finish*), and work done on a laptop outside CI stays off the books. Both are documented gaps, not surprises.
