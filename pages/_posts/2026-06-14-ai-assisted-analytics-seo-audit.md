---
title: "The first thing analytics told me was that the analytics were wrong (85% of traffic was me)"
description: "I finally wired Google Analytics into a tool I could query, got a 304% traffic spike, and discovered 85% of it was localhost. Here's the segment that saved me."
preview: /images/previews/the-first-thing-analytics-told-me-was-that-the-ana.png
date: 2026-06-14
categories: [Field Notes]
tags: [google-analytics, jekyll, seo, observability, debugging]
author: amr
excerpt: "I connected the data source, asked for the numbers, and the numbers were a lie. The first real win from analytics was finding out the analytics were broken."
---

I had Google Analytics installed on this site for months and never once looked at it. That is the most honest sentence in this post. The dashboard was there, collecting numbers, and I treated it the way I treat a smoke detector: I assumed silence meant everything was fine.

So I finally wired it up to something I could actually query on demand — a small tool that wraps the Google Analytics Data API and lets me ask for `runReport` results without opening a single web dashboard. I ran the first query. It told me I had **18,943 active users in the last 28 days, up 304%**.

For about ninety seconds I believed it.

## The part where it broke (before I even started)

The very first credential I tried to plug in was the wrong kind, and this is worth thirty seconds of your life because everyone hits it.

Google hands you two JSON files that look nearly identical and do completely different jobs. An **OAuth client** (`client_secret_….apps.googleusercontent.com.json`) is for a human clicking "allow" in a browser. A **service account** is for a server talking to a server with no human in the loop — and that is what the API client needs. The Data API call needs the service-account flow, full stop.

You don't have to memorize which is which. The file tells you, if you ask it the right way:

```bash
# lh:run
# Two creds that look alike. One has type: service_account. That's the one you want.
printf '%s\n' '{"web":{"client_id":"123.apps.googleusercontent.com"}}' > client_secret_example.json
printf '%s\n' '{"type":"service_account","client_email":"ga-reader@proj.iam.gserviceaccount.com"}' > service-account.json

for f in *.json; do
  echo "$f -> $(jq -r '.type // (keys[0])' "$f")"
done
```

I ran exactly that, and it prints:

```console
client_secret_example.json -> web
service-account.json -> service_account
```

If the answer isn't `service_account`, you have the OAuth client and the API will reject you. You'll know it worked when `runReport` returns rows instead of an auth error.

## The credential I almost committed to a public repo

Both JSON files landed in the repository root while I was experimenting. This repo is **public**. The files were never committed — I checked `git log --all` after the fact and nothing had leaked — but they were one absent-minded `git add .` away from being on the internet forever.

The repair is belt-and-suspenders. The belt is a local, never-shared ignore in `.git/info/exclude`; the suspenders are the same patterns in `.gitignore` so the protection survives a fresh clone:

```bash
# lh:run
git init -q
printf '%s\n' 'client_secret_*.json' '*.apps.googleusercontent.com.json' '*service-account*.json' >> .git/info/exclude
touch client_secret_abc.json my-service-account.json real_post.md

echo "== what git would actually stage: =="
git status --porcelain
echo "== proof the creds are ignored: =="
git check-ignore client_secret_abc.json my-service-account.json
```

The real output, which is the whole point:

```console
== what git would actually stage: ==
?? real_post.md
== proof the creds are ignored: ==
client_secret_abc.json
my-service-account.json
```

`real_post.md` shows up. The two credential files do not. You'll know it worked when `git check-ignore` echoes back the secret filenames — that means git is actively refusing to see them. Then move the actual key out of the repo entirely (`~/.config/gcloud/`, `chmod 600`) and stop keeping it next to your code. A gitignore is a safety net under the trapeze, not a place to live.

## The plot twist: 85% of "traffic" was me

Back to the 304% spike. A few things about it smelled wrong, and they're the same tells every time:

- Engagement rate had **collapsed to 3%** (it used to be 7%).
- Sessions were lasting about ten seconds.
- 99% of it was "Direct," 99% Chrome on desktop, from datacenter "cities."

A real audience does not behave like that. A build server does. So I segmented by the one dimension nobody thinks to add — **`hostName`** — and there it was:

