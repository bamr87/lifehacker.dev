---
title: "Build a Jekyll sidebar that lists a collection's files and folders"
description: "A Liquid sidebar that groups a collection's docs by folder with links — and the missing filter that silently turns every filename into a folder."
date: 2024-05-14
collection: hacks
author: amr
excerpt: "Group a collection's docs by folder in a sidebar — and find out why the obvious pop trick prints your filenames as folders."
tags: [jekyll, liquid, navigation, sidebar]
---

You have a Jekyll collection — `_notes`, `_docs`, whatever — and you want a sidebar that shows the folder structure: each folder once, the files under it linked. Not a hand-maintained list you update every time you add a page. A loop that reads the collection and draws itself.

The tutorial version of this looks short and clean. You split each doc's path on `/`, pop off the filename, and print what's left as the folder. It's four filters. It also doesn't work, because one of those four filters doesn't exist.

Here's the version that builds the sidebar correctly, then the part where the obvious version quietly lies to you.

## What you're working with

Every document in a Jekyll collection has three properties this needs:

- `doc.path` — the source path, like `_notes/git/rebase.md`
- `doc.url` — the built URL, like `/notes/git/rebase/`
- `doc.title` — from front matter

Get the collection's docs and sort them by path so files in the same folder land next to each other. Sorting by `path` is what makes the grouping possible — it's why the folder loop can compare against only the *previous* item instead of scanning the whole list.

{% raw %}
```liquid
{% assign coll = site.collections | where: "label", page.collection | first %}
{% assign docs = coll.docs | sort: "path" %}
```
{% endraw %}

`where: "label", page.collection` finds the collection object whose label matches the page you're on, and `first` unwraps the single match. Now `docs` is every document in that collection, in path order.

## Step 1: turn a path into its folder

This is the step the tutorials get wrong, so do it deliberately. You want `_notes/git/rebase.md` to become `_notes/git` — the path with the last segment removed.

Split on `/`, then drop the last element. Liquid has no "drop last" filter, but it does have `slice`, and `slice: 0, n` keeps the first `n` elements. The number you want is one less than the count:

{% raw %}
```liquid
{% assign parts = doc.path | split: "/" %}
{% assign depth = parts.size | minus: 1 %}
{% assign dir = parts | slice: 0, depth | join: "/" %}
```
{% endraw %}

For `_notes/git/rebase.md`, `parts` is `["_notes","git","rebase.md"]`, `parts.size` is `3`, `depth` is `2`, and `slice: 0, 2` keeps `["_notes","git"]`, which joins to `_notes/git`. That's the folder, as a plain string.

You'll know it worked when `dir` for a top-level file like `_notes/index.md` comes out as `_notes` (not empty, not `_notes/index.md`).

## Step 2: print each folder once, then its files

Track the previous folder in a variable. When the current doc's folder differs from the last one, emit a folder header; otherwise emit only the file. Because `docs` is sorted by path, every file in a folder is contiguous, so a folder only differs from the previous once — right when you cross into it.

{% raw %}
```liquid
{% assign prev_dir = "" %}
<ul class="collection-tree">
{% for doc in docs %}
  {% assign parts = doc.path | split: "/" %}
  {% assign depth = parts.size | minus: 1 %}
  {% assign dir = parts | slice: 0, depth | join: "/" %}

  {% if dir != prev_dir %}
    <li class="folder">{{ dir }}/</li>
    {% assign prev_dir = dir %}
  {% endif %}

  <li class="file"><a href="{{ doc.url | relative_url }}">{{ doc.title }}</a></li>
{% endfor %}
</ul>
```
{% endraw %}

Run `{% raw %}{{ doc.url | relative_url }}{% endraw %}` rather than the bare `doc.url` — `relative_url` prepends your `baseurl`, so the links survive deployment to a project page under a subpath instead of 404ing.

You'll know it worked when adjacent files in the same folder share one header: two notes under `_notes/git/` produce a single `_notes/git/` line followed by both file links, not the folder name twice.

I rendered the template above against four fake docs (paths `_notes/index.md`, `_notes/git/rebase.md`, `_notes/git/stash.md`, `_notes/shell/awk.md`). The real output, whitespace squeezed:

