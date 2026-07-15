---
title: "Eight rounds with Copilot to make one Liquid folder tree stop repeating itself"
description: "A Jekyll sidebar that listed every parent folder once per file. The fix is one Liquid filter and a mental model the assistant kept missing across eight tries."
preview: /images/previews/eight-rounds-with-copilot-to-make-one-liquid-folde.png
date: 2024-05-16
categories: [Field Notes]
tags: [jekyll, liquid, copilot, sidebar, debugging]
author: amr
excerpt: "I wanted a folder tree. I got the same folder name printed once per file, eight times, with apologies."
---

I wanted a sidebar that showed a collection's folders as a tree: each folder once, then the files inside it. A normal thing to want. What I got, for the better part of an afternoon, was every parent folder printed once *per file*, accompanied by an AI assistant apologizing and then handing me the same shape of bug in a slightly different shirt.

This is the log of that afternoon. The useful part — the actual fix — is at the bottom. The eight rounds in the middle are the lesson, and I'm leaving them in.

## The thing I was building

Jekyll exposes a collection's documents as `site.collections | where: "label", page.collection`. Each doc has a `.path` like `_notes/git/rebase.md`. I wanted to walk those paths and render a nested list: a `<li class="folder">` per directory, a `<li class="file">` per document, no repeats.

Sounds like a `for` loop. It is. That's the trap.

## Round 1: "it already works" (it did not)

First suggestion split each `doc.path` on `/` and printed every segment as a folder:

```liquid
{% raw %}{% for doc in docs %}
  {% assign folders = doc.path | split: '/' %}
  {% for folder in folders %}
    <li class="folder">{{ folder }}</li>
  {% endfor %}
  <li class="file">{{ doc.title }}</li>
{% endfor %}{% endraw %}
```

For five files in `_notes/git/`, this prints `_notes` five times and `git` five times. The folder names repeat once for every file under them. That's the entire bug, stated early, and we spent seven more rounds rediscovering it.

You'll know you've hit it when the sidebar reads like a stutter: `_notes / git / rebase / _notes / git / bisect / _notes / git / ...`.

## Rounds 2–6: the wandering variable

The next several attempts all chased the same idea — track the path you've already printed, only print when it changes — and kept putting the bookkeeping variable in the wrong scope. The pattern, every time:

- **Round 2:** track `current_path`, reset it inside the doc loop. Folders still repeat, because it resets per document.
- **Round 3:** move `current_path` outside the doc loop. Now the root folder repeats instead.
- **Round 4:** skip the first path segment with `forloop.index != 1`. Now the *sub*-folders repeat.
- **Round 5:** add `{% raw %}{% if forloop.last %}</ul>{% endif %}{% endraw %}` to close tags. Still repeating.
- **Round 6:** "I apologize for the confusion earlier" — then the identical fix from round 3, pasted again.

Round 6 is where I learned the tell for a stuck assistant: it apologizes, restates your symptom back to you as the diagnosis, and ships code that is byte-for-byte something it already tried. Two consecutive replies were the same block. The model had run out of new ideas and was looping; I hadn't noticed I was the one in the loop with it.

The honest read: the inner `for folder in folders` loop was always the problem. You cannot dedupe a *folder* by comparing inside a loop that visits one *segment* at a time, because the comparison state belongs to the document, not the segment.

## Round 7: the filter that fixed it

The thing that finally worked dropped the segment-by-segment loop entirely. Instead of building the path up piece by piece, take the document's path, split it, and `pop` off the filename. What's left is the parent directory — one value per document. Compare *that* to the previous one:

```liquid
{% raw %}{% assign docs = root_folder.docs | sort: 'path' %}
{% assign prev_path = "" %}
<ul>
{% for doc in docs %}
  {% assign current_path = doc.path | split: '/' | pop %}
  {% if current_path != prev_path %}
    {% for folder in current_path %}
      {% if forloop.index != 1 %}
        <li class="folder">{{ folder }}</li>
      {% endif %}
    {% endfor %}
    {% assign prev_path = current_path %}
  {% endif %}
  <li class="file"><a href="{{ doc.url }}">{{ doc.title }}</a></li>
{% endfor %}
</ul>{% endraw %}
```

Two things carry the whole fix:

1. **`sort: 'path'`** — so every file in a folder is adjacent. Dedup-on-change only works if duplicates are neighbors.
2. **`| pop`** — Liquid's `pop` returns the array without its last element. On `_notes/git/rebase.md` split into `["_notes","git","rebase.md"]`, `pop` gives `["_notes","git"]`: the folder, no filename. That's the value you compare.

The `forloop.index != 1` skips the collection root (`_notes`) so it isn't rendered as a folder header.

You'll know it worked when each folder name appears exactly once and the files sit under it — no stutter.

## Why this was always the answer

You don't need Liquid to see why round 7 works and rounds 1–6 didn't. The shape is identical to a Unix one-liner, and that one I *can* run here. Sort the paths, strip the filename to get the parent, print the folder only when it changes:

```bash
# lh:run
cd "$(mktemp -d)"
mkdir -p _notes/git _notes/shell/zsh
: > _notes/intro.md
: > _notes/git/rebase.md
: > _notes/git/bisect.md
: > _notes/shell/aliases.md
: > _notes/shell/zsh/prompt.md

prev=""
find _notes -name '*.md' | sort | while read -r p; do
  dir=$(dirname "$p")              # like split:'/' | pop — drop the filename
  if [ "$dir" != "$prev" ]; then   # only emit the folder when it CHANGES
    echo "FOLDER: $dir"
    prev="$dir"
  fi
  echo "  file: $(basename "$p")"
done
```

Real output from running that block:

```text
FOLDER: _notes/git
  file: bisect.md
  file: rebase.md
FOLDER: _notes
  file: intro.md
FOLDER: _notes/shell
  file: aliases.md
FOLDER: _notes/shell/zsh
  file: prompt.md
```

`dirname` is `split: '/' | pop`. The `prev` check is `current_path != prev_path`. The `sort` is `sort: 'path'`. Round 7 is this script wearing a `{% raw %}{% %}{% endraw %}` costume. Every earlier round tried to do the deduping *inside* the per-segment loop, which is like running the `if "$dir" != "$prev"` check once per path component instead of once per file — guaranteed to misfire.

(One quirk the shell hides and Liquid doesn't: `sort` puts `_notes/git` before `_notes`, because `_notes/g` sorts before `_notes` plus a newline. The output above shows it. In a real sidebar you'd want the parent before its children, which means sorting on depth too — but that's a second post, and the dedup logic is the same either way.)

## What the afternoon actually taught me

The fix was one filter. The detour was six rounds of putting a counter in the wrong loop, with an assistant that confidently narrated each wrong scope as the solution. It wasn't wrong because it was a robot; it was wrong the way I'd have been wrong solo, only faster and with better grammar.

The move that broke the loop wasn't a better prompt. It was stepping back from "track the path as I build it up" to "the parent folder is the path minus the filename" — a reframing the segment-by-segment loop structurally couldn't reach. When an assistant pastes the same block twice, that's your cue to stop refining and change the data model, not the code.

The part where it broke is the part worth keeping. The repeating-folder bug is what a `for` loop does when you ask it to remember something across iterations and then reset the memory every iteration. Sort, strip the filename, compare to the last one. Once you see it as the `dirname`/`sort`/`uniq` it always was, there's nothing left to apologize for.
