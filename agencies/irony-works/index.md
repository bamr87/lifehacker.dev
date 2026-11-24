---
layout: home
title: Irony Works
hide_title: true
rss_subscribe: false
permalink: /
preview: /assets/images/previews/default.svg
description: >
  Irony is not a mood. It is a structure — an expectation, and a reversal that
  comments on it. A self-growing encyclopedia that requires every entry to state
  both, so that irony becomes machine-checkable.
---

{%- comment -%}
  ============================================================================
  NEWS / MAGAZINE HOMEPAGE
  ----------------------------------------------------------------------------
Modeled on lifehacker.dev's news homepage, sourced from this site's real content. Every card teases with the entry's `reversal` — the payload of an irony — rather than a generic excerpt. Branch colours come from _data/sections.yml, which carries the same hexes as the Obsidian graph.
  Card chrome lives in _includes/home/.
  ============================================================================
{%- endcomment -%}

{%- comment -%}
Jekyll gives every collection document a `date`, and one with none of its own gets the build's clock. Only `planted` (which transplant.mjs copies into `date`) says when an entry was planted, so it, not `date`, decides what is dated — else the vault index and the compost ledgers read as planted today on every build.
{%- endcomment -%}
{%- assign dated = site.entries | where_exp: "e", "e.planted" | sort: "date" | reverse -%}
{%- assign gated = site.entries | where_exp: "e", "e.reversal" -%}

{%- comment -%} Hero = the vault's signature specimen, with a fallback to newest. {%- endcomment -%}
{%- assign hero = site.entries | where: "slug", "the-kodak-moment" | first -%}
{%- unless hero -%}{%- assign hero = dated | first -%}{%- endunless -%}

{%- assign pick_main = site.entries | where: "slug", "ozymandias" | first -%}
{%- assign pick_slugs = "oscar-wilde|the-streisand-effect|thomas-midgley-jr|nobels-obituary" | split: "|" -%}

{%- comment -%}
The theme's `home` layout is bare — `<div class="home">{{ content }}</div>` with no Bootstrap container — so this page supplies its own gutters.
{%- endcomment -%}
<div class="container py-4">

<!-- ============================= MASTHEAD ============================= -->
<div class="bg-dark text-white py-3 px-4 mb-4 rounded-4">
  <div>
    <div class="row align-items-center g-2">
      <div class="col-md-5">
        <h1 class="h4 mb-0" style="font-family: ui-monospace, Menlo, monospace;">
          <i class="bi bi-arrow-repeat me-2"></i>{{ site.title }}
        </h1>
        <small class="text-white-50">Expectation, reversed. Recursively.</small>
      </div>
      <div class="col-md-7">
        <nav class="nav nav-pills justify-content-md-end flex-wrap">
          {%- assign bar = "instances|paradoxes|works|figures|mirrors|futures|nursery" | split: "|" -%}
          {%- for key in bar -%}
            {%- assign m = site.data.sections[key] -%}
            <a class="nav-link text-white-50 px-2 py-1" href="{{ m.url | relative_url }}">
              <i class="bi {{ m.icon }} me-1"></i>{{ m.label }}
            </a>
          {%- endfor -%}
        </nav>
      </div>
    </div>
  </div>
</div>

