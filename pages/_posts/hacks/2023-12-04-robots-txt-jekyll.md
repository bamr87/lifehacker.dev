---
title: "A robots.txt That Actually Works on Jekyll (and the sitemap line people forget)"
description: "The Jekyll robots.txt that ships unrendered {{ braces }} to crawlers, the front-matter line that fixes it, and an offline check that catches it before deploy."
date: 2023-12-04
categories: [Hacks]
tags: [jekyll]
author: amr
excerpt: "Your robots.txt looks right and crawlers still read it wrong — because Jekyll never rendered the line that matters."
preview: /images/previews/a-robots-txt-that-actually-works-on-jekyll-and-the.webp
permalink: /hacks/robots-txt-jekyll/
---
{% raw %}

A `robots.txt` is the most-copied file in web development. Four lines, a wildcard, a `Disallow`, a `Sitemap`, done — every tutorial ships the same block and every tutorial is technically correct.

It is also where I shipped a file that told Google my sitemap lived at `{{ site.url }}/sitemap.xml`. Literally. Curly braces and all. The file looked perfect in my editor and broke the one line it existed to get right.

Here is the version that works on Jekyll, why the obvious version doesn't, and a check you can run before you push so a crawler isn't the first to find the hole.

## The file

Put this at the **root of your source** — the same folder as `_config.yml`, not inside `_includes` or `_data`. The filename is `robots.txt`, no leading underscore.

```text
---
permalink: /robots.txt
layout: null
sitemap: false
---
User-agent: *
Disallow: /secret/
Disallow: /private/
Disallow: /drafts/

Sitemap: {{ site.url }}{{ site.baseurl }}/sitemap.xml
```

The body is the boring part everyone gets right:

- `User-agent: *` — the rules apply to every crawler.
- `Disallow: /secret/` — keep robots out of that path. Repeat per directory you want left out of search.
- `Sitemap:` — points crawlers at the full list of your live pages.

The part that is not boring is the three lines at the top, between the `---` fences. That is the front matter, and it is the difference between this file working and the literal-braces disaster below.

## The part where it broke

Here is the failure I shipped, because it is the entire point of this post.

The first robots.txt I deployed had **no front matter** — only the body, starting at `User-agent`. It built. It deployed. It served at `/robots.txt`. Everything looked fine.

Then I checked the live file and the sitemap line read:

```text
Sitemap: {{ site.url }}/sitemap.xml
```

Not my domain. The literal Liquid tag, braces intact, served to every crawler that asked.

The cause: **Jekyll only renders Liquid in files that have a front-matter block.** A file with the two `---` fences at the top gets processed — its `{{ ... }}` tags are evaluated. A file *without* them is treated as a static asset and copied byte-for-byte to `_site/`. My braces were copied verbatim because Jekyll never considered the file something to render.

You can see the exact shape of the bug without Jekyll at all. This is a real run:

```bash
# lh:run
cd "$(mktemp -d)"

# A robots.txt that has the Sitemap line but (like my first one) was never rendered.
cat > robots.txt <<'EOF'
User-agent: *
Disallow: /secret/
Sitemap: {{ site.url }}/sitemap.xml
EOF

# Pull the Sitemap value and ask the only question that matters:
# is it an absolute URL a crawler can actually fetch?
sitemap=$(grep -i '^Sitemap:' robots.txt | sed -E 's/^Sitemap:[[:space:]]*//')
case "$sitemap" in
  https://*|http://*) echo "OK  absolute: $sitemap" ;;
  *) echo "BAD relative or templated: $sitemap" ;;
esac
```

Real output:

```text
BAD relative or templated: {{ site.url }}/sitemap.xml
```

That `BAD` is exactly the file I deployed. The fix is to add the front matter so Jekyll renders the line — which is what the working file at the top does.

## The two fixes you need together

**1. The `---` fences.** They turn the file from a static copy into something Jekyll renders. Without them, no Liquid runs and your `{{ site.url }}` ships as text. This is the one I missed.

**2. The `permalink: /robots.txt`.** Once a file has front matter, Jekyll may apply its default permalink rules and put the output somewhere unexpected. Pinning `permalink: /robots.txt` guarantees it lands at the root, where crawlers look for it — `https://yoursite.com/robots.txt`, nothing else.

The other two front-matter lines are insurance:

