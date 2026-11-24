#!/usr/bin/env python3
"""Render missing book illustrations with the OpenAI Images API.

Walks the Jekyll books collection (pages/_books/**/*.md), reads each page's
front matter, and generates every declared illustration whose image file does
not exist yet:

  - story pages: each `illustrations:` entry ({beat, title, prompt, image})
  - book index pages: `cover_prompts.front` / `cover_prompts.back` for a
    missing `cover_image` / `back_cover_image`
  - ABC board books (`book-abc` layout): each `alphabet:` entry
    ({letter, word, prompt, image}) plus the `cover_prompt` / `cover_image`.
    These prompts are already fully expanded by the zer0-CMS ABC wizard.

Prompt composition mirrors the book's illustration bible: when a book defines
`illustration_style` and a scene prompt opens with the shorthand
"Cozy illustration storybook:", the shorthand is expanded to the full style
tag so every render shares the same look.

The declared image path is the contract: the importer plans paths for scenes
that have no art yet (`status: planned`), and this tool fills them in. It
NEVER edits front matter — once a render is approved, embed it in the story in
the book's content repo and re-run the importer, which keeps the content repo
canonical.

Requires: python3.9+, PyYAML, OPENAI_API_KEY (only when something needs
rendering). Model: --model / DRSAI_IMAGE_MODEL, default gpt-image-2
(dall-e-3 also works but always outputs PNG bytes).

Usage:
  python3 tools/generate_illustrations.py --dry-run
  python3 tools/generate_illustrations.py --book dodge-and-reena --limit 2
  python3 tools/generate_illustrations.py --save-to-source ../Dodge-and-Reena-Book
"""

from __future__ import annotations

import argparse
import base64
import json
import os
import shutil
import sys
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover
    raise SystemExit("PyYAML is required: python3 -m pip install pyyaml")

OPENAI_IMAGES_URL = "https://api.openai.com/v1/images/generations"
DEFAULT_MODEL = os.environ.get("DRSAI_IMAGE_MODEL", "gpt-image-2")
STYLE_SHORTHAND = "Cozy illustration storybook:"

PLATE_SIZE = "1536x1024"   # landscape story plates
COVER_SIZE = "1024x1536"   # portrait covers
ABC_PLATE_SIZE = "1024x1024"   # square ABC letter cards (big centered subject)


@dataclass
class Job:
    book: str
    label: str
    prompt: str
    out_path: Path
    size: str


def front_matter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end < 0:
        return {}
    return yaml.safe_load(text[3:end]) or {}


def expand_prompt(prompt: str, style: str | None) -> str:
    if style and prompt.startswith(STYLE_SHORTHAND):
        # The style tag itself documents the shorthand; strip that meta-note.
        tag = style.split(" Every prompt below", 1)[0].strip()
        return f"{tag} {prompt[len(STYLE_SHORTHAND):].strip()}"
    return prompt


def collect_jobs(repo: Path, only_book: str | None) -> list[Job]:
    jobs: list[Job] = []
    books_dir = repo / "pages" / "_books"
    if not books_dir.is_dir():
        raise SystemExit(f"no books collection at {books_dir}")

    styles: dict[str, str] = {}
    pages = sorted(books_dir.rglob("*.md"))
    for page in pages:
        fm = front_matter(page)
        if fm.get("layout") == "book" and fm.get("book") and fm.get("illustration_style"):
            styles[fm["book"]] = fm["illustration_style"]

    for page in pages:
        fm = front_matter(page)
        book = fm.get("book")
        if not book or (only_book and book != only_book):
            continue
        style = styles.get(book)

        # ABC / alphabet board books carry an `alphabet:` list; each entry's
        # prompt is already fully composed by the zer0-CMS wizard, so no style
        # shorthand expansion applies. The single cover renders portrait.
        if fm.get("alphabet"):
            cover_prompt, cover_image = fm.get("cover_prompt"), fm.get("cover_image")
            if cover_prompt and cover_image:
                out = repo / cover_image.lstrip("/")
                if not out.exists():
                    jobs.append(Job(book, "cover", cover_prompt, out, COVER_SIZE))
            for entry in fm.get("alphabet") or []:
                prompt, image = entry.get("prompt"), entry.get("image")
                if not prompt or not image:
                    continue
                out = repo / image.lstrip("/")
                if out.exists():
                    continue
                label = f"{entry.get('letter', '?')} is for {entry.get('word', '')}".strip()
                jobs.append(Job(book, label, prompt, out, ABC_PLATE_SIZE))
            continue

        if fm.get("layout") == "book":
            covers = fm.get("cover_prompts") or {}
            for side, key in (("front", "cover_image"), ("back", "back_cover_image")):
                prompt, image = covers.get(side), fm.get(key)
                if prompt and image:
                    out = repo / image.lstrip("/")
                    if not out.exists():
                        jobs.append(Job(book, f"{side} cover", prompt, out, COVER_SIZE))
            continue

        for ill in fm.get("illustrations") or []:
            prompt, image = ill.get("prompt"), ill.get("image")
            if not prompt or not image:
                continue
            out = repo / image.lstrip("/")
            if out.exists():
                continue
            label = " — ".join(x for x in (ill.get("beat"), ill.get("title")) if x)
            jobs.append(Job(book, f"{page.stem}: {label}", expand_prompt(prompt, style), out, PLATE_SIZE))
    return jobs


