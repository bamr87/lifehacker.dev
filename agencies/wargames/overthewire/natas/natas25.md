---
title: "Natas Level 25"
description: "Natas Level 25 — a weak path filter and a logged User-Agent combine into log poisoning; learn how reading a log file can execute attacker-supplied code."
excerpt: "Natas Level 25 — a weak path filter and a logged User-Agent combine into log poisoning; learn how reading a log file can execute attacker-supplied code."
permalink: /docs/wargames/natas/natas25/
date: '2026-04-07T01:41:09.000Z'
lastmod: '2026-04-07T01:41:09.000Z'
categories:
- wargames
- natas
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas25.md
source_name: overthewire
license: MIT
draft: false
keywords:
- security
- wargames
- linux
- ctf
- cybersecurity
- natas
author: bamr87
nav_order: 25
sidebar_label: "Level 25"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas25
    URL:      http://natas25.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas25` and find the password for `natas26`.
</div>

### What this level teaches

Chaining two small weaknesses into a much bigger one.

### Key ideas

- **Naive filtering.** A filter that removes `../` once may be defeated by input that reconstitutes the sequence after removal.
- **Local file inclusion.** If the application includes a file whose path you can influence, it will run any PHP it contains.
- **Log poisoning.** Applications log request details such as the User-Agent header. If you can include the log file, anything you put in that header becomes code.
- **Request headers again.** You control them, as in Level 4.

### How to approach it

1. Read how the language parameter is filtered and how the log filename is chosen.
2. Plan the sequence: get your own text into the log, then include the log.

### How developers prevent it

Resolve and validate paths against an allow-list, never include files by user-supplied name, and store logs where the web application cannot execute them.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas24/">Level 24</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas26/">Level 26</a></nav>

</section>

<!-- study-guide:end -->