- `layout: null` stops Jekyll from wrapping your robots.txt in your site's HTML layout (a `<html>` wrapper around `User-agent: *` is its own kind of broken).
- `sitemap: false` keeps the `jekyll-sitemap` plugin from listing your robots.txt *inside* the sitemap, which is pointless and slightly embarrassing.

## Get the Sitemap URL right (the line people forget)

The reason to use `{{ site.url }}{{ site.baseurl }}` instead of hard-coding the domain: the `Sitemap:` directive **must be an absolute URL**. A bare `Sitemap: /sitemap.xml` is invalid per the spec — crawlers want the full `https://...` so they can fetch it from anywhere.

Set both values in `_config.yml` so the template has something to render:

```yaml
url: "https://lifehacker.dev"   # protocol + host, no trailing slash
baseurl: ""                     # "" for a root domain; "/repo" for project pages
```

`baseurl` is the one people on GitHub Project Pages forget. If your site lives at `username.github.io/myrepo/`, your sitemap is at `username.github.io/myrepo/sitemap.xml`, and only `{{ site.baseurl }}` puts the `/myrepo` in. Drop it and you advertise a sitemap URL that 404s.

You'll know the values are right when, after a build, `_site/robots.txt` contains your real domain and a fetchable sitemap path — not a single curly brace.

## The pre-deploy check

You don't need to wait for a crawler to tell you the line is broken. After `bundle exec jekyll build`, run a two-question check against the *built* file in `_site/` — does the Sitemap resolve to an absolute URL, and did any literal Liquid leak through? Here it is run against a built file that has both problems, so you can see what a failure looks like:

```bash
# lh:run
cd "$(mktemp -d)"

# Stand in for a built _site/robots.txt that was never rendered.
cat > robots.txt <<'EOF'
User-agent: *
Disallow: /secret/
Sitemap: {{ site.url }}/sitemap.xml
EOF

fail=0

# 1) The Sitemap line must be an absolute URL.
sitemap=$(grep -i '^Sitemap:' robots.txt | sed -E 's/^Sitemap:[[:space:]]*//')
case "$sitemap" in
  https://*|http://*) echo "OK   sitemap absolute: $sitemap" ;;
  *) echo "FAIL sitemap not absolute: $sitemap"; fail=1 ;;
esac

# 2) No unrendered Liquid braces may survive into the built file.
if grep -nq '{[{%]' robots.txt; then
  echo "FAIL unrendered Liquid leaked:"
  grep -n '{[{%]' robots.txt
  fail=1
else
  echo "OK   no leftover Liquid"
fi

exit $fail
```

Real output:

```text
FAIL sitemap not absolute: {{ site.url }}/sitemap.xml
FAIL unrendered Liquid leaked:
3:Sitemap: {{ site.url }}/sitemap.xml
```

Two clean `FAIL`s — the same two problems my deployed file had, caught on a laptop in under a second. Point this at your real `_site/robots.txt` after a build; when both checks read `OK`, the file is safe to ship. Wire the same two `grep`s into CI and you'll never hand-render-check a robots.txt again.

## When this goes wrong

A few traps that survive even the fixes above:

- **You edited `_site/robots.txt` directly.** That folder is generated; every build overwrites it. Edit the source file at the project root, then rebuild.
- **The file isn't at the root after build.** If `_site/robots.txt` is missing or nested, you skipped `permalink: /robots.txt` — front matter without a pinned permalink can relocate the output.
- **`Disallow` is not security.** It asks polite crawlers not to *index* a path; it does not block access. Anyone can still read a "disallowed" page, and listing `/secret/` in a public file arguably advertises it. Use real auth for real secrets — robots.txt is a hint, not a lock.
- **Disallowing a page does not remove it from search reliably.** A page blocked in robots.txt can still appear in results (from external links) without its content. To actually keep a page out of the index, let crawlers reach it and serve a `<meta name="robots" content="noindex">` on the page itself.

## The honest accounting

The whole fix is three lines of front matter and one absolute-URL convention. It buys you nothing flashy — only a robots.txt that says your real domain instead of a curly-brace apology.

The lesson generalizes past this one file: on Jekyll, **no front matter means no rendering.** Any file where you're reaching for `{{ ... }}` — robots.txt, a CNAME with a templated value, a hand-rolled feed — needs the two `---` fences or the template ships as text. Add the fences, pin the permalink, run the two-line check, and let the crawler find your sitemap instead of your bug.

{% endraw %}
