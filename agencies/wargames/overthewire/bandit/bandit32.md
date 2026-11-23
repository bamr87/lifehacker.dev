---
title: "Bandit Level 32"
description: "Bandit Level 32 — push a commit to a Git remote and defeat a .gitignore rule that stops your file from being added."
permalink: /docs/wargames/bandit/bandit32/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit32.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 32 — push a commit to a Git remote and defeat a .gitignore rule that stops your file from being added."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 32
sidebar_label: "Level 32"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
There is a git repository at `ssh://bandit31-git@bandit.labs.overthewire.org/home/bandit31-git/repo` via the port `2220`. The password for the user `bandit31-git` is the same as for the user `bandit31`.

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
**Level map:** using the password for `bandit31`, find the password for `bandit32`.
</div>

### What this level teaches

Pushing to a remote, and how ignore rules and server-side hooks work.

### Key ideas

- **The three areas.** Working tree, staging area (`git add`) and repository (`git commit`) are separate; `git push` then sends commits to the remote.
- **`.gitignore`.** A list of patterns Git deliberately skips. If a file you need to add matches a pattern, Git silently refuses unless you force it.
- **Server hooks.** A remote can run a script when it receives a push and send messages back to you. Read the output of `git push` carefully.
- **Read the README.** It states exactly what the remote expects.

### How to approach it

1. Clone, then read the README to learn what file and content the server wants.
2. Create it, try to add and commit it, and diagnose why Git skips it.
3. Push and read what the server prints back.

### Why it matters

Hooks drive continuous integration, deployments and policy checks, and understanding what `git add` actually does stops "my change disappeared" confusion.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit31/">Level 31</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit33/">Level 33</a></nav>

</section>

<!-- study-guide:end -->