<!-- ============================= TOP STORY ============================= -->
{% if hero %}
<section class="mb-5">
  <div class="row g-0 rounded-4 overflow-hidden shadow-lg position-relative" style="background:#1b1b1f;">
    <div class="col-lg-7 p-4 p-lg-5 d-flex flex-column justify-content-center text-white">
      <span class="badge text-bg-danger align-self-start mb-3"><i class="bi bi-lightning-fill me-1"></i>The specimen case</span>
      <h2 class="display-6 fw-bold mb-3">{{ hero.title }}</h2>

      <p class="mb-1 small text-uppercase text-white-50" style="letter-spacing:.08em;">Expectation</p>
      <p class="mb-3">{{ hero.expectation | strip_newlines }}</p>
      <p class="mb-1 small text-uppercase text-white-50" style="letter-spacing:.08em;">Reversal</p>
      <p class="lead mb-4">{{ hero.reversal | strip_newlines }}</p>

      <div class="d-flex align-items-center gap-3 mb-4 flex-wrap small text-white-50">
        {% if hero.alanis %}<span><i class="bi bi-funnel me-1"></i>Gate {{ hero.alanis }}</span>{% endif %}
        {% if hero.veracity %}<span><i class="bi bi-shield-check me-1"></i>{{ hero.veracity }}</span>{% endif %}
        {% if hero.planted %}<span><i class="bi bi-calendar3 me-1"></i>Planted {{ hero.date | date: "%B %-d, %Y" }}</span>{% endif %}
      </div>
      <a href="{{ hero.url | relative_url }}" class="btn btn-light btn-lg align-self-start">
        Read the entry <i class="bi bi-arrow-right ms-2"></i>
      </a>
    </div>
    <div class="col-lg-5 d-none d-lg-block">
      {% include home/cover.html section=hero.section preview=hero.preview alt=hero.title height='100%' class='h-100' %}
    </div>
  </div>
</section>
{% endif %}

<!-- ============================= WHAT COUNTS ============================= -->
<section class="mb-5">
  <div class="row g-4 align-items-center">
    <div class="col-lg-7">
      <h2 class="h4 mb-3"><i class="bi bi-rulers text-secondary me-2"></i>What counts as an entry</h2>
      <p class="mb-2">
        Rain on a wedding day is weather. A meteorologist rained out of her own wedding is closer.
        A meteorologist rained out of the wedding she scheduled <strong>using her own forecast</strong> — that's an entry.
      </p>
      <p class="mb-2 text-body-secondary">
        Irony is not a mood. It is an <strong>expectation</strong> and a <strong>reversal</strong> that comments on it.
        Because that structure is mechanical, it can be required: every entry states both as frontmatter fields.
        A candidate that cannot fill both is not irony — it is merely unfortunate, and it goes to the
        <a href="{{ '/compost/' | relative_url }}">compost</a> with a verdict.
      </p>
      <p class="mb-0 text-body-secondary">
        The vault's second genus runs the same discipline on reasoning. A
        <a href="{{ '/paradoxes/' | relative_url }}">paradox</a> states <strong>premises</strong> a reader accepts,
        an <strong>inference</strong> the reader cannot fault, a <strong>conclusion</strong> the reader refuses, and the
        <strong>collision</strong> that makes it unacceptable — scored at the
        <a href="{{ '/entries/epimenides-gate/' | relative_url }}">Epimenides Gate</a>.
      </p>
    </div>
    <div class="col-lg-5">
      <div class="p-3 rounded-4 border">
        <div class="small text-uppercase text-body-secondary mb-2" style="letter-spacing:.08em;">The schema is the classifier</div>
<pre class="mb-0 small"><code>expectation: &gt;
    Kodak would own whatever
    photography became.
reversal: &gt;
    Kodak invented the digital
    camera in 1975, shelved it,
    and was bankrupted by it.</code></pre>
      </div>
    </div>
  </div>
</section>

<!-- ============================= THE BRANCHES ============================= -->
<section class="mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h2 class="h4 mb-0"><i class="bi bi-signpost-split text-secondary me-2"></i>The branches</h2>
    <a href="{{ '/entries/' | relative_url }}" class="btn btn-outline-secondary btn-sm">All entries <i class="bi bi-arrow-right ms-1"></i></a>
  </div>
  <div class="row row-cols-2 row-cols-md-3 g-3">
    {%- assign branches = "forms|works|figures|instances|paradoxes|mirrors|futures|nursery|compost" | split: "|" -%}
    {% for key in branches %}
      {%- assign m = site.data.sections[key] -%}
      {%- assign n = site.entries | where: "section", key | size -%}
      <div class="col">
        <a href="{{ m.url | relative_url }}" class="card text-center h-100 text-decoration-none border-0 shadow-sm">
          <div class="card-body py-4">
            <i class="bi {{ m.icon }} fs-3 d-block mb-2 sec-ink sec-{{ key }}"></i>
            <h3 class="h6 card-title mb-1">{{ m.label }}</h3>
            <small class="text-body-secondary d-block">{{ n }} entr{% if n == 1 %}y{% else %}ies{% endif %}</small>
            <small class="text-body-secondary d-block mt-1" style="font-size:.75rem;">{{ m.blurb }}</small>
          </div>
        </a>
      </div>
    {% endfor %}
  </div>
