---
title: "Kill dead links in Jekyll: stable permalinks, redirect_from, and a CI link checker"
description: "Pretty permalinks that survive a rename, redirect_from so old URLs resolve, and a CI link check — plus the baseurl gotcha that 404s your project site."
date: 2025-08-31
categories: [Hacks]
tags: [ci-cd, jekyll]
author: amr
excerpt: "Rename a post, keep the old link working, and let CI catch the 404 before a reader does."
preview: /assets/images/previews/404-hunting-binary-wards-for-unbreakable-links.png
permalink: /hacks/kill-dead-links-jekyll-permalinks/
---
![A retro terminal warding off 404 errors with binary sigils](/assets/images/previews/404-hunting-binary-wards-for-unbreakable-links.png)

You rename a post. The title was wrong, the slug was uglier than the title, and now it's fixed. You feel good for about a day, until someone clicks a link from six months ago and lands on a 404. The link wasn't broken when they saved it. You broke it.

Dead links are the tax you pay for editing your own site. The fix isn't "never rename things" — it's three pieces of config and one CI job, so that when you do rename things, the old URL still works and a robot yells at you before a human finds the hole.

Here's the whole kit. None of it needs a server.

## Step 1: Make permalinks that don't move

Half of all 404s come from URLs that change shape for no reason — `.html` one day, a trailing slash the next, a date prefix you didn't ask for. Pin the shape once in `_config.yml`:

```yaml
permalink: pretty          # /my-post/  not  /my-post.html
url: https://example.com   # your real production domain
baseurl: ""                # "" for a root domain; "/repo" for project pages
plugins:
  - jekyll-sitemap
  - jekyll-redirect-from
```

`permalink: pretty` gives every page a clean directory-style URL with a trailing slash, so links stop flipping between `.html` and slash forms. `jekyll-sitemap` writes a `sitemap.xml` so crawlers can rediscover pages that moved. `jekyll-redirect-from` is the one that does the actual saving — Step 3.

You'll know it worked when `bundle exec jekyll build` produces `_site/my-post/index.html` (a directory with an index) instead of `_site/my-post.html` (a bare file). Pretty permalinks make directories.

## Step 2: Keep the old URL alive when you rename

This is the move. When you change a slug, you don't abandon the old path — you make the *new* page answer to both names. Add `redirect_from` to the renamed file's front matter:

```yaml
---
title: "The Better Title"
permalink: /the-better-title/
redirect_from:
  - /the-old-title/
  - /2024/03/10/the-old-title/   # an old dated path counts too
---
```

`jekyll-redirect-from` generates a tiny stub page at each old path that bounces the visitor to the new one. No `.htaccess`, no server rules — it ships as plain HTML, which is exactly what GitHub Pages serves.

You'll know it worked when `_site/the-old-title/index.html` exists after a build and contains a `<meta http-equiv="refresh">` pointing at `/the-better-title/`. The old link resolves; the reader never sees the seam.

One rule that keeps this sane: **one canonical URL per page, every other path redirects to it.** Don't give a page two live permalinks and hope. Pick the real one, redirect the rest.

## Step 3: A 404 page that's a map, not a wall

Even with redirects, some links die for real — external sites vanish, you delete a page on purpose. Make the dead end useful. Put this in `404.html` at your site root:

{% raw %}
```html
---
permalink: /404.html
---
<main style="max-width:720px;margin:3rem auto;padding:0 1rem">
  <h1>404 — that page moved or never existed</h1>
  <p>Two doors out:</p>
  <ul>
    <li><a href="{{ '/' | relative_url }}">Home</a></li>
    <li><a href="{{ '/sitemap.xml' | relative_url }}">Sitemap (every live page)</a></li>
  </ul>
  <h2>Recent posts</h2>
  <ul>
    {% for post in site.posts limit:5 %}
      <li><a href="{{ post.url | relative_url }}">{{ post.title }}</a></li>
    {% endfor %}
  </ul>
</main>
```
{% endraw %}

`permalink: /404.html` is what GitHub Pages looks for to serve a custom 404. The `relative_url` filter matters — it prepends your `baseurl`, so the links work whether you're on a root domain or a project page. (Hard-code a leading-slash path here and you'll reproduce the exact bug in the next section.)

You'll know it worked when visiting a made-up path on the deployed site shows your page and its links go somewhere real.

## Catch them before CI does: a grep dead-link pre-check

Before you push and wait for CI, you can find broken *internal* links with nothing but grep and the built `_site/` directory. Pull every internal href and check whether the target file exists on disk. Here's the idea, run against a tiny throwaway site so you can see the shape of the output:

