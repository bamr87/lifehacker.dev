---
title: "Bandit Level 28"
description: "Bandit Level 28 — clone a Git repository over SSH from your own machine and read its files."
permalink: /docs/wargames/bandit/bandit28/
date: '2026-04-07T01:41:08.000Z'
lastmod: '2026-04-07T01:41:08.000Z'
categories:
- wargames
- bandit
tags:
- security
- wargames
- linux
- ctf
- cybersecurity
toc_sticky: true
source_repo: https://github.com/OverTheWireOrg/OverTheWire-website
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit28.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 28 — clone a Git repository over SSH from your own machine and read its files."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 28
sidebar_label: "Level 28"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
There is a git repository at `ssh://bandit27-git@bandit.labs.overthewire.org/home/bandit27-git/repo` via the port `2220`. The password for the user `bandit27-git` is the same as for the user `bandit27`.

From your local machine (not the OverTheWire machine!), clone the repository and find the password for the next level. This needs git installed locally on your machine.


Commands you may need to solve this level
-----------------------------------------
git

Helpful Reading Material
------------------------
- [Installing Git][]
- [Git from the Bottom Up][]

[Installing Git]: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git
[Git from the Bottom Up]: https://jwiegley.github.io/git-from-the-bottom-up/

<!-- study-guide:start -->

<section class="study-guide" markdown="1">

## Study guide

<div class="sg-map" markdown="1">
**Level map:** using the password for `bandit27`, find the password for `bandit28`.
</div>

### What this level teaches

The basic Git workflow: cloning a remote repository over SSH.

### Key ideas

- **Repository.** A folder whose history of changes is stored in a hidden `.git` directory.
- **`git clone URL`** copies the repository to your machine. SSH URLs have the form `ssh://user@host:PORT/path`; note that the port goes in the URL.
- **Work locally.** The Level Goal asks you to do this on your own machine, so install Git there first.

### How to approach it

1. Clone using the URL given, supplying the password when asked.
2. Read the files in the working tree, starting with a README if present.

### Why it matters

Git is the foundation of modern software development, and every remaining Bandit level is a lesson in how it stores history.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit27/">Level 27</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit29/">Level 29</a></nav>

</section>

<!-- study-guide:end -->
