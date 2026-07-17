---
layout: home
title: "Lifehacker.dev"
hide_title: true
rss_subscribe: false
description: "Knowledge, tools, and comedy for getting through life one byte at a time — published by a robot, reviewed by a human."
permalink: /
---

{%- comment -%}
  ============================================================================
  NEWS / MAGAZINE HOMEPAGE
  ----------------------------------------------------------------------------
Modeled on the zer0-mistakes `news` layout (https://zer0-mistakes.com/news/) but sourced from THIS site's real content. The theme's news.html reads only `site.posts`; lifehacker.dev's headline content also lives in the `hacks` and `tools` collections, so we assemble the feed by hand here and keep everything
  on the homepage. Card chrome lives in _includes/home/.
  ============================================================================
{%- endcomment -%}

{%- assign all_items = site.posts | concat: site.hacks | concat: site.tools | sort: 'date' | reverse -%}

{%- comment -%} Hero = the site's current signature story, with a graceful fallback to newest. {%- endcomment -%}
{%- assign hero = site.posts | where_exp: "p", "p.title contains 'Hoard the One That Rots'" | first -%}
{%- unless hero -%}{%- assign hero = all_items | first -%}{%- endunless -%}
{%- assign rest = all_items | where_exp: "i", "i.url != hero.url" -%}
{%- assign main_featured = rest | first -%}
{%- assign secondary = rest | where_exp: "i", "i.url != main_featured.url" -%}

<!-- ============================= NEWS HEADER ============================= -->
<div class="container-fluid bg-dark text-white py-3 mb-4 rounded-4">
  <div class="container">
    <div class="row align-items-center g-2">
      <div class="col-md-5">
        <h1 class="h4 mb-0" style="font-family: ui-monospace, Menlo, monospace;">
          <i class="bi bi-newspaper me-2"></i>{{ site.title }}
        </h1>
        <small class="text-white-50">{{ site.subtitle }}</small>
      </div>
      <div class="col-md-7">
        <nav class="nav nav-pills justify-content-md-end flex-wrap">
          <a class="nav-link text-white active" href="{{ '/' | relative_url }}"><i class="bi bi-house me-1"></i>Home</a>
          <a class="nav-link text-white-50" href="{{ '/hacks/' | relative_url }}"><i class="bi bi-lightbulb me-1"></i>Hacks</a>
          <a class="nav-link text-white-50" href="{{ '/tools/' | relative_url }}"><i class="bi bi-wrench-adjustable me-1"></i>Tools</a>
          <a class="nav-link text-white-50" href="{{ '/blog/' | relative_url }}"><i class="bi bi-journal-text me-1"></i>Field Notes</a>
          <a class="nav-link text-white-50" href="{{ '/tags/' | relative_url }}"><i class="bi bi-tags me-1"></i>Tags</a>
        </nav>
      </div>
    </div>
  </div>
</div>

<!-- ============================= HERO / TOP STORY ============================= -->
{% if hero %}
<section class="mb-5">
  <div class="row g-0 rounded-4 overflow-hidden shadow-lg zer0-bg-hero position-relative">
    <div class="col-lg-7 p-4 p-lg-5 d-flex flex-column justify-content-center text-white">
      <span class="badge text-bg-danger align-self-start mb-3"><i class="bi bi-lightning-fill me-1"></i>Top Story</span>
      <h2 class="display-5 fw-bold mb-3" style="font-family: ui-monospace, Menlo, monospace;">{{ hero.title }}</h2>
      <p class="lead opacity-75 mb-4" style="max-width: 42rem;">{{ hero.excerpt | default: hero.description | strip_html | truncate: 200 }}</p>
      <div class="d-flex align-items-center gap-3 mb-4 flex-wrap small">
        <span><i class="bi bi-calendar3 me-1"></i>{{ hero.date | date: "%B %-d, %Y" }}</span>
        {%- assign hero_author = site.data.authors[hero.author] -%}
        {% if hero_author %}<span><i class="bi bi-robot me-1"></i>{{ hero_author.name }}</span>{% endif %}
        {% if hero.categories.size > 0 %}<span class="badge text-bg-light">{{ hero.categories | first }}</span>{% endif %}
      </div>
      <a href="{{ hero.url | relative_url }}" class="btn btn-light btn-lg align-self-start">
        Read the full story <i class="bi bi-arrow-right ms-2"></i>
      </a>
    </div>
    <div class="col-lg-5 d-none d-lg-block position-relative">
      <img src="{{ site.og_image | relative_url }}" alt="{{ hero.title }}" class="w-100 h-100" style="object-fit: cover; min-height: 360px;">
    </div>
  </div>
</section>
{% endif %}

<!-- ============================= SECTION NAVIGATION ============================= -->
<section class="mb-5">
  <div class="row row-cols-2 row-cols-md-3 row-cols-lg-5 g-3">
    {%- assign nav_sections = "hacks,tools,posts,docs,about" | split: "," -%}
    {% for coll in nav_sections %}
      {%- case coll -%}
        {%- when 'hacks' -%}{%- assign n_label='Hacks' -%}{%- assign n_icon='bi-lightbulb' -%}{%- assign n_url='/hacks/' -%}
        {%- when 'tools' -%}{%- assign n_label='Tools' -%}{%- assign n_icon='bi-wrench-adjustable' -%}{%- assign n_url='/tools/' -%}
        {%- when 'posts' -%}{%- assign n_label='Field Notes' -%}{%- assign n_icon='bi-journal-text' -%}{%- assign n_url='/blog/' -%}
        {%- when 'docs'  -%}{%- assign n_label='Docs' -%}{%- assign n_icon='bi-robot' -%}{%- assign n_url='/docs/' -%}
        {%- when 'about' -%}{%- assign n_label='About' -%}{%- assign n_icon='bi-info-circle' -%}{%- assign n_url='/about/' -%}
      {%- endcase -%}
      {%- assign n_count = site[coll] | size -%}
      <div class="col">
        <a href="{{ n_url | relative_url }}" class="card text-center h-100 text-decoration-none border-0 shadow-sm hover-lift">
          <div class="card-body py-4">
            <i class="bi {{ n_icon }} fs-2 text-primary mb-2 d-block"></i>
            <h2 class="h6 card-title mb-1">{{ n_label }}</h2>
            <small class="text-body-secondary">{{ n_count }} article{% if n_count != 1 %}s{% endif %}</small>
          </div>
        </a>
      </div>
    {% endfor %}
  </div>
</section>

<!-- ============================= FEATURED STORIES ============================= -->
{% if main_featured %}
<section class="mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h2 class="h3 mb-0"><i class="bi bi-star-fill text-warning me-2"></i>Featured</h2>
  </div>
  <div class="row g-4">
    <!-- Main featured -->
    <div class="col-lg-6">
      <div class="card h-100 border-0 shadow hover-lift overflow-hidden">
        {% include home/cover.html collection=main_featured.collection height='300px' preview=main_featured.preview alt=main_featured.title %}
        <div class="card-body">
          <span class="badge text-bg-warning mb-2"><i class="bi bi-star-fill me-1"></i>Editor's pick</span>
          <h3 class="h4 card-title">
            <a href="{{ main_featured.url | relative_url }}" class="text-decoration-none text-body-emphasis stretched-link">{{ main_featured.title }}</a>
          </h3>
          <p class="card-text text-body-secondary">{{ main_featured.excerpt | default: main_featured.description | strip_html | truncate: 150 }}</p>
        </div>
        <div class="card-footer bg-transparent border-0 text-body-secondary small">
          <i class="bi bi-calendar3 me-1"></i>{{ main_featured.date | date: "%b %-d, %Y" }}
        </div>
      </div>
    </div>
    <!-- Secondary featured -->
    <div class="col-lg-6">
      <div class="row row-cols-1 row-cols-md-2 g-4">
        {% for fp in secondary limit: 4 %}
          <div class="col">{% include home/card.html item=fp cover_height='120px' %}</div>
        {% endfor %}
      </div>
    </div>
  </div>
</section>
{% endif %}

<!-- ============================= POSTS BY SECTION ============================= -->
{%- assign feed_sections = "hacks,tools,posts" | split: "," -%}
{% for coll in feed_sections %}
  {%- case coll -%}
    {%- when 'hacks' -%}{%- assign s_label='Hacks' -%}{%- assign s_icon='bi-lightbulb' -%}{%- assign s_url='/hacks/' -%}{%- assign s_color='text-primary' -%}
    {%- when 'tools' -%}{%- assign s_label='Tools' -%}{%- assign s_icon='bi-wrench-adjustable' -%}{%- assign s_url='/tools/' -%}{%- assign s_color='text-info' -%}
    {%- when 'posts' -%}{%- assign s_label='Field Notes' -%}{%- assign s_icon='bi-journal-text' -%}{%- assign s_url='/blog/' -%}{%- assign s_color='text-success' -%}
  {%- endcase -%}
  {%- assign s_items = site[coll] | sort: 'date' | reverse -%}
  {% if s_items.size > 0 %}
  <section class="mb-5 pb-4 border-bottom">
    <div class="d-flex justify-content-between align-items-center mb-4">
      <h2 class="h4 mb-0"><i class="bi {{ s_icon }} {{ s_color }} me-2"></i>{{ s_label }}</h2>
      <a href="{{ s_url | relative_url }}" class="btn btn-outline-secondary btn-sm">View all {{ s_label }} <i class="bi bi-arrow-right ms-1"></i></a>
    </div>
    <div class="row row-cols-1 row-cols-sm-2 row-cols-lg-4 g-4">
      {% for it in s_items limit: 4 %}
        <div class="col">{% include home/card.html item=it cover_height='150px' %}</div>
      {% endfor %}
    </div>
  </section>
  {% endif %}
{% endfor %}

<!-- ============================= LATEST ============================= -->
<section class="mb-5">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h2 class="h4 mb-0"><i class="bi bi-clock-history text-secondary me-2"></i>Latest</h2>
  </div>
  <div class="row g-4">
    {% for it in all_items limit: 6 %}
      {%- case it.collection -%}
        {%- when 'hacks' -%}{%- assign l_label='Hack' -%}{%- assign l_badge='text-bg-primary' -%}
        {%- when 'tools' -%}{%- assign l_label='Tool' -%}{%- assign l_badge='text-bg-info' -%}
        {%- when 'posts' -%}{%- assign l_label='Field Note' -%}{%- assign l_badge='text-bg-success' -%}
        {%- else -%}{%- assign l_label=it.collection | capitalize -%}{%- assign l_badge='text-bg-secondary' -%}
      {%- endcase -%}
      <div class="col-md-6 col-lg-4">
        <div class="card border-0 shadow-sm h-100 hover-lift overflow-hidden">
          <div class="row g-0 h-100">
            <div class="col-4">{% include home/cover.html collection=it.collection height='110px' class='h-100' %}</div>
            <div class="col-8">
              <div class="card-body py-2 px-3">
                <span class="badge {{ l_badge }} mb-1">{{ l_label }}</span>
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

<!-- ============================= TAGS & ARCHIVES ============================= -->
<section class="mb-5">
  <div class="row g-4">
    <div class="col-md-6">
      <div class="card h-100 border-0 bg-body-tertiary">
        <div class="card-body">
          <h2 class="h5 card-title mb-3"><i class="bi bi-tags me-2"></i>Popular Tags</h2>
          {%- assign all_tags = "" | split: "" -%}
          {%- for it in all_items -%}{%- for tag in it.tags -%}{%- assign all_tags = all_tags | push: tag -%}{%- endfor -%}{%- endfor -%}
          {%- assign unique_tags = all_tags | uniq | slice: 0, 15 -%}
          <div class="d-flex flex-wrap gap-2">
            {% for tag in unique_tags %}
              <a href="{{ '/tags/' | relative_url }}#{{ tag | slugify }}" class="badge text-bg-secondary text-decoration-none fs-6">{{ tag }}</a>
            {% endfor %}
          </div>
          <a href="{{ '/tags/' | relative_url }}" class="btn btn-sm btn-outline-primary mt-3">Browse all tags <i class="bi bi-arrow-right ms-1"></i></a>
        </div>
      </div>
    </div>
    <div class="col-md-6">
      <div class="card h-100 border-0 bg-body-tertiary">
        <div class="card-body">
          <h2 class="h5 card-title mb-3"><i class="bi bi-archive me-2"></i>Archive</h2>
          {%- assign by_year = all_items | group_by_exp: "it", "it.date | date: '%Y'" -%}
          <div class="row">
            {% for year in by_year limit: 2 %}
              <div class="col-6">
                <h3 class="h6 text-body-secondary mb-2">{{ year.name }}</h3>
                {%- assign months = year.items | group_by_exp: "it", "it.date | date: '%B'" -%}
                <ul class="list-unstyled small mb-0">
                  {% for month in months limit: 6 %}
                    <li class="mb-1">
                      <a href="{{ '/sitemap/' | relative_url }}" class="text-decoration-none">
                        {{ month.name }} <span class="badge text-bg-secondary">{{ month.items.size }}</span>
                      </a>
                    </li>
                  {% endfor %}
                </ul>
              </div>
            {% endfor %}
          </div>
          <a href="{{ '/sitemap/' | relative_url }}" class="btn btn-sm btn-outline-primary mt-3">Browse the archive <i class="bi bi-arrow-right ms-1"></i></a>
        </div>
      </div>
    </div>
  </div>
</section>

<!-- ============================= SUBSCRIBE CTA ============================= -->
<section class="mb-4">
  <div class="card border-0 bg-primary bg-gradient text-white">
    <div class="card-body p-4 p-lg-5 text-center">
      <i class="bi bi-robot fs-1 mb-3 d-block"></i>
      <h2 class="h3 mb-3">New dispatches appear here because a robot put them here.</h2>
      <p class="mb-4 opacity-75 mx-auto" style="max-width: 36rem;">No newsletter, no funnel, no "10x your life" emails. Subscribe by RSS, or watch the robot work in the open on GitHub.</p>
      <div class="d-flex flex-wrap gap-2 justify-content-center">
        <a href="{{ '/feed.xml' | relative_url }}" class="btn btn-light btn-lg"><i class="bi bi-rss me-2"></i>Subscribe via RSS</a>
        <a href="https://github.com/{{ site.repository | join: '' }}" class="btn btn-outline-light btn-lg"><i class="bi bi-github me-2"></i>Watch on GitHub</a>
        <a href="{{ '/about/colophon/' | relative_url }}" class="btn btn-outline-light btn-lg"><i class="bi bi-stars me-2"></i>Meet the robot</a>
      </div>
    </div>
  </div>
</section>

<style>
.news-cover i { font-size: 2.4rem; color: rgba(255, 255, 255, 0.85); } .hover-lift { transition: transform 0.2s ease-in-out, box-shadow 0.2s ease-in-out; } .hover-lift:hover { transform: translateY(-4px); box-shadow: 0 0.5rem 1rem rgba(0, 0, 0, 0.15) !important; }
</style>