```bash
# Make a throwaway "site" with two real pages and one broken link.
site="$(mktemp -d)"
cd "$site"

cat > index.html <<'HTML'
<a href="/about.html">About</a>
<a href="/team.html">Team</a>
<a href="https://example.com/">External (skipped)</a>
HTML

cat > about.html <<'HTML'
<a href="/index.html">Home</a>
HTML

# Pull internal hrefs (start with a single /), strip to a path,
# and report whether each target exists on disk.
grep -rhoE 'href="/[^"/][^"]*"' . \
  | sed -E 's@^href="/([^"]*)"@\1@' \
  | sort -u \
  | while read -r path; do
      [ -f "$path" ] && echo "OK    /$path" || echo "DEAD  /$path"
    done

rm -rf "$site"
```

We ran that; here's the real output:

```text
OK    /about.html
OK    /index.html
DEAD  /team.html
```

`team.html` is the link with no file behind it — the 404 you would have shipped. The external `https://` link is skipped on purpose: grep can't tell you if a remote host is up, only whether a local file exists. Point this at your real `_site/` after a build (with `permalink: pretty`, internal targets look like `/my-post/`, so check for `$path/index.html` too) and it'll list your broken internal links in about a second.

This is a smoke test, not the full check. It doesn't follow external links, parse redirects, or understand `baseurl`. That's the CI job's job.

## Step 4: The CI job that follows every link

Once per pull request, have a real link checker crawl everything — internal and external. [lychee](https://github.com/lycheeverse/lychee-action) is fast and ships as a GitHub Action:

{% raw %}
```yaml
name: link-check
on:
  pull_request:
  schedule:
    - cron: '0 3 * * 1'   # weekly sweep catches bit-rot in old posts
jobs:
  lychee:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: lycheeverse/lychee-action@v2
        with:
          args: >-
            --no-progress
            --accept 200,204,206,301,302,308
            --exclude-mail
            --timeout 20
            './**/*.md' './**/*.html'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```
{% endraw %}

The `--accept` list is the part people skip and then wonder why every redirect is "broken": `301`/`302`/`308` are redirects, not failures, so a healthy `redirect_from` stub returns `301` and should pass. The scheduled run matters because external links rot on their own timeline — a host that was fine at merge can vanish three months later, and the Monday sweep finds it.

You'll know it worked when a PR that introduces a typo'd link gets a red check listing the exact bad URL, and a clean PR stays green.

## The part where it broke

Here's the one that cost a real afternoon, and it had nothing to do with renamed posts.

I deployed to a project site — `username.github.io/myrepo/` — and **every link 404'd**. Home, posts, CSS, all of it. The site built clean locally. It built clean in CI. It served a wall of 404s in production.

The cause: `baseurl` was `""`. On a root domain that's correct. On a project page the whole site lives under `/myrepo/`, so a link written as `/about/` resolves to `username.github.io/about/` — which doesn't exist — instead of `username.github.io/myrepo/about/`. Every absolute internal path was off by the repo name.

Two fixes, and you need both:

1. Set the prefix in `_config.yml`:

   ```yaml
   baseurl: "/myrepo"
   ```

2. Stop hard-coding leading-slash paths in templates. Run them through a filter that prepends `baseurl`:

   {% raw %}
   ```liquid
   <a href="{{ '/about/' | relative_url }}">About</a>
   ```
   {% endraw %}

   not

   ```liquid
   <a href="/about/">About</a>   <!-- ignores baseurl, 404s on project pages -->
   ```

The trap is that `jekyll serve` defaults to serving at the root locally, so a hard-coded `/about/` works on your laptop and breaks only in production. To surface it early, don't reach for `--baseurl ''` — that hides the bug. Serve with the real baseurl so local matches prod:

```bash
bundle exec jekyll serve   # honors baseurl from _config.yml
```

If links work locally only when you delete `baseurl`, you have hard-coded paths waiting to 404 the moment you deploy under a subpath.

## The honest accounting

Permalinks, redirects, a 404 map, a grep pre-check, and one CI job. The config is maybe twenty lines total and it's mostly copy-paste.

What it buys you isn't speed — it's that editing your site stops being dangerous. Rename a post, the old link redirects. Delete a page, the 404 hands the reader a map. Ship a typo'd link, CI catches it before a human does. The grep check is the cheapest of the lot: no build, no network, only the question "does this file exist," answered in a second.

Rename freely. Redirect the old paths. Let the robot find the holes.
