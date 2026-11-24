# scripts/agencies

> The two tools of an agency's life here: `import.rb` brings its site tree into `agencies/`, and `promote.rb` publishes it as a collection of this site.

`import.rb` exports the tracked files of one commit of a source repository into a registered site path, drops what this repository ignores, holds Markdown to one paragraph per line, and writes the provenance into [`_data/agencies.yml`](../../_data/agencies.yml). It is stdlib Ruby (2.6 or newer) and needs `git`, `tar` and `python3` on the path. It fetches nothing: point `--from` at a checkout you cloned or pulled yourself.

```bash
ruby scripts/agencies/import.rb <site path> --from <git checkout> [--ref <commit>] [--date YYYY-MM-DD]
ruby scripts/agencies/import.rb <site path> --from <git checkout> --verify
ruby scripts/agencies/import.rb --digest <site path>
```

`promote.rb` runs once per site, and only for one whose custody is `home`. It moves the tree's pages to `pages/_<collection>/` and its images to `assets/images/<collection>/` with `git mv`, rewrites the URL base and the byline keys the pages carried, and writes a `published:` block on the site's registry row. It does not edit `_config.yml`: declaring the collection is a reviewed, hand-written change.

```bash
ruby scripts/agencies/promote.rb <site path> --pages <dir in the tree> --collection <name> --url /<name>/ \
     [--url-from /old/base/] [--author old=new ...] [--images <dir in the tree>]
```

The rules for agencies, and how to add or publish one, are in [`agencies/README.md`](../../agencies/README.md). The registry is checked by [`scripts/ci/lint_agencies.rb`](../ci/lint_agencies.rb), which runs in the harness.
