---
title: "Host a Site Free on GitHub Pages: Repo, Jekyll _config, and a Custom Domain"
description: "A repo named user.github.io, the minimal Jekyll _config.yml, the four apex A records, and the CNAME-file gotcha that 404s your custom domain."
date: 2025-11-15
categories: [Hacks]
tags: [jekyll, security]
author: amr
excerpt: "Push a folder, get a website — plus the apex DNS records and the one-line CNAME file everyone fills in wrong."
preview: /images/previews/host-a-site-free-on-github-pages-repo-jekyll-confi.webp
permalink: /hacks/github-pages-hidden-gem/
---
You want a website. The internet wants you to compare hosting plans, pick a tier, enter a card, and then babysit a server that exists only to serve files that never change.

You can skip all of that. GitHub Pages takes a folder, builds it, and serves it over HTTPS off a global CDN, for zero dollars, on public repos. The whole "infrastructure" is a repo with a specific name and a build that runs when you push.

Here's the actual procedure. No tiers, no card. The part that bites — the custom domain — gets its own section at the bottom, because that's where everyone's afternoon goes.

## Step 1: Name the repo exactly right

For a *user site* (the one that lives at `https://USERNAME.github.io`), the repo name is not a suggestion. It must be `USERNAME.github.io`, matching your account name exactly:

```bash
gh repo create yourname.github.io --public --clone
cd yourname.github.io
```

You'll know it worked when `gh repo view` shows the repo and it's public. The name is the address: get a letter wrong and you get an ordinary repo that never turns into a site.

For a *project site* — docs for one repo, served at `https://USERNAME.github.io/REPO/` — any repo name works. The tradeoff is that the site lives under a subpath, which is exactly the thing that breaks links later (see the `baseurl` section at the end).

## Step 2: The smallest site that counts

A single file is a website here. Add an `index.html`, push, done:

```bash
cat > index.html <<'HTML'
<!doctype html>
<title>It's alive</title>
<h1>Hosted on GitHub Pages</h1>
HTML
git add index.html
git commit -m "first page"
git push
```

Then turn Pages on once, in the repo: **Settings → Pages → Build and deployment → Source: Deploy from a branch → `main` / `root`.**

You'll know it worked when, after a minute or two, `https://yourname.github.io` shows your heading. The first build is slower than every build after it — if you get a 404, wait, then hard-refresh, before you assume something's wrong.

## Step 3: Turn on Jekyll for real content

A pile of `index.html` files gets old fast. Jekyll converts Markdown to HTML and gives you layouts, so you write posts instead of hand-rolling `<head>` tags. GitHub Pages runs Jekyll automatically — you opt in by adding a `_config.yml`. Here is the minimal one that actually matters:

```yaml
# _config.yml
title: Your Site
description: What this site is, in one sentence.
url: "https://yourname.github.io"
baseurl: ""              # "" for a user site; "/REPO" for a project site

markdown: kramdown
plugins:
  - jekyll-feed
  - jekyll-sitemap
  - jekyll-seo-tag
```

The two lines that decide whether links work are `url` and `baseurl`. `url` is your real production origin. `baseurl` is the subpath the site lives under — empty for a user site, `/REPO` for a project site. Set `baseurl` wrong and read the `baseurl` section at the end, because that's the wrong you'll set.

Posts go in `_posts/` with a dated filename and front matter:

```bash
mkdir -p _posts
cat > _posts/2025-11-15-hello.md <<'MD'
---
title: "Hello"
date: 2025-11-15
---
First post. Markdown becomes HTML on push.
MD
git add _config.yml _posts/2025-11-15-hello.md
git commit -m "jekyll + first post"
git push
```

You'll know it worked when the deployed build produces a directory with an index, not a bare `.html` file — that directory-with-index shape is what a clean permalink looks like on disk:

```bash
# lh:run
# What Jekyll's "pretty" permalinks produce in _site/ (no Jekyll needed to see the shape).
cd "$(mktemp -d)"
mkdir -p _site/hello
: > _site/hello/index.html
find _site -type f
```

We ran that. Real output:

```text
_site/hello/index.html
```

`/_site/hello/index.html` is served at the URL `/hello/` — a directory and its index, which is why a trailing-slash link to a post works.

## Step 4: A custom domain (the part where it broke)

This is where the free website costs you an afternoon. The site builds fine, the GitHub URL works, you point your domain at it — and every page 404s, or the browser screams about a certificate. Two separate gotchas, both quiet.