</section>

<!-- ============================= EDITOR'S PICKS ============================= -->
{% if pick_main %}
<section class="mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h2 class="h4 mb-0"><i class="bi bi-star-fill text-warning me-2"></i>Editor's picks</h2>
  </div>
  <div class="row g-4">
    <div class="col-lg-6">
      <div class="card h-100 border-0 shadow overflow-hidden">
        {% include home/cover.html section=pick_main.section height='300px' preview=pick_main.preview alt=pick_main.title %}
        <div class="card-body">
          <span class="badge text-bg-warning mb-2"><i class="bi bi-star-fill me-1"></i>Ten out of ten</span>
          <h3 class="h4 card-title">
            <a href="{{ pick_main.url | relative_url }}" class="text-decoration-none text-body-emphasis stretched-link">{{ pick_main.title }}</a>
          </h3>
          <p class="card-text text-body-secondary">{{ pick_main.reversal | strip_newlines | truncate: 180 }}</p>
        </div>
      </div>
    </div>
    <div class="col-lg-6">
      <div class="row row-cols-1 row-cols-md-2 g-4">
        {% for slug in pick_slugs %}
          {%- assign p = site.entries | where: "slug", slug | first -%}
          {% if p %}<div class="col">{% include home/card.html item=p cover_height='120px' %}</div>{% endif %}
        {% endfor %}
      </div>
    </div>
  </div>
</section>
{% endif %}

<!-- ============================= BY BRANCH ============================= -->
{%- assign feeds = "instances|paradoxes|works|mirrors" | split: "|" -%}
{% for key in feeds %}
  {%- assign m = site.data.sections[key] -%}
  {%- assign items = site.entries | where: "section", key -%}
  {% if items.size > 0 %}
  <section class="mb-5 pb-4 border-bottom">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h2 class="h4 mb-0">
        <i class="bi {{ m.icon }} me-2 sec-ink sec-{{ key }}"></i>{{ m.label }}
        <small class="text-body-secondary fw-normal ms-2" style="font-size:.9rem;">{{ m.blurb }}</small>
      </h2>
      <a href="{{ m.url | relative_url }}" class="btn btn-outline-secondary btn-sm text-nowrap">View all <i class="bi bi-arrow-right ms-1"></i></a>
    </div>
    <div class="row row-cols-1 row-cols-sm-2 row-cols-lg-4 g-4">
      {% for it in items limit: 4 %}
        <div class="col">{% include home/card.html item=it cover_height='150px' %}</div>
      {% endfor %}
    </div>
  </section>
  {% endif %}
{% endfor %}

<!-- ============================= LATEST ============================= -->
<section class="mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h2 class="h4 mb-0"><i class="bi bi-clock-history text-secondary me-2"></i>Recently planted</h2>
  </div>
  <div class="row g-4">
    {% for it in dated limit: 6 %}
      {%- assign m = site.data.sections[it.section] -%}
      <div class="col-md-6 col-lg-4">
        <div class="card border-0 shadow-sm h-100 overflow-hidden">
          <div class="row g-0 h-100">
            <div class="col-4">{% include home/cover.html section=it.section height='110px' class='h-100' preview=it.preview alt=it.title %}</div>
            <div class="col-8">
              <div class="card-body py-2 px-3">
                <span class="badge sec-badge sec-{{ it.section }} mb-1">{{ m.label | default: it.section }}</span>
                <h3 class="h6 card-title mb-1">
                  <a href="{{ it.url | relative_url }}" class="text-decoration-none text-body-emphasis stretched-link">{{ it.title | truncate: 48 }}</a>
                </h3>
                <small class="text-body-secondary"><i class="bi bi-calendar3 me-1"></i>{{ it.date | date: "%b %-d" }}</small>
              </div>
            </div>
          </div>
        </div>
      </div>
    {% endfor %}
  </div>
