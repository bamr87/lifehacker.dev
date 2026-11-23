---
title: "Bandit Level 31"
description: "Bandit Level 31 — find a secret stored in a Git tag rather than in any file or branch."
permalink: /docs/wargames/bandit/bandit31/
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
source_url: https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/bandit/bandit31.md
source_name: overthewire
license: MIT
author: bamr87
excerpt: "Bandit Level 31 — find a secret stored in a Git tag rather than in any file or branch."
draft: false
keywords:
- security
- wargames
- linux
- overthewire
- ctf
- cybersecurity
nav_order: 31
sidebar_label: "Level 31"
---

> **Source:** This content is aggregated from [overthewire](https://github.com/OverTheWireOrg/OverTheWire-website) ([MIT](https://github.com/OverTheWireOrg/OverTheWire-website/blob/gh-pages/LICENSE)). Visit the original repository for the latest version.

Level Goal
----------
There is a git repository at `ssh://bandit30-git@bandit.labs.overthewire.org/home/bandit30-git/repo` via the port `2220`. The password for the user `bandit30-git` is the same as for the user `bandit30`.

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
**Level map:** using the password for `bandit30`, find the password for `bandit31`.
</div>

### What this level teaches

That Git stores more than files and branches, including tags and other references.

### Key ideas

- **Tags** are permanent labels on a specific commit, usually marking releases such as `v1.0`.
- **Annotated tags** can carry a message of their own.
- **`git tag`** lists them and `git show TAG` displays what each points to.
- **Searching a repo.** When files and logs reveal nothing, enumerate every kind of reference Git keeps.

### How to approach it

1. Clone the repository and check the visible files and log.
2. List the tags in the repository and inspect them.

### Why it matters

Secrets can hide in the less obvious corners of a repository, which is why secret-scanning tools search all references, not just the latest files.

<nav class="sg-nav" aria-label="Level navigation"><a class="sg-prev" href="../bandit30/">Level 30</a><a class="sg-index" href="../">Bandit overview</a><a class="sg-next" href="../bandit32/">Level 32</a></nav>

</section>

<!-- study-guide:end -->