### The CNAME file is one bare hostname — nothing else

GitHub Pages reads a file literally named `CNAME` (no extension) at the repo root. It must contain your domain and **nothing else** — no `https://`, no path, no trailing slash. People paste the URL from their browser bar and ship a broken file. Here's a validator you can run before you commit, wrong file first:

```bash
# lh:run
cd "$(mktemp -d)"

# The file people wrongly paste from the address bar:
printf 'https://blog.example.com/\n' > CNAME
echo "pasted:"; cat CNAME

check() {
  if grep -qE '^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$' CNAME; then
    echo "OK    bare hostname"
  else
    echo "BAD   strip the scheme, path, and trailing slash"
  fi
}
check

# The corrected file: just the host.
printf 'blog.example.com\n' > CNAME
echo "fixed:"; cat CNAME
check
```

We ran that. Real output:

```text
pasted:
https://blog.example.com/
BAD   strip the scheme, path, and trailing slash
fixed:
blog.example.com
OK    bare hostname
```

A correct `CNAME` file is 17 bytes for `blog.example.com` — the hostname plus a newline, and that is all.

### The DNS: A records for apex, CNAME for subdomain

How you point the domain depends on whether it's an apex (`example.com`) or a subdomain (`www.example.com`, `blog.example.com`).

A **subdomain** points with one DNS `CNAME` record at your Pages host:

```dns
; subdomain → your github.io site
blog   CNAME   yourname.github.io.
```

An **apex domain** can't be a CNAME (DNS forbids it at the zone root), so you use four `A` records pointing at GitHub's CDN. These are the real, current GitHub Pages addresses — we looked them up live:

```dns
; apex → GitHub Pages, four A records
@   A   185.199.108.153
@   A   185.199.109.153
@   A   185.199.110.153
@   A   185.199.111.153
```

We confirmed those by querying DNS directly:

```console
$ dig +short github.io A
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
$ dig +short -x 185.199.108.153
cdn-185-199-108-153.github.com.
```

That's real captured output. The reverse lookup resolving to `cdn-...github.com` is the tell that the address belongs to GitHub's CDN and not to some stale IP a tutorial copied in 2019. If your apex still 404s after the records propagate, `dig +short yourdomain.com` should print exactly those four IPs in some order — if it prints anything else, your DNS isn't pointed where you think.

### Then enable HTTPS — but only after DNS resolves

In **Settings → Pages**, set the custom domain, save, and *wait* for the green check before ticking **Enforce HTTPS**. GitHub provisions the TLS certificate after it can see your DNS pointing at it. Tick "Enforce HTTPS" too early and you get a certificate error instead of a site, which looks like a catastrophe and is only a race you lost by thirty seconds. Untick it, wait for the domain check, tick it again.

## The part where it broke, again: baseurl

The other afternoon-killer has nothing to do with domains. Deploy a *project* site to `yourname.github.io/myrepo/` with `baseurl: ""` and **every link 404s** — home, CSS, posts, all of it — while the site builds perfectly clean.

The cause: with `baseurl` empty, a link written `/about/` resolves to `yourname.github.io/about/`, but the whole site actually lives under `/myrepo/`. Every absolute path is off by the repo name.

The fix is both halves together:

```yaml
# _config.yml
baseurl: "/myrepo"
```

and stop hard-coding leading-slash paths in templates — run them through `relative_url` so they pick up `baseurl`:

{% raw %}
```liquid
<a href="{{ '/about/' | relative_url }}">About</a>
```
{% endraw %}

The trap is that `jekyll serve` defaults to the root locally, so a hard-coded `/about/` works on your laptop and breaks only in production. If your links work locally only when `baseurl` is empty, you've got hard-coded paths waiting to 404 the moment you deploy under a subpath.

## The honest accounting

A repo with the right name, an `index.html`, a ten-line `_config.yml`, and — if you want your own domain — four A records and a one-line file. That's the whole stack, and it costs nothing.

What it doesn't do: it serves static files only. No server-side code, no database, no form handler — those need a third-party service or a different host. And the "free" part assumes a public repo; private-repo Pages needs a paid plan.

But for a blog, docs, a portfolio, or a project page, the math is hard to beat: you push a folder and get an HTTPS site on a CDN. Name the repo right, keep the `CNAME` file to one bare line, point apex domains at the four A records, and wait for the green check before you enforce HTTPS. Then go push a folder and call it hosting.