def render(job: Job, model: str, api_key: str, timeout: int) -> bytes:
    payload: dict = {"model": model, "prompt": job.prompt, "size": job.size, "n": 1}
    if model.startswith("gpt-image"):
        payload["output_format"] = job.out_path.suffix.lstrip(".").replace("jpg", "jpeg") or "jpeg"
    else:  # dall-e-* return URLs unless b64 is requested; bytes are PNG
        payload["response_format"] = "b64_json"
    req = urllib.request.Request(
        OPENAI_IMAGES_URL,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", "replace")[:500]
        raise RuntimeError(f"OpenAI API error {e.code}: {detail}") from e
    b64 = data["data"][0].get("b64_json")
    if not b64:
        raise RuntimeError("no b64_json in response (URL-only response?)")
    return base64.b64decode(b64)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--book", help="only this book slug")
    ap.add_argument("--model", default=DEFAULT_MODEL,
                    help=f"image model (default: {DEFAULT_MODEL})")
    ap.add_argument("--limit", type=int, default=0, help="render at most N images")
    ap.add_argument("--timeout", type=int, default=300, help="per-image timeout seconds")
    ap.add_argument("--dry-run", action="store_true", help="list what would render")
    ap.add_argument("--save-to-source", metavar="PATH",
                    help="also copy renders into <PATH>/images/generated/")
    args = ap.parse_args()

    repo = Path(__file__).resolve().parent.parent
    jobs = collect_jobs(repo, args.book)
    if args.limit:
        jobs = jobs[: args.limit]

    if not jobs:
        print("nothing to render — every declared illustration exists")
        return 0

    print(f"{len(jobs)} illustration(s) missing:")
    for job in jobs:
        print(f"  [{job.book}] {job.label} -> {job.out_path.relative_to(repo)} ({job.size})")
    if args.dry_run:
        return 0

    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        raise SystemExit("OPENAI_API_KEY is required to render (set it or use --dry-run)")

    failures = 0
    for i, job in enumerate(jobs, 1):
        print(f"[{i}/{len(jobs)}] rendering {job.label} ...", flush=True)
        try:
            png = render(job, args.model, api_key, args.timeout)
        except Exception as e:  # keep going; report at the end
            failures += 1
            print(f"  FAILED: {e}", file=sys.stderr)
            continue
        job.out_path.parent.mkdir(parents=True, exist_ok=True)
        job.out_path.write_bytes(png)
        print(f"  wrote {job.out_path.relative_to(repo)} ({len(png) // 1024} KiB)")
        if args.save_to_source:
            src_dir = Path(args.save_to_source).expanduser() / "images" / "generated"
            if src_dir.is_dir():
                shutil.copy2(job.out_path, src_dir / job.out_path.name)
                print(f"  copied to {src_dir / job.out_path.name}")

    if failures:
        print(f"{failures} render(s) failed", file=sys.stderr)
        return 1
    print("done — review the renders, embed approved plates in the content "
          "repo's stories, then re-run tools/import_dodge_and_reena.py")
    return 0


if __name__ == "__main__":
    sys.exit(main())
