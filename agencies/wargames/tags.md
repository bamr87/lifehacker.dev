---
title: All levels
description: Every level of every wargame on one page, grouped by difficulty, with links straight to each level.
permalink: /tags/
author: bamr87
layout: default
sidebar: false
sitemap: true
---

<div class="wg-all">
{% assign wg_tiers = "beginner|intermediate|advanced|archive" | split: "|" %}
{% for tier in wg_tiers %}
{% assign wg_games = site.data.games[tier] %}
<div class="wg-tier"><h2>{{ tier | capitalize }}</h2></div>
{% for game in wg_games %}
{% assign wg_levels = site.pages | where_exp: "p", "p.url contains game.url" | where_exp: "p", "p.nav_order != nil" | sort: "nav_order" %}
<section class="wg-all-game">
<h3><i class="bi {{ game.icon }}" aria-hidden="true"></i> <a href="{{ game.url | relative_url }}">{{ game.title }}</a> <small>{{ game.description }}</small></h3>
{% if wg_levels.size > 0 %}
<ul class="wg-pills">
{% for p in wg_levels %}
<li><a href="{{ p.url | relative_url }}" title="{{ p.title | escape }}">{% if p.nav_order >= 0 %}{{ p.nav_order }}{% else %}{{ p.sidebar_label }}{% endif %}</a></li>
{% endfor %}
</ul>
{% endif %}
</section>
{% endfor %}
{% endfor %}
</div>
