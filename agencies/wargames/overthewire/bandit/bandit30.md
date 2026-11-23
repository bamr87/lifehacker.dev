---
title: "Bandit Level 30"
description: "Bandit Level 30 — discover that the interesting commit lives on a branch other than the one you cloned."
permalink: /docs/wargames/bandit/bandit30/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit30.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 30 — discover that the interesting commit lives on a branch other than the one you cloned."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 30
sidebar_label: "Level 30"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
There is a git repository at `ssh://bandit29-git@bandit.labs.overthewire.org/home/bandit29-git/repo` via the port `2220`. The password for the user `bandit29-git` is the same as for the user `bandit29`.

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
**Level map:** using the password for `bandit29`, find the password for `bandit30`.
</div>

### What this level teaches

Git branches, and how to see work that is not on the default branch.

### Key ideas

- **Branches** are named, movable pointers to lines of development. A clone checks out only the default branch at first.
- **Remote branches.** `git branch -a` lists local and remote branches; `git checkout` switches to one.
- **Log per branch.** `git log` shows only the history reachable from the branch you are on.

### How to approach it

1. After cloning, read the files and log, then ask what else could exist.
2. List all branches, including remote ones, and look through each.
3. Read files in any branch that looks like a work in progress.

### Why it matters

Development, feature and release branches often hold unreleased code or leftover secrets, and reviewers must check them all.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit29/">Level 29</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit31/">Level 31</a></nav>

</section>

<!-- study-guide:end -->
