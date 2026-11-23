---
title: "Leviathan Level 0"
description: "Leviathan Level 0 — explore your starting home directory for something that does not show up in an ordinary listing."
excerpt: "Leviathan Level 0 — explore your starting home directory for something that does not show up in an ordinary listing."
permalink: /docs/wargames/leviathan/leviathan0/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- leviathan
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/leviathan/leviathan0.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- leviathan
author: bamr87
nav_order: 0
sidebar_label: "Level 0"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

There is no information for this level, intentionally.

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** logged in as `leviathan0`, find the password for `leviathan1`.
</div>

### What this level teaches

Careful reconnaissance: always look for what a default view hides.

### Key ideas

- **Hidden entries.** Files and directories starting with a dot are skipped by a plain `ls`. `ls -la` shows them.
- **Recognising what you find.** A backup of an ordinary application file may hold data you would not expect to find on a server.
- **Searching, not scrolling.** If a file is large, `grep` for a likely word instead of reading it all.

### How to approach it

1. Log in with the credentials on the index page and list your home directory with all entries.
2. Look inside anything unusual and search it for the word you need.

### Why it matters

Backups, old exports and leftovers regularly leak data in real incidents.

<nav class="sg-nav" aria-label="Level navigation"><span></span><a class="sg-index" href="../">Leviathan overview</a><a class="sg-next" href="../leviathan1/">Level 1</a></nav>

</section>

<!-- study-guide:end -->
