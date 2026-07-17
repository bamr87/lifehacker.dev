# The Build Journey — lifehacker.dev, night one

> The honest, behind-the-scenes log of turning a five-file remote-theme starter
> into a real site run by a robot. The *published*, funnier versions of these
> stories live in the [Field Notes](https://lifehacker.dev/blog/); this file is
> the engineering ledger, with screenshots and receipts.

## Where we started

A bare [zer0-mistakes](https://github.com/bamr87/zer0-mistakes) remote-theme starter: `_config.yml`, `Gemfile`, `index.md`, `CNAME`, `.gitignore`, plus the setup tutorial in [`docs/README.md`](../README.md). The home page rendered the theme's onboarding wizard because `site_configured` was `false` and the site had no `_data/` of its own.

![Before — the welcome wizard](screenshots/00-before-welcome-wizard.png)

## What we built

| Area | What changed |
|---|---|
| **Config** | A deliberate `_config.yml`: neon skin, palette, 6 collections, the defaults cascade, the whitelisted plugins, analytics/AI-chat explicitly **off**. A `_config_dev.yml` for local builds. |
| **Data** | `_data/navigation/`, `authors.yml` (a human + the resident robot), `landing.yml`, and a brand-as-data system in `_data/brand/` (`identity`, `voice`, `glossary`) that keeps the autopilot on-voice. Plus the theme's `ui-text`/`skins`/`backgrounds` (which `remote_theme` doesn't deliver). |
| **Spine** | `index.md` (custom neon hero), `404.html`, hand-authored `search.json` + `/sitemap/` (the theme's generator can't run on Pages), and `/blog/`, `/hacks/`, `/tools/` index pages. |
| **Content** | 4 satirical field notes + 2 hacks + 2 tool reviews, written on-voice, every command real. |
| **Autopilot** | `.claude/skills/grow-lifehacker/SKILL.md`, `_data/backlog.yml`, `scripts/preview.sh`, and the docs at `/docs/autopilot/` + `/about/colophon/`. |

## After

| Page | Screenshot |
|---|---|
| Home | ![home](screenshots/01-after-home.png) |
| Hacks | ![hacks](screenshots/02-after-hacks.png) |
| A hack article | ![article](screenshots/03-after-hack-article.png) |
| Colophon | ![colophon](screenshots/04-after-colophon.png) |
| Field Notes | ![blog](screenshots/05-after-blog.png) |
| Tools | ![tools](screenshots/06-after-tools.png) |

## Mistakes filed upstream

Per the prime directive — when the theme breaks, file it, don't paper over it — building this site surfaced three genuine, distinct issues on [zer0-mistakes](https://github.com/bamr87/zer0-mistakes):

- [#201](https://github.com/bamr87/zer0-mistakes/issues/201) — `fix:` giscus
comments silently disabled because `_config.yml` uses the misspelled key `gisgus:` while every template reads `site.giscus`.
- [#202](https://github.com/bamr87/zer0-mistakes/issues/202) — `fix:`
remote-theme Pages consumers 404 on `/search.json` and `/sitemap/` (the generator is a plugin Pages won't run, and the stubs aren't delivered).
- [#203](https://github.com/bamr87/zer0-mistakes/issues/203) — `feat(docs):` add
a single "remote-theme Pages consumer checklist" enumerating everything `remote_theme` doesn't deliver. lifehacker.dev is the worked reference.

## How to reproduce the preview

```bash
scripts/preview.sh        # overlay onto a theme clone + docker compose up → http://localhost:4000
```

The build is clean (feed + sitemap generate; the only console note is a harmless "pagination skipped" because there's no paginated index — by design).
