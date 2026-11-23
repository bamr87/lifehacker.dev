---
title: Wargames — Security Challenges
description: "Learn Linux, web security, cryptography and binary exploitation by playing OverTheWire wargames, with a spoiler-free study guide on every page."
layout: home
hide_title: true
rss_subscribe: false
permalink: /
date: '2025-01-27T00:00:00.000Z'
lastmod: '2026-04-07T02:46:45.000Z'
categories:
- wargames
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_name: overthewire
license: MIT
author: bamr87
excerpt: Security wargame challenges to practice Linux, CTF, and cybersecurity skills.
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
---

<section class="wg-hero">
<div class="container-xl wg-hero-inner">
<p class="wg-eyebrow">OverTheWire · study edition</p>
<h1 class="wg-title">Learn Linux and security by playing wargames</h1>
<p class="wg-lead">Hands-on challenges that teach the command line, web security, cryptography and binary exploitation, one level at a time. Every page comes with a spoiler-free study guide that explains the ideas without giving away the answers.</p>
<div class="wg-cta">
<a class="btn btn-primary btn-lg" href="{{ '/docs/wargames/bandit/' | relative_url }}"><i class="bi bi-terminal me-2" aria-hidden="true"></i>Start with Bandit</a>
<a class="btn btn-outline-light btn-lg" href="{{ '/docs/wargames/' | relative_url }}">How wargames work</a>
</div>
<p class="wg-terminal"><span class="wg-prompt">$</span> ssh bandit0@bandit.labs.overthewire.org -p 2220</p>
<ul class="wg-stats">
<li><strong>18</strong> wargames</li>
<li><strong>~200</strong> levels</li>
<li><strong>219</strong> study guides</li>
<li><strong>0</strong> spoilers</li>
</ul>
</div>
</section>

<div class="container-xl wg-section">
<h2>How it works</h2>
<p class="wg-sub">Wargames are security challenges played as a game. Each level hides a password; finding it teaches a skill, and the password unlocks the next level.</p>
<div class="row g-3">
<div class="col-md-4"><div class="wg-tile"><i class="bi bi-terminal" aria-hidden="true"></i><h3>Play for real</h3><p>Connect over SSH, or in your browser for Natas, to real, intentionally vulnerable servers run by the OverTheWire community.</p></div></div>
<div class="col-md-4"><div class="wg-tile"><i class="bi bi-mortarboard" aria-hidden="true"></i><h3>Study without spoilers</h3><p>Every page ends with a study guide: the concepts behind the level, a hint-level approach, and why the skill matters in real work.</p></div></div>
<div class="col-md-4"><div class="wg-tile"><i class="bi bi-signpost-split" aria-hidden="true"></i><h3>Follow a path</h3><p>Games are grouped by difficulty and ordered so that each one prepares you for the next. Start with the first.</p></div></div>
</div>
</div>

<div class="container-xl wg-section">
<h2>A suggested path</h2>
<p class="wg-sub">This is the order the OverTheWire maintainers suggest. Skipping ahead is fine, but Bandit's skills are assumed everywhere.</p>
<ol class="wg-path">
<li><strong>Bandit</strong><span>Linux command line and SSH. Do this first.</span></li>
<li><strong>Natas, Krypton or Leviathan</strong><span>Pick one by interest: web, cryptography or reverse engineering.</span></li>
<li><strong>Narnia, then Behemoth</strong><span>Binary exploitation, first with the source code and then without.</span></li>
<li><strong>Utumno, Maze and beyond</strong><span>Harder binaries, code auditing and mixed advanced topics.</span></li>
</ol>
</div>

<div class="container-xl wg-section">
<h2>The games</h2>
<p class="wg-sub">Open any game for its overview, prerequisites and a level-by-level roadmap. The sidebar on every page lists its levels, or <a href="{{ '/tags/' | relative_url }}">browse every level on one page</a>.</p>
<div class="wg-tier"><h3>Beginner</h3><small>Start here</small></div>
{% include components/card-grid.html items=site.data.games.beginner columns="row-cols-1 row-cols-md-2 row-cols-xl-4" heading_level="h4" aria_label="Beginner wargames" %}
<div class="wg-tier"><h3>Intermediate</h3><small>Binary exploitation begins</small></div>
{% include components/card-grid.html items=site.data.games.intermediate columns="row-cols-1 row-cols-md-2 row-cols-xl-3" heading_level="h4" aria_label="Intermediate wargames" %}
<div class="wg-tier"><h3>Advanced</h3><small>Bring a debugger</small></div>
{% include components/card-grid.html items=site.data.games.advanced columns="row-cols-1 row-cols-md-2 row-cols-xl-3" heading_level="h4" aria_label="Advanced wargames" %}
<div class="wg-tier"><h3>Archive and downloads</h3><small>Offline games and conference virtual machines</small></div>
{% include components/card-grid.html items=site.data.games.archive columns="row-cols-1 row-cols-md-2 row-cols-xl-3" heading_level="h4" aria_label="Archived and downloadable wargames" %}
</div>

<div class="container-xl wg-section">
{%- capture wg_rules -%}
<ul class="mb-0"><li>Only attack the wargame servers and the accounts the games provide. Never use these techniques on systems you do not own or have written permission to test.</li><li>Do not disrupt other players, and clean up after yourself in <code>/tmp</code>.</li><li>Do not publish passwords or step-by-step solutions. Write about the concepts instead.</li></ul>
{%- endcapture -%}
{% include components/callout.html type="warning" title="Ground rules" content=wg_rules %}
<p class="wg-about">The challenge pages are a mirror of the <a href="https://overthewire.org/wargames/">OverTheWire</a> wargames, aggregated from the <a href="https://github.com/OverTheWireOrg/OverTheWire-website">OverTheWire-website repository</a> under the <a href="https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE">MIT License</a>. Visit the original site to play the games live. The <strong>Study guide</strong> section at the end of each page is this site's own addition, between <code>study-guide</code> marker comments, and is kept apart from the upstream text. To refresh the upstream content, see the <a href="https://github.com/bamr87/wargames/blob/main/scripts/docs-aggregator/README.md">aggregator documentation</a>.</p>
</div>
