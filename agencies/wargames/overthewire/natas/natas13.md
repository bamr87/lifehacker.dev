---
title: "Natas Level 13"
description: "Natas Level 13 — the server now checks that an upload looks like an image; learn what file signatures are and why checking them is not enough."
excerpt: "Natas Level 13 — the server now checks that an upload looks like an image; learn what file signatures are and why checking them is not enough."
permalink: /docs/wargames/natas/natas13/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas13.md
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
nav_order: 13
sidebar_label: "Level 13"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas13
    URL:      http://natas13.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas13` and find the password for `natas14`.
</div>

### What this level teaches

That validating the first few bytes of a file does not make the whole file safe.

### Key ideas

- **Magic bytes.** Image formats start with fixed bytes that identify them. Functions such as PHP's `exif_imagetype` look only at those.
- **Polyglot files.** A file can satisfy two formats at once, for example start like an image and contain a script after it.
- **Same weakness, new gate.** The execution risk from the previous level is unchanged; only the filter is different.

### How to approach it

1. Read the new check and work out exactly what it examines.
2. Build a file that passes that check while still containing your payload.
3. Use `xxd` or a hex editor to see your file the way the server does.

### How developers prevent it

Re-encode images with an image library (which discards extra content), store them outside the web root, and never rely on a header check alone.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas12/">Level 12</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas14/">Level 14</a></nav>

</section>

<!-- study-guide:end -->
