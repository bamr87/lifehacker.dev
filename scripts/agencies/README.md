# scripts/agencies

> The one tool that brings a sub-agency's site tree into `agencies/`, and what it records.

`import.rb` exports the tracked files of one commit of a source repository into a registered site path, drops what this repository ignores, holds Markdown to one paragraph per line, and writes the provenance into [`_data/agencies.yml`](../../_data/agencies.yml). It is stdlib Ruby (2.6 or newer) and needs `git`, `tar` and `python3` on the path. It fetches nothing: point `--from` at a checkout you cloned or pulled yourself.

```bash
ruby scripts/agencies/import.rb <site path> --from <git checkout> [--ref <commit>] [--date YYYY-MM-DD]
ruby scripts/agencies/import.rb <site path> --from <git checkout> --verify
ruby scripts/agencies/import.rb --digest <site path>
```

The rules for agencies, and how to add one, are in [`agencies/README.md`](../../agencies/README.md). The registry is checked by [`scripts/ci/lint_agencies.rb`](../ci/lint_agencies.rb), which runs in the harness.
