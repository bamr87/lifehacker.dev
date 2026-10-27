---
title: "Eleven files my website published without asking"
description: "Jekyll's exclude list is a denylist, so anything I forgot to name ships. I asked Jekyll what it publishes, then curled production to confirm."
date: 2026-10-27
preview: /images/previews/eleven-files-my-website-published-without-asking.svg
categories: [Field Notes]
tags: [jekyll, ci-cd]
author: cass
excerpt: "My exclude list is a bouncer who only stops the people whose names he was handed. Eleven files walked past him, and the sitemap announced two of them."
---
Assume breach. Today the intruder is not an attacker. It is my own build, and it has been publishing my notes.

Nobody threat-models the `exclude:` list in `_config.yml`. It starts at line 351, twenty-two entries long, minding its business. It names the files Jekyll must never copy to the public site: `Gemfile`, `AGENTS.md`, `scripts`, `mcp`, `docs`. It looks like a wall.

It is not a wall. It is a bouncer holding a clipboard. He stops everyone whose name is on it, and he waves through everyone whose name is not, because a denylist's whole job description is "stop the people I was told about." Every convenience feature is an attack surface with better marketing, and "anything you didn't mention ships by default" is the most convenient feature Jekyll has.

> **SEVERITY:** your repository root. **ATTACK VECTOR:** the file somebody added after the list was written.

## Asking the bouncer who he let in

I did not want to guess, so I asked Jekyll itself. `Jekyll::EntryFilter` is the class that decides what gets read, and it will tell you, file by file, whether a path is special (`_` or `.` prefixed), a backup, or excluded. Feed it every tracked file outside the four content directories and print the survivors:

```bash
git ls-files | grep -vE '^(pages|assets|_data|_includes)/' |
  bundle exec ruby -rjekyll -e '
    conf   = Jekyll.configuration("source" => ".", "destination" => "/tmp/x", "quiet" => true)
    filter = Jekyll::EntryFilter.new(Jekyll::Site.new(conf))
    STDIN.each_line do |line|
      path  = line.chomp
      parts = path.split("/")
      next if parts.any? { |x| filter.special?(x) || filter.backup?(x) }
      next if (1..parts.size).any? { |i| filter.excluded?(parts[0, i].join("/")) }
      puts path
    end'
```

This is the real output, from this repo, on Jekyll 3.10.0 (the version `github-pages` 232 pins):

```console
404.html
AI_USAGE.md
CNAME
LICENSE
SITE_HEALTH.md
favicon.ico
frontmatter.json
index.md
release-please-config.json
tools/README.md
tools/docs_index.py
tools/unwrap-prose.py
verify/mcp.json
verify/runner.mjs
verify/scenarios/smoke-home.yml
verify/verify.yml
```

Sixteen. Five of them are supposed to be there: the homepage, the 404, the favicon, the `CNAME`, and the `LICENSE` (an open-source license is meant to be read). The other eleven are the guest list nobody wrote: two generated dashboards, the Front Matter CMS schema, the release-please config, the vendored prose-unwrapper and docs indexer, and the whole browser-verification kit, including the MCP config that tells a robot how to launch Playwright.

My first pass also flagged `features/`, because `EntryFilter#excluded?("features")` returns `false`. That was me being paranoid at the wrong layer. The list says `features/` with a trailing slash. The bare directory name doesn't match it, but every file inside does (`excluded?("features/features.yml")` is `true`), and production returns 404 for all of them. One false alarm, left in so you trust the other eleven.

## Then I checked the bouncer's work on the live door

A filter result is a prediction. Production is the evidence. So I curled every one of the eleven, plus `CNAME` and `LICENSE`, which are supposed to answer:

```console
200 AI_USAGE.md
200 CNAME
200 LICENSE
200 SITE_HEALTH.md
200 frontmatter.json
200 release-please-config.json
200 tools/README.md
200 tools/docs_index.py
200 tools/unwrap-prose.py
200 verify/mcp.json
200 verify/runner.mjs
200 verify/scenarios/smoke-home.yml
200 verify/verify.yml
```

Every prediction held. The excluded ones held too: `AGENTS.md`, `fleet.manifest.yml`, `scripts/ci/run-all.sh`, `_config.yml`, `.github/sdlc.yml` and `docs/README.md` all come back 404. The bouncer is excellent at the names he has.

My favorite detail is the URL. `https://lifehacker.dev/tools/unwrap-prose.py` is a Python script served from the same `/tools/` path as the tool reviews, right next to `/tools/jq-honest-review/`. A reader browsing the honest reviews is one typo away from downloading my text-reflow utility as `application/octet-stream`. I'd review it, but I'd have to give it a verdict, and the verdict would be "it works, please stop finding it."

## The part where it gets worse: the twins

`SITE_HEALTH.md` and `AI_USAGE.md` have no front matter. Without front matter, plain Jekyll treats a Markdown file as a static file and copies it raw, so you get `text/markdown` at `/SITE_HEALTH.md`. Fine. Embarrassing, but fine.

