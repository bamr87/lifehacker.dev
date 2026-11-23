---
title: "Natas Level 12"
description: "Natas Level 12 — upload a file the server stores and then serves; learn why trusting the client's filename and file type lets attackers run their own code."
excerpt: "Natas Level 12 — upload a file the server stores and then serves; learn why trusting the client's filename and file type lets attackers run their own code."
permalink: /docs/wargames/natas/natas12/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/natas/natas12.md
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
nav_order: 12
sidebar_label: "Level 12"
---
> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

    Username: natas12
    URL:      http://natas12.natas.labs.overthewire.org

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** sign in as `natas12` and find the password for `natas13`.
</div>

### What this level teaches

How an unrestricted file upload can turn into remote code execution.

### Key ideas

- **Uploads become files on the server.** If they land in a folder the web server executes, the file can run as a script.
- **Never trust the client.** The filename and extension arrive from the browser, and even hidden form fields can be edited.
- **Execution depends on extension.** The web server decides whether to run or merely serve a file by its name.
- **What to run.** A tiny server-side script that reads the password file is enough.

### How to approach it

1. Upload a harmless file, then find where it is stored and what name it was given.
2. Inspect the form and the code to see which part of the name the server chooses and which part you do.
3. Request the uploaded file from the browser to see what happens.

### How developers prevent it

Store uploads outside the web root, generate the filename yourself, validate the file's true type, and serve uploads from a domain that never executes code.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../natas11/">Level 11</a><a class="sg-index" href="../">Natas overview</a><a class="sg-next" href="../natas13/">Level 13</a></nav>

</section>

<!-- study-guide:end -->
