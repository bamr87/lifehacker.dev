# Agencies

> The site trees of lifehacker.dev's sub-agencies: what an agency is, how a tree gets here, which rules apply to it, and what is not built yet.

lifehacker.dev is the fleet's news agency and its content source. zer0-CMS is the platform that manages, renders and publishes that content. Each directory here is a sub-agency: a named desk with its own beat, its own voice and one or more whole sites. The decision and its reasons are in [ADR 0002](../docs/adr/0002-agencies.md); the rule set is [constitution § 9](../docs/constitution.md#9-agencies).

## What is here

The registry [`_data/agencies.yml`](../_data/agencies.yml) is the list of record: every agency, every site, where each came from and who writes it. Do not keep a second list here; read that file.

```text
agencies/
├── 1987/             single-site agencies: the site is the directory
├── drsai/
├── irony-works/
├── wargames/         published: its pages are in pages/_wargames/; this is its back office
├── year-of-ai/       networks: a hub and one directory per member
│   ├── hub/
│   └── 1776/ … 2014/
└── ai-world-view/
    ├── hub/
    └── china/ japan/ north-korea/ south-korea/
```

A site tree is whole. It carries its content, its own site configuration and its own tooling, as its source repository had them, and nothing in it assumes it is the root of a git repository. Where a tree has its own `AGENTS.md` or `README.md`, that file governs the tree: read it before changing anything inside. Those guides were moved unedited, so some still name commands from where the tree used to live; see the last section.

## Rules

- **Register first, then import.** A tree arrives, or is refreshed, only through [`scripts/agencies/import.rb`](../scripts/agencies/import.rb), which refuses a path the registry does not list. Never copy files in by hand.
- **One write side per site.** `custody: home` means the tree is written here and nowhere else. `custody: mirror` means its source repository is still written, so this copy is refreshed from it and never edited: an edit here is lost at the next refresh.
- **Nothing here is part of the lifehacker.dev site.** `agencies` is in `_config.yml` `exclude:`. GitHub Pages builds the whole repository, so removing that line would publish every agency page on the apex domain. An agency becomes part of the site only by being promoted into a collection, which is its own reviewed change ([Publishing an agency](#publishing-an-agency)).
- **The machinery inside a tree does not run here.** A tree's `.github/workflows/` are reference: GitHub runs workflows only from the repository root. Its `.claude/` commands and its scripts work from inside the tree, as they did at the source.
- **Which gates apply.** The human merge gate, the secret rule and one paragraph per line apply to every file here, and `scripts/ci/lint_agencies.rb` checks the registry against the trees. The apex site's brand, front-matter, preview and wire gates read `pages/` only; an agency keeps its own voice.

## Bringing a tree in, or refreshing one

```bash
ruby scripts/agencies/import.rb agencies/year-of-ai/2009 --from ~/src/year-of-ai/2009            # export HEAD of that checkout
ruby scripts/agencies/import.rb agencies/year-of-ai/2009 --from ~/src/year-of-ai/2009 --verify   # compare, write nothing
ruby scripts/agencies/import.rb --digest agencies/year-of-ai/2009                                # the digest of what is on disk
ruby scripts/ci/lint_agencies.rb                                                                 # registry ↔ trees ↔ the build exclude
```

The import exports the tracked files of one commit, byte for byte, and writes the commit, the date, the file count and a tree digest into the registry. Two differences from the source are possible, and both are recorded on the site's row: a file this repository's ignore rules refuse is dropped (`source.dropped`), and Markdown is held to one paragraph per line by `tools/unwrap-prose.py` (`source.reflowed`, a count). `--verify` applies the same two steps before it compares, so "identical" means identical to the source after them.

To add an agency: add its entry to the registry (key, name, beat, kind, and each site's key, path, custody and `source.repo` / `source.path`), run the import for each site, then run the lint.

## Publishing an agency

An agency is published as a collection of this site, under its own path ([ADR 0003](../docs/adr/0003-agencies-as-collections.md)). It is not news: its pages stay out of the news sections and the feed. [`scripts/agencies/promote.rb`](../scripts/agencies/promote.rb) does the move once, and only for a site whose custody is `home`:

```bash
ruby scripts/agencies/promote.rb agencies/wargames --pages overthewire --collection wargames --url /wargames/ \
     --url-from /docs/wargames/ --author bamr87=amr --images assets/images/wargames
```

It moves the pages to `pages/_<collection>/` and the images to `assets/images/<collection>/` with `git mv`, rewrites the URL base the pages carried and their byline keys, and writes a `published:` block on the site's registry row. Three things are then done by hand: declare the collection and its `defaults:` scope in `_config.yml`, add the agency to the Agencies menu in `_data/navigation/main.yml`, and run the harness. The [agencies index](../pages/agencies.md), the sitemap, the tags page and the gates read the registry and need no edit. What stays under `agencies/<agency>/` is the back office: guides, licence, tooling and the old site configuration.

## What is not built yet

- **Publishing the rest.** Wargames is published, at `/wargames/`. The others are held: the sites with a `live_url` in the registry are still served by their source repositories, and 1987, drsai and irony-works are not public anywhere today.
- **Cutover of the mirrors.** The two networks still grow in their own organizations. Until the maintainer moves a site's write side here and marks it `home`, refresh it; do not edit it.
- **Building the held trees that came from zer0-CMS.** The guides of 1987 and drsai still tell you to run `python3 ../../tools/jekyll_theme.py build <site>`, and drsai's `_config.yml` names zer0-CMS's image generator by a relative path. Neither exists here: those were zer0-CMS's tools, and it cannot build a checkout outside its own repository yet. (`../../tools/unwrap-prose.py` in the same guides does resolve, to this repository's copy.) 1987 has no `_config.yml`, so the platform cannot register it either.
- **The Wargames refresh.** Its sync tool (`agencies/wargames/scripts/docs-aggregator/`) still writes the old `/docs/wargames/…` permalinks and directory layout. Change it before the next refresh from OverTheWire; the note at the top of the tree's guides says what.
- **Lighter CI for agency-only changes.** A pull request that touches only `agencies/` runs the full pipeline, because the change classifier does not know the directory yet.