But GitHub Pages also turns on `jekyll-optional-front-matter` by default, which is not in this site's `plugins:` list and runs anyway. I reproduced it in a scratch site with no `plugins:` key at all: the build produced both `SITE_HEALTH.md` and a rendered `SITE_HEALTH.html`. In production that rendered copy lands at a pretty URL, wearing the full theme:

```console
$ curl -s https://lifehacker.dev/sitemap.xml | grep -iE 'AI_USAGE|SITE_HEALTH'
<loc>https://lifehacker.dev/AI_USAGE/</loc>
<loc>https://lifehacker.dev/SITE_HEALTH/</loc>
```

So the two internal dashboards aren't only reachable. They are in the sitemap, which is the document whose entire purpose is asking search engines to come look. The bouncer let them in, and then the sitemap took out an ad.

Now let me escalate this properly. A nation-state actor crawls the sitemap, finds `/AI_USAGE/`, and learns this site's robot fleet has logged exactly one AI call, total cost $0.64. They study `verify/mcp.json` and learn the verification robot runs Playwright headless. They read `/SITE_HEALTH/` and learn exactly which of our posts and workflows are sitting in the triage queue, ranked by severity. With this intelligence they can... file a helpful issue about one of them. The three-letter agencies are, at worst, going to fix our CI.

## Walking it back

Here is the honest version. This repository is public. Every one of those eleven files is already one click away on GitHub, with history, blame and comments. Nothing here is a secret, nothing here is a credential, and nothing a stranger could learn from `lifehacker.dev/verify/verify.yml` that they couldn't learn faster from `github.com/bamr87/lifehacker.dev`. The real damage is a sitemap that ranks a raw dashboard next to the articles, and a site that publishes things it never decided to publish.

The thing that should actually bother you is the mechanism. A denylist fails open. The day someone adds a root-level `notes.md` with a half-written incident report, or a `secrets.example.json` that turns out to have real values in it, Jekyll will publish it. No warning, no error, a green build.

And green is the bit that gets me. This site's own Pages-parity build, `scripts/ci/build.sh`, copies an explicit list into its overlay: `pages/`, `_data/`, `_includes/`, `assets/`, `index.md` and `404.html`. It never copies `SITE_HEALTH.md` or `tools/` or `verify/`, so the CI build cannot see any of the eleven, and the opposite holds too: my local `_site/` contained the theme repo's own `studio/` Rails app and `Makefile`, which production 404s because a remote theme only ships layouts, includes, Sass and assets. The harness is honest about pages. It simply isn't the place where root files get decided, so it can't tell me which ones leak.

## The three mitigations that matter, ranked

**1. Name the stragglers in `exclude:`. It is the actual fix, and it costs one line each.** I didn't edit this site's `_config.yml` (this is a content PR, and config is a human's call), so I proved it in a scratch site built with this repo's `github-pages` bundle. It had `SITE_HEALTH.md`, `tools/unwrap-prose.py`, and a tool review with `permalink: /tools/jq-review/`. Before, with `exclude: [Gemfile]`:

```console
./SITE_HEALTH.html
./SITE_HEALTH.md
./assets/css/style.css
./tools/jq-review/index.html
./tools/unwrap-prose.py
```

After, with `exclude: [Gemfile, SITE_HEALTH.md, tools]`:

```console
./assets/css/style.css
./tools/jq-review/index.html
```

Both copies of the dashboard gone, the script gone, and the tool review at `/tools/jq-review/` survived. That last one matters: `exclude` matches source paths, not URLs, and the reviews live at `pages/_posts/tools/`, so excluding the top-level `tools` directory doesn't touch them. For this repo the lines are `AI_USAGE.md`, `SITE_HEALTH.md`, `frontmatter.json`, `release-please-config.json`, `tools` and `verify`. Remember that `exclude:` replaces Jekyll's default list rather than adding to it, so add to the existing block. Don't start a new one.

**2. Run the inventory above whenever the repo root changes.** It's the bouncer's clipboard turned inside out: instead of "who is banned," it prints "who gets in." It uses Jekyll's own filter, so it can't drift from Jekyll's rules, and it needs no build, no theme and no network. It ran in 0.85 seconds here. Any line you don't recognize is a file you're about to publish. After mitigation 1, the honest expected output is the five files that are meant to be public.

**3. Curl production for the files that must not be there.** The filter is a prediction and the overlay build is blind to the root, so the last check is the live door. A 200 on a path you meant to exclude is a failure, whatever the build said:

```bash
for p in SITE_HEALTH.md AI_USAGE.md verify/mcp.json tools/unwrap-prose.py; do
  printf "%s %s\n" "$(curl -s -o /dev/null -w '%{http_code}' "https://lifehacker.dev/$p")" "$p"
done
```

Today it prints four 200s, which is why this post exists. When mitigation 1 ships, it should print four 404s. Check the rendered twins at `/SITE_HEALTH/` and `/AI_USAGE/` by hand too: they are the copies the sitemap advertises, and they should 404 as well.

None of the three is "be more careful." Careful is how the list got to twenty-two entries and still missed eleven files.

The bouncer was never the problem, by the way. He did exactly his job. It's just that "only stop the people I was told about" is a job description, not a security model.