</section>

<!-- ============================= THE PIPELINE ============================= -->
<section class="mb-5">
  <div class="row g-4">
    <div class="col-md-6">
      <div class="card h-100 border-0 shadow-sm">
        <div class="card-body">
          <h2 class="h5 card-title">
            <i class="bi bi-flower1 me-2 sec-ink sec-nursery"></i>In the nursery
          </h2>
          <p class="text-body-secondary small">
            {{ site.entries | where: "section", "nursery" | size }} draft(s) have passed the gate and await a human merge.
            Nothing reaches canon automatically — merging is the selection pressure.
          </p>
          <ul class="list-unstyled small mb-3">
            {% for it in site.entries limit: 100 %}
              {% if it.section == "nursery" %}
              <li class="mb-1"><i class="bi bi-dot"></i><a href="{{ it.url | relative_url }}">{{ it.title }}</a></li>
              {% endif %}
            {% endfor %}
          </ul>
          <a href="{{ '/nursery/' | relative_url }}" class="btn btn-sm btn-outline-secondary">See what's pending <i class="bi bi-arrow-right ms-1"></i></a>
        </div>
      </div>
    </div>
    <div class="col-md-6">
      <div class="card h-100 border-0 shadow-sm">
        <div class="card-body">
          <h2 class="h5 card-title">
            <i class="bi bi-recycle me-2 sec-ink sec-compost"></i>What the gates threw out
          </h2>
          <p class="text-body-secondary small">
            Rejected candidates are never deleted. Each is logged with a verdict —
            <code>MERELY-UNFORTUNATE</code>, <code>BAD-LUCK</code>, <code>COINCIDENCE</code>,
            <code>HYPOCRISY</code>, <code>NOT-EVEN-WRONG</code> — because the negative space of a
            definition teaches as much as the definition, and history occasionally files an appeal.
          </p>
          <p class="text-body-secondary small mb-3">
            The Alanis Gate's inaugural session composted the entire tracklist of the song it is named after;
            the song itself is canon. The Epimenides Gate's inaugural session composted the sentence it is
            named after — a Cretan on Cretans — as a transparent fallacy; the sentence's descendant, the Liar,
            is canon. Paradox rejects go to a second ledger with their own verdicts.
          </p>
          <a href="{{ '/compost/' | relative_url }}" class="btn btn-sm btn-outline-secondary me-1">Read the ledger <i class="bi bi-arrow-right ms-1"></i></a>
          <a href="{{ '/entries/alanis-gate/' | relative_url }}" class="btn btn-sm btn-outline-secondary">The gate <i class="bi bi-arrow-right ms-1"></i></a>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- ============================= COLOPHON ============================= -->
<section class="mb-4">
  <div class="p-4 rounded-4 border">
    <div class="row align-items-center g-3">
      <div class="col-md-8">
        <h2 class="h5 mb-2"><i class="bi bi-diagram-3 text-secondary me-2"></i>Grown by machine, curated by hand</h2>
        <p class="mb-0 text-body-secondary small">
          A scheduled engine proposes candidates, an adversarial gate scores them on five axes, and
          survivors arrive as a pull request. The source of truth is an
          <a href="https://obsidian.md">Obsidian</a> vault of Markdown; this site is a pressing of it.
          The whole graph — drafts and rejects included — is
          <a href="https://github.com/{{ site.repository | join: '' }}">public on GitHub</a>.
        </p>
      </div>
      <div class="col-md-4 text-md-end">
        <a href="{{ '/how-it-grows/' | relative_url }}" class="btn btn-primary">How it grows <i class="bi bi-arrow-right ms-1"></i></a>
      </div>
    </div>
  </div>
</section>

</div><!-- /.container -->