| Hostname | Sessions | What it actually is |
|---|---:|---|
| `127.0.0.1` | 15,415 | my local `jekyll serve` |
| `it-journey.dev` | 1,765 | real production traffic |
| `localhost` | 471 | also me, local dev |
| `host.docker.internal` | 308 | me, in Docker |
| `zer0-mistakes.com` | 251 | a sibling site reusing the same GA tag |

Roughly **85% of every session was development traffic** — me, refreshing my own site while I worked on it — plus a shared analytics tag bleeding in numbers from other sites. The real production number was ~1,765 sessions in 28 days. About 63 a day. Not thousands.

The lesson I keep relearning, written here so I stop: **a connected data source is not a trustworthy one.** The first useful thing analytics ever told me was that the analytics were measuring the wrong website.

## Fixing it at the source, not in the report

I could have filtered `127.0.0.1` out of every report forever. That's treating the symptom. The root cause was in the Jekyll theme: the analytics include fired on **every** build, with no guard for which environment it was in. The canonical fix is one conditional:

{% raw %}
```liquid
{% if jekyll.environment == "production" %}
  {% include analytics/google-analytics.html %}
{% endif %}
```
{% endraw %}

`jekyll serve` runs in `development`, so the tag never loads on my machine. GitHub Pages builds with `JEKYLL_ENV=production`, so real visitors still count. Belt and suspenders again: inside the include I also bail out on dev hostnames, in case a production-env preview ever runs in Docker:

```js
// Skip dev hostnames even if jekyll.environment somehow says production.
var h = location.hostname;
if (h === 'localhost' || h === '127.0.0.1' || h === 'host.docker.internal' ||
    h.endsWith('.local') || h.endsWith('.test')) return;
```

You'll know it worked when your next 28-day report shows your session count *drop* and your engagement rate *climb*. Smaller, truer numbers are the win.

## Then the honest numbers pointed at the real problem

With the noise gone, the story changed completely. Organic search was tiny — about 316 sessions in 90 days — but **engaged at 41%**, which is a real audience — a small one. So before chasing more of it, I checked whether the site was even crawlable. It mostly wasn't:

- **Duplicated URLs.** A permalink of `/:collection/:path/:name/` repeated the filename, producing `/notes/slug/slug/`. `:path` already ends in the filename, so `:name` was redundant. Fix: `/:collection/:path/`.
- **436 broken `.md` links** across 51 files. The `jekyll-relative-links` plugin was enabled but defaults to `collections: false`, so it silently skipped `_quests`, `_notes`, `_docs`, and `_posts` — turning every `[text](file.md)` into a dead link. Fix: `relative_links: { collections: true }`.
- **Indexable junk.** Internal planning docs (`PRD.md`, build plans) were being crawled and ranked. Fix: `published: false`.

For the already-indexed duplicate URLs I added one generic redirect in `404.html` (`/x/y/y/` → `/x/y/`) instead of pasting `redirect_from` front matter into 34 files. One rule beats thirty-four edits.

## The unglamorous workflow lessons

- **Verify before you "fix."** The live `robots.txt` didn't match the repo's, and I nearly "fixed" it — until I checked and found the branch had *already* fixed it; main hadn't deployed yet. I almost repaired a non-bug.
- **Let CI be the build oracle.** My local Ruby was too old to build the site, so the authoritative check was the clean PR build. That is precisely what a PR is for.

## What I'd tell past me

1. **Segment by hostname before you believe a single GA number.** It's the cheapest sanity check there is.
2. **Gate analytics to production.** One `{% raw %}{% if jekyll.environment %}{% endraw %}` stops you from measuring yourself.
3. **Know your credential types, and keep them out of the repo.** `service_account`, not `web`.
4. **Crawlability is plumbing.** Duplicated URLs and dead internal links quietly cap your reach long before your content does.

No, this was not a *"10x growth-hacking observability stack"*™. It was a smoke detector I finally walked over to read, only to find it had been pointed at my own kitchen the whole time.

---

**Level up.** The hands-on version of this is broken into a quest series on IT-Journey: [Level 1010 · Monitoring & Observability](https://it-journey.dev/quests/1010/), starting with [Connect Analytics to Your AI Agent](https://it-journey.dev/quests/1010/analytics-mcp-setup/).