```html
<ul class="collection-tree">
  <li class="folder">_notes/</li>
  <li class="file"><a href="/notes/">Index</a></li>
  <li class="folder">_notes/git/</li>
  <li class="file"><a href="/notes/git/rebase/">Rebase</a></li>
  <li class="file"><a href="/notes/git/stash/">Stash</a></li>
  <li class="folder">_notes/shell/</li>
  <li class="file"><a href="/notes/shell/awk/">Awk</a></li>
</ul>
```

`stash.md` reuses the `_notes/git/` header instead of re-emitting it. That's the whole feature.

## The part where it broke

The version of this floating around tutorials uses `pop` to chop the filename off:

{% raw %}
```liquid
{% assign current_path = doc.path | split: "/" | pop %}
```
{% endraw %}

That reads beautifully. `pop` removes the last element of an array — `rebase.md` falls off, you're left with the folder. Except **Liquid has no `pop` filter.**

When Liquid hits a filter it doesn't recognize, it doesn't error. It passes the value through unchanged. So `split: "/" | pop` returns the *full* array — filename still attached — and your code happily treats `rebase.md` as a folder name.

I ran exactly this through Liquid 4.0.4 to be sure I wasn't imagining it:

```text
full:   _notes,git,rebase.md
popped: _notes,git,rebase.md
```

`popped` is identical to `full`. The filter ran, removed nothing, and reported no problem. Feed that into a folder loop and you get folder headers like `rebase.md` and `awk.md` — every file shows up twice, once mislabeled as its own folder, once as itself. The page looks busy and almost right, which is the worst kind of wrong.

The tell: if your sidebar shows a "folder" whose name ends in `.md`, your filename-removal step is a no-op. `pop` is a JavaScript/Ruby array method, not a Liquid filter — the muscle memory leaks across languages. Use `slice` with an explicit length, as in Step 1, and the filename actually comes off.

## When it still misbehaves

A few honest edges this simple version doesn't cover:

- **Deep nesting only shows the leaf folder.** A file at `_notes/git/advanced/rebase.md` prints one header, `_notes/git/advanced/`, and skips intermediate `_notes/git/` if no file lives directly there. For a flat-ish collection that's fine; for a deep tree you'd compare folder segments level by level, which is a lot more Liquid for a sidebar.
- **`prev_dir` resets per page render, not per build.** That's correct here — each page rebuilds the whole tree — but don't try to carry it across includes.
- **Empty folders never appear.** Jekyll collections track documents, not directories, so a folder with no docs never appears in the list. There's nothing to loop over.

## The grouping logic, offline

You don't need Jekyll to sanity-check the "print each folder once" behavior — it's the same loop in any language. Here's the bash version, which I ran to confirm the grouping before wiring up the Liquid:

```bash
# lh:run
cd "$(mktemp -d)"
cat > paths.txt <<'EOF'
_notes/index.md
_notes/git/rebase.md
_notes/git/stash.md
_notes/shell/awk.md
_notes/shell/sed.md
EOF

prev=""
while IFS= read -r p; do
  dir="${p%/*}"        # parent folder: strip the last /segment
  file="${p##*/}"      # bare filename: keep the last /segment
  if [ "$dir" != "$prev" ]; then
    echo "[$dir]"
    prev="$dir"
  fi
  echo "  - $file"
done < paths.txt
```

`${p%/*}` is bash's "remove from the last slash" — the same job `split | slice` does in Liquid, in one expansion. The output:

```text
[_notes]
  - index.md
[_notes/git]
  - rebase.md
  - stash.md
[_notes/shell]
  - awk.md
  - sed.md
```

Each folder header appears once; files nest under it. If the bash version groups cleanly on your real paths, the Liquid version will too — same compare-against-previous trick, same sorted input.

## The honest accounting

It's about fifteen lines of Liquid and it saves you a sidebar you'd otherwise edit by hand every time you add a note. That's the real payoff — not the lines of code, but the list that can't fall out of sync with the files.

The one thing that'll cost you an afternoon isn't the logic, it's `pop`. Reach for `slice` to drop the filename, sort by `path` so the grouping holds, and run your URLs through `relative_url` so the links survive deployment. Then the sidebar draws itself.
