# drsai — AI storybooks

**drsai** is a children's book platform: stories written with AI assistance, illustrations rendered with OpenAI image models, and the whole thing published as a real, readable picture book on GitHub Pages.

The first book is [**Deputy Dodge & Ranger Reena: Adventures of a Lifetime**](https://bamr87.github.io/drsai/books/dodge-and-reena/) — twelve gentle desert-town mysteries, one per month, imported from its content repo as the platform's test book.

## How it fits together

```text
Dodge-and-Reena-Book ──▶ tools/import_dodge_and_reena.py ──▶ pages/_books/dodge-and-reena/
  (canonical stories,        (parse stories, match scenes,       (Jekyll books collection:
   illustration bible,        expand prompts)                     front matter = generation
   chosen renders)                                                manifest)
                                                                        │
        OPENAI_API_KEY ──▶ tools/generate_illustrations.py ◀────────────┤ missing scenes
                              (OpenAI Images API)                       │
                                                                        ▼
drsai/ (Python story engine) ─ new verse/stories            zer0-mistakes theme (books
  OpenAI · meter validation                                  layouts) ──▶ GitHub Pages
```

| Piece | Where | Role |
|---|---|---|
| Story engine | [`drsai/`](./drsai/) | Python CLI generating Seuss-style verse/stories via OpenAI (Anthropic/xAI supported), with scansion + rhyme validation |
| ABC content engine | [bamr87/zer0-CMS](https://github.com/bamr87/zer0-CMS) | Rails app + Ruby engine — the ABC wizard that drafts alphabet books (words + per-letter art prompts) and exports them here |
| Book content | [bamr87/Dodge-and-Reena-Book](https://github.com/bamr87/Dodge-and-Reena-Book) | Canonical story text, the illustration style & character bible, chosen AI renders |
| Importer | [`tools/import_dodge_and_reena.py`](./tools/import_dodge_and_reena.py) | Converts the content repo into the site's books collection; matches plates to scenes; idempotent (`--check` runs in CI) |
| Illustrator | [`tools/generate_illustrations.py`](./tools/generate_illustrations.py) | Renders missing scenes/covers with the OpenAI Images API from front-matter prompts |
| Theme | [bamr87/zer0-mistakes](https://github.com/bamr87/zer0-mistakes) | `books` collection, `book`/`book-story` layouts, bookshelf/plate/TOC components |
| Preview banners | [bamr87/zer0-image-generator](https://github.com/bamr87/zer0-image-generator) | Its Python engine (`preview_generator.py`, no Ruby) — OpenAI-rendered social banners per story |

## Run the site locally

In zer0-CMS the site builds with the Jekyll-theme option, with Docker and no Ruby: the theme at the tag the root `workspace.yml` pins, built by GitHub Pages' own builder in a container.

```bash
python3 ../../tools/jekyll_theme.py build drsai    # → _site/
```

Production (GitHub Pages) builds use `remote_theme` too — see `.github/workflows/pages.yml`. Enable **Settings → Pages → Source: GitHub Actions** once per fork.

## Refresh the book from its content repo

```bash
git clone https://github.com/bamr87/Dodge-and-Reena-Book ../Dodge-and-Reena-Book
python3 tools/import_dodge_and_reena.py            # write pages + copy images
python3 tools/import_dodge_and_reena.py --check    # CI-style drift check
```

The importer parses `stories/dodge-and-reena-stories-v2.md`, expands the simplified illustration prompts, and assigns each embedded image to its Setup/Mystery/Resolution scene (order-preserving, token-scored — pass `--verbose` for the matching report). Scenes without art are declared `status: planned` with a deterministic output path.

## Generate missing illustrations (OpenAI)

```bash
python3 -m pip install pyyaml
export OPENAI_API_KEY=sk-...
python3 tools/generate_illustrations.py --dry-run          # list the gaps
python3 tools/generate_illustrations.py --book dodge-and-reena --limit 2
```

Renders land at each scene's declared path (landscape plates, portrait covers) using the book's `illustration_style` so the cast stays consistent. Approve a render by embedding it in the story in the content repo (and `--save-to-source` copies it there); the next import closes the loop. Story-page **preview banners** come from the zer0-image-generator's Python engine, run from this directory: `python3 ../../packages/zer0-image-generator/lib/zer0_image_generator/preview_generator.py --dry-run` (the gem's `jekyll preview-images` left with the Gemfile; PLAN G6 makes it a platform command).

## Write new stories

```bash
cd drsai && pip install -e ".[dev]"
drsai generate "a lighthouse that is afraid of the dark" --mode story --prompts
```

See [`drsai/README.md`](./drsai/README.md) for the story engine's full CLI, meter validation, and library usage. Planning documents for the platform live in [`PRD.md`](./PRD.md) and [`IMPLEMENTATION_PLAN.md`](./IMPLEMENTATION_PLAN.md).

## ABC books — the "ABC & Language" series

drsai also publishes toddler **ABC board books** — one big letter, one word, one picture per page. The words and per-letter illustration prompts are drafted by the **[zer0-CMS](https://github.com/bamr87/zer0-CMS) ABC wizard**, which exports straight into this repo. The first is [**The IT Alphabet: A is for Automation**](https://bamr87.github.io/drsai/books/it-alphabet/) — A is for Automation, B is for Backup … Z is for Zero Trust.

```bash
# From the zer0-CMS monorepo's Rails app, draft a book and export it here:
cd ../../rails
ruby bin/zer0-cms new --theme "IT systems" --slug it-alphabet \
     --art-style isometric-tech-toy --out ../sites/drsai

# Back in drsai: guard the page against its spec, then render the plates.
python3 tools/import_abc_book.py --check                       # drift check (CI)
python3 tools/generate_illustrations.py --book it-alphabet --dry-run
```

The wizard writes `pages/_books/<slug>/index.md` (`layout: book-abc`, an `alphabet:` list of {letter, word, tagline, image, prompt}) and the canonical spec sidecar `_data/abc_books/<slug>.json`. The [zer0-image-generator](https://github.com/bamr87/zer0-image-generator) plugin owns the shared art-style catalog; `generate_illustrations.py` renders each letter's text-free prompt to its declared image path. Series metadata lives in [`_data/series.yml`](./_data/series.yml).

## Repository layout

```text
_config.yml            Jekyll site (zer0-mistakes remote theme, books collection)
index.html             The library home page (bookshelf)
pages/_books/          Book collection: one folder per book, chapter per story
assets/images/books/   Illustration plates + covers (committed renders)
tools/                 import_dodge_and_reena.py · generate_illustrations.py · unwrap-prose.py
drsai/                 The Python story engine (own README, tests, PyPI packaging)
.github/workflows/     pages.yml (build+deploy+content-drift) · ci.yml (engine tests)
```
