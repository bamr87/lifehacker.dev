# lifehacker.dev tools

> The operator tools vendored into this repository; none of them ship to the site.

Operator scripts for this repository. Nothing here ships to users. Both are vendored from the [bamr87 hub](https://github.com/bamr87/bamr87/tree/main/tools): change them there and re-vendor, never edit them here.

| Where | What |
| --- | --- |
| [`docs_index.py`](docs_index.py) | docs_index.py — generate the docs index in `docs/README.md` from each document's summary line (`--write`, `--check`, `--lint`) |
| [`unwrap-prose.py`](unwrap-prose.py) | unwrap-prose.py — join soft-wrapped prose lines so each paragraph is one line |
