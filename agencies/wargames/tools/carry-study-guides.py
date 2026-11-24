#!/usr/bin/env python3
"""
carry-study-guides.py — re-apply this site's own additions to freshly synced pages.

The docs aggregator regenerates every page under ``overthewire/**`` from the
upstream OverTheWire repo. That discards what this site adds on top of the
vendored text:

  * the "Study guide" section at the end of each page, fenced by the
    ``<!-- study-guide:start -->`` / ``<!-- study-guide:end -->`` markers, and
  * front matter the site owns: the one-sentence ``description`` / ``excerpt``
    (the aggregator's derived value is truncated body text), ``title``,
    ``author``, ``draft``, ``keywords``, the game ``categories``/``tags`` and the
    original ``date``.

Run this after ``aggregate_docs.sh`` (and ``unwrap-prose.py --write``) on the
staged pages, before moving them into ``overthewire/``. For every page in
NEW_DIR it finds the same page in the current ``overthewire/`` tree and, in
place on the NEW_DIR copy:

  * keeps the old page's front matter (same keys, same order), except that
    upstream-owned provenance keys (``source_*``, ``license``, ``permalink``,
    ``nav_order``, ``sidebar_label``, ``toc_sticky``) are taken from the fresh
    page so upstream changes propagate, and keys that only the fresh page has
    are appended;
  * keeps the old ``lastmod`` when the vendored text did not change, so a re-sync
    with no upstream changes produces no diff; and
  * re-attaches the old page's study guide.

Usage:
  carry-study-guides.py NEW_DIR [--old-dir overthewire]

NEW_DIR is the refreshed tree, laid out like ``overthewire/`` (for example
``pages/_docs/wargames/overthewire``). Pages with no counterpart, or whose
counterpart has no study guide, are listed and left unchanged: they need a guide
(and the site-owned front matter) written for them.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

import yaml

START = "<!-- study-guide:start -->"
END = "<!-- study-guide:end -->"
TOP_KEY = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):")
FRONT = re.compile(r"\A---\n(.*?)\n---\n", re.S)

# Front matter the aggregator derives from upstream on every run; the fresh value wins.
UPSTREAM_OWNED = {
    "source_repo", "source_url", "source_name", "license",
    "permalink", "nav_order", "sidebar_label", "toc_sticky",
}


def split(text: str) -> tuple[list[tuple[str, list[str]]], str]:
    """Split a page into ordered front matter blocks [(key, lines)] and the body."""
    m = FRONT.match(text)
    if not m:
        raise ValueError("no front matter")
    blocks: list[tuple[str, list[str]]] = []
    for line in m.group(1).split("\n"):
        k = TOP_KEY.match(line)
        if k:
            blocks.append((k.group(1), [line]))
        elif blocks:
            blocks[-1][1].append(line)  # continuation line or list item of the previous key
        else:
            raise ValueError("front matter does not start with a key")
    return blocks, text[m.end():]


def same_value(a: list[str], b: list[str]) -> bool:
    """True when two front matter blocks parse to the same value (ignores quoting style)."""
    return yaml.safe_load("\n".join(a)) == yaml.safe_load("\n".join(b))


def strip_guide(body: str) -> str:
    s = body.find(START)
    if s == -1:
        return body
    e = body.find(END, s)
    if e == -1:
        raise ValueError("unterminated study-guide block")
    before = body[:s]
    if before.endswith("\n\n"):
        before = before[:-2]  # remove only the blank line we added, never upstream text
    return before + "\n" + body[e + len(END):].lstrip("\n")


def carry(old_text: str, new_text: str) -> str | None:
    """Return ``new_text`` with the old page's guide and site-owned front matter, or None if the old page has no guide."""
    old_blocks, old_body = split(old_text)
    s = old_body.find(START)
    if s == -1:
        return None
    e = old_body.find(END, s)
    if e == -1:
        raise ValueError("unterminated study-guide block in the old page")
    guide = old_body[s:e + len(END)]

    new_blocks, new_body = split(new_text)
    fresh = dict(new_blocks)
    text_changed = strip_guide(old_body).strip() != strip_guide(new_body).strip()

    merged: list[str] = []
    seen = set()
    for key, lines in old_blocks:
        seen.add(key)
        if key in fresh and not same_value(lines, fresh[key]) and (
            key in UPSTREAM_OWNED or (key == "lastmod" and text_changed)
        ):
            merged += fresh[key]
        else:
            merged += lines  # also keeps the old quoting when only the formatting differs
    for key, lines in new_blocks:
        if key not in seen:
            merged += lines

    yaml.safe_load("\n".join(merged))  # fail loudly on broken front matter
    lead = old_body[: len(old_body) - len(old_body.lstrip("\n"))]  # keep the old page's gap after the front matter
    body = lead + strip_guide(new_body).strip("\n")
    return "---\n" + "\n".join(merged) + "\n---\n" + body + "\n\n" + guide + "\n"


def main() -> int:
    ap = argparse.ArgumentParser(description="Re-apply study guides and site-owned front matter to freshly synced pages.")
    ap.add_argument("new_dir", type=Path, help="refreshed tree, laid out like overthewire/")
    ap.add_argument("--old-dir", type=Path, default=Path("overthewire"),
                    help="current tree that holds the study guides (default: overthewire)")
    args = ap.parse_args()

    if not args.new_dir.is_dir() or not args.old_dir.is_dir():
        print("both NEW_DIR and --old-dir must be directories", file=sys.stderr)
        return 2

    done, skipped = 0, []
    for new_path in sorted(args.new_dir.rglob("*.md")):
        rel = new_path.relative_to(args.new_dir)
        old_path = args.old_dir / rel
        if not old_path.exists():
            skipped.append(f"{rel}: no counterpart in {args.old_dir}")
            continue
        merged = carry(old_path.read_text(encoding="utf-8"), new_path.read_text(encoding="utf-8"))
        if merged is None:
            skipped.append(f"{rel}: current page has no study guide")
            continue
        new_path.write_text(merged, encoding="utf-8")
        done += 1

    print(f"carried the study guide and site-owned front matter onto {done} page(s)")
    for line in skipped:
        print(f"  skipped {line}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
