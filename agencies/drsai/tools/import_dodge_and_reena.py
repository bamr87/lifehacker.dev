#!/usr/bin/env python3
"""Import the Dodge & Reena picture book into the drsai books collection.

Reads the canonical sources from the Dodge-and-Reena-Book repo:

  stories/dodge-and-reena-stories-v2.md                the 12 monthly stories
  illustrations/illustration-descriptions-simplified.md style tag, character
                                                        tags, 3 prompts/month
  illustrations/cover-descriptions.md                   front/back cover prompts
  images/generated/*.jpg + images/{front,back}-cover.jpg

and writes the Jekyll `books` collection consumed by the zer0-mistakes theme:

  pages/_books/dodge-and-reena/index.md                 book landing page
  pages/_books/dodge-and-reena/NN-<month>.md            one story per month
  assets/images/books/dodge-and-reena/*.jpg             copied art

Embedded story images become `book-plate` includes; every scene's generation
prompt lands in the chapter's `illustrations:` front matter so
tools/generate_illustrations.py can render missing plates with OpenAI.

Usage:
  python3 tools/import_dodge_and_reena.py [--source PATH] [--check] [--verbose]

--check exits non-zero when the committed output differs from a fresh import
(useful in CI); --verbose prints the image<->scene matching report.
"""

from __future__ import annotations

import argparse
import difflib
import json
import re
import shutil
import sys
from pathlib import Path

BOOK_SLUG = "dodge-and-reena"
BOOK_TITLE = "Deputy Dodge & Ranger Reena"
BOOK_SUBTITLE = "Adventures of a Lifetime"

MONTHS = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]

STOPWORDS = {
    "a", "an", "and", "at", "by", "for", "in", "into", "its", "my", "of",
    "on", "one", "over", "the", "to", "under", "up", "with", "you", "your",
    "little", "great", "big", "did", "where", "who", "that", "wouldnt",
}

IMG_LINE = re.compile(r"^!\[(?P<alt>[^\]]*)\]\((?P<src>[^)]+)\)\s*$")
SCENE_LINE = re.compile(
    r"^\*\*(?P<num>\d+)\s*·\s*(?P<beat>[^—]+?)\s*—\s*(?P<title>.+?)\*\*\s*(?P<prompt>.+)$"
)
MONTH_HEADING = re.compile(r"^##\s+(?P<month>\w+)\s+—\s+(?P<title>.+?)\s*$")


def yq(value: str) -> str:
    """Quote a scalar for YAML front matter (JSON strings are valid YAML)."""
    return json.dumps(value, ensure_ascii=False)


def tokens(text: str) -> set[str]:
    """Normalized comparison tokens: lowercase, plural-stripped, no stopwords."""
    words = re.findall(r"[a-z]+", text.lower())
    out = set()
    for w in words:
        if w in STOPWORDS or len(w) < 3:
            continue
        if w.endswith("ies"):
            w = w[:-3] + "i"
        elif w.endswith("es"):
            w = w[:-2]
        elif w.endswith("s") and not w.endswith("ss"):
            w = w[:-1]
        out.add(w)
    return out


# ---------------------------------------------------------------------------
# Source parsing
# ---------------------------------------------------------------------------

def parse_stories(path: Path) -> list[dict]:
    """Split stories-v2 into per-month sections with body lines and images."""
    text = path.read_text(encoding="utf-8")
    stories: list[dict] = []
    current: dict | None = None
    for line in text.splitlines():
        m = MONTH_HEADING.match(line)
        if m and m.group("month") in MONTHS:
            current = {
                "month": m.group("month"),
                "title": m.group("title"),
                "lines": [],
            }
            stories.append(current)
            continue
        if current is not None:
            current["lines"].append(line)

    for story in stories:
        lines = story["lines"]
        # Drop the closing "*The End*" marker and section separators — the
        # book-story layout renders its own "The End" flourish.
        lines = [
            ln for ln in lines
            if ln.strip() not in {"*The End*", "---"}
        ]
        # Trim leading/trailing blank lines.
        while lines and not lines[0].strip():
            lines.pop(0)
        while lines and not lines[-1].strip():
            lines.pop()
        story["lines"] = lines
        story["images"] = [
            IMG_LINE.match(ln).groupdict()
            for ln in lines
            if IMG_LINE.match(ln)
        ]
    if len(stories) != 12:
        raise SystemExit(f"expected 12 monthly stories, found {len(stories)}")
    return stories


def parse_prompts(path: Path) -> tuple[str, list[dict], dict[str, list[dict]]]:
    """Extract the style tag, character tags, and per-month scene prompts."""
    text = path.read_text(encoding="utf-8")
    lines = text.splitlines()

    style_tag = ""
    characters: list[dict] = []
    scenes: dict[str, list[dict]] = {m: [] for m in MONTHS}

    section = None
    month = None
    for line in lines:
        if line.startswith("## "):
            heading = line[3:].strip()
            m = MONTH_HEADING.match(line)
            if m and m.group("month") in MONTHS:
                section, month = "month", m.group("month")
            elif heading.startswith("Style Tag"):
                section, month = "style", None
            elif heading.startswith("Character Tags"):
                section, month = "characters", None
            else:
                section, month = None, None
            continue
        if section == "style" and line.strip() and not style_tag:
            style_tag = line.strip()
        elif section == "characters":
            cm = re.match(r"^-\s+\*\*(?P<name>[^*]+)\*\*\s+—\s+(?P<tag>.+)$", line)
            if cm:
                characters.append(
                    {"name": cm.group("name").strip(), "tag": cm.group("tag").strip()}
                )
        elif section == "month":
            sm = SCENE_LINE.match(line)
            if sm:
                scenes[month].append(
                    {
                        "beat": sm.group("beat").strip(),
                        "title": sm.group("title").strip(),
                        "prompt": sm.group("prompt").strip(),
                    }
                )

    missing = [m for m in MONTHS if len(scenes[m]) != 3]
    if not style_tag or missing:
        raise SystemExit(f"prompt parse failed (style={bool(style_tag)}, incomplete months={missing})")
    return style_tag, characters, scenes


def parse_cover_prompts(path: Path) -> dict[str, str]:
    """Grab the primary (Option A) front and back cover prompts."""
    text = path.read_text(encoding="utf-8")
    covers: dict[str, str] = {}
    side = None
    option_a = False
    for line in text.splitlines():
        if line.startswith("## Front Cover"):
            side, option_a = "front", False
        elif line.startswith("## Back Cover"):
            side, option_a = "back", False
        elif line.startswith("## "):
            side, option_a = None, False
        elif line.startswith("### "):
            option_a = "Option A" in line
        elif side and option_a and line.strip() and not line.startswith(("*", "#", "-")):
            # The prompt is the long plain paragraph inside Option A.
            if side not in covers or len(line.strip()) > len(covers[side]):
                covers[side] = line.strip()
    return covers


# ---------------------------------------------------------------------------
# Image <-> scene matching
# ---------------------------------------------------------------------------

def match_scenes(story: dict, month_scenes: list[dict]) -> list[dict | None]:
    """Assign each embedded image (in story order) to a scene (in beat order).

    Images appear in narrative order and scenes are ordered Setup -> Mystery ->
    Resolution, so the assignment must preserve order. With k images and 3
    scenes we score every order-preserving subset by token overlap between the
    filename slug and the scene's title+prompt, and keep the best.
    Returns a list the length of month_scenes: the image dict or None.
    """
    imgs = story["images"]
    k, n = len(imgs), len(month_scenes)
    if k == 0:
        return [None] * n

    def slug_tokens(img: dict) -> set[str]:
        stem = Path(img["src"]).stem  # e.g. 01-january-sunrise-race
        stem = re.sub(r"^\d+-[a-z]+-", "", stem)
        return tokens(stem.replace("-", " ")) | tokens(img["alt"])

    def scene_tokens(scene: dict) -> set[str]:
        return tokens(scene["title"] + " " + scene["prompt"])

    from itertools import combinations

    best, best_score = None, -1.0
    for combo in combinations(range(n), min(k, n)):
        score = sum(
            len(slug_tokens(imgs[i]) & scene_tokens(month_scenes[s]))
            for i, s in enumerate(combo)
        )
        if score > best_score:
            best, best_score = combo, score

    assignment: list[dict | None] = [None] * n
    for i, s in enumerate(best or ()):
        assignment[s] = imgs[i]
    return assignment


# ---------------------------------------------------------------------------
# Output rendering
# ---------------------------------------------------------------------------

def site_image(src: str) -> str:
    """Map a source-repo image path to the drsai site asset path."""
    return f"/assets/images/books/{BOOK_SLUG}/{Path(src).name}"


def plate_include(alt: str, src: str) -> str:
    safe_alt = alt.replace('"', "'").strip()
    return (
        "{% include components/book-plate.html "
        f'src="{site_image(src)}" alt="{safe_alt}" %}}'
    )


def first_sentence(lines: list[str]) -> str:
    for ln in lines:
        ln = ln.strip()
        if not ln or IMG_LINE.match(ln) or ln.startswith(("#", ">", "*")):
            continue
        plain = re.sub(r"[*_`]", "", ln)
        m = re.match(r"(.+?[.!?])(\s|$)", plain)
        sentence = (m.group(1) if m else plain).strip()
        return sentence[:157] + "..." if len(sentence) > 160 else sentence
    return ""


def render_chapter(story: dict, chapter: int, scenes: list[dict],
                   assignment: list[dict | None]) -> str:
    month = story["month"]
    body_lines: list[str] = []
    for ln in story["lines"]:
        m = IMG_LINE.match(ln)
        body_lines.append(plate_include(m.group("alt"), m.group("src")) if m else ln)

    preview = next(
        (site_image(img["src"]) for img in assignment if img),
        f"/assets/images/books/{BOOK_SLUG}/front-cover.jpg",
    )

    fm: list[str] = ["---"]
    fm.append(f"title: {yq(story['title'])}")
    fm.append(f"book: {BOOK_SLUG}")
    fm.append(f"chapter: {chapter}")
    fm.append(f"chapter_label: {yq(month)}")
    fm.append(f"description: {yq(first_sentence(story['lines']))}")
    fm.append(f"preview: {yq(preview)}")
    fm.append(f"permalink: /books/{BOOK_SLUG}/{month.lower()}/")
    fm.append("illustrations:")
    for scene, img in zip(scenes, assignment):
        fm.append(f"  - beat: {yq(scene['beat'])}")
        fm.append(f"    title: {yq(scene['title'])}")
        fm.append(f"    prompt: {yq(scene['prompt'])}")
        if img:
            fm.append(f"    image: {yq(site_image(img['src']))}")
        else:
            planned = f"/assets/images/books/{BOOK_SLUG}/{chapter:02d}-{month.lower()}-{slugify(scene['title'])}.jpg"
            fm.append(f"    image: {yq(planned)}")
            fm.append("    status: planned")
    fm.append("---")
    return "\n".join(fm) + "\n\n" + "\n".join(body_lines) + "\n"


def slugify(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def render_index(style_tag: str, characters: list[dict],
                 covers: dict[str, str]) -> str:
    fm: list[str] = ["---"]
    fm.append(f"title: {yq(BOOK_TITLE)}")
    fm.append(f"subtitle: {yq(BOOK_SUBTITLE)}")
    fm.append("layout: book")
    fm.append(f"book: {BOOK_SLUG}")
    fm.append('author: "Amr Abdel"')
    fm.append('illustrator: "OpenAI image models, art-directed by the illustration bible"')
    fm.append('audience: "Ages 4–8"')
    fm.append("status: complete")
    fm.append("synopsis: >-")
    fm.append("  Deputy Dodge, Ranger Reena, and the gentle giant dog Thunderpaws Hans")
    fm.append("  solve a year of cozy mysteries in the desert town of Dusty Gulch —")
    fm.append("  one story for every month, from snowy January tracks to a December")
    fm.append("  star that would not shine.")
    fm.append(f"cover_image: {yq(f'/assets/images/books/{BOOK_SLUG}/front-cover.jpg')}")
    fm.append(f"back_cover_image: {yq(f'/assets/images/books/{BOOK_SLUG}/back-cover.jpg')}")
    fm.append(f"preview: {yq(f'/assets/images/books/{BOOK_SLUG}/front-cover.jpg')}")
    fm.append("description: >-")
    fm.append("  A children's picture book of twelve gentle desert-town mysteries,")
    fm.append("  written for read-aloud and illustrated with AI-generated art.")
    fm.append("generator: >-")
    fm.append("  Stories are drafted and refined in the Dodge-and-Reena-Book repo and")
    fm.append("  imported by tools/import_dodge_and_reena.py; illustrations are")
    fm.append("  rendered with the OpenAI Images API from the prompts in each story's")
    fm.append("  front matter (tools/generate_illustrations.py).")
    fm.append(f"illustration_style: {yq(style_tag)}")
    fm.append("cover_prompts:")
    for side in ("front", "back"):
        if covers.get(side):
            fm.append(f"  {side}: {yq(covers[side])}")
    fm.append("characters:")
    for ch in characters:
        fm.append(f"  - name: {yq(ch['name'])}")
        fm.append(f"    tag: {yq(ch['tag'])}")
    fm.append(f"permalink: /books/{BOOK_SLUG}/")
    fm.append("---")

    body = f"""
**{BOOK_TITLE}: {BOOK_SUBTITLE}** follows the bravest young deputy in the West, his best friend Ranger Reena, and their animal companions through one full year in Dusty Gulch — a friendly old-west desert town of wooden storefronts, red-rock mesas, and big turquoise skies. Every month brings a small, kind mystery: wiggly tracks in the snow, a masked snack thief, a star that will not shine. Every mystery ends warm.

## Meet the friends

{chr(10).join(f"- **{c['name']}** — {c['tag']}" for c in characters[:9])}

## How this book is made

This book is the test content for the [drsai children's book platform](https://github.com/bamr87/drsai). The stories live in the [Dodge-and-Reena-Book](https://github.com/bamr87/Dodge-and-Reena-Book) repo and are imported here by `tools/import_dodge_and_reena.py`. Each story page carries the exact image prompts that produced its illustrations; missing scenes are rendered with the OpenAI Images API by `tools/generate_illustrations.py`, using the shared style and character bible so the cast looks the same on every page.
"""
    return "\n".join(fm) + "\n" + body.lstrip("\n")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--source", default="../Dodge-and-Reena-Book",
                    help="path to the Dodge-and-Reena-Book checkout")
    ap.add_argument("--check", action="store_true",
                    help="verify committed output matches a fresh import")
    ap.add_argument("--verbose", action="store_true",
                    help="print the image<->scene matching report")
    args = ap.parse_args()

    repo = Path(__file__).resolve().parent.parent
    source = (repo / args.source).resolve() if not Path(args.source).is_absolute() else Path(args.source)
    if not source.is_dir():
        raise SystemExit(f"source repo not found: {source}")

    stories = parse_stories(source / "stories" / "dodge-and-reena-stories-v2.md")
    style_tag, characters, scenes = parse_prompts(
        source / "illustrations" / "illustration-descriptions-simplified.md")
    covers = parse_cover_prompts(source / "illustrations" / "cover-descriptions.md")

    out_dir = repo / "pages" / "_books" / BOOK_SLUG
    img_dir = repo / "assets" / "images" / "books" / BOOK_SLUG

    outputs: dict[Path, str] = {out_dir / "index.md": render_index(style_tag, characters, covers)}
    for i, story in enumerate(stories, start=1):
        assignment = match_scenes(story, scenes[story["month"]])
        if args.verbose:
            for scene, img in zip(scenes[story["month"]], assignment):
                mark = Path(img["src"]).name if img else "(planned)"
                print(f"  {story['month']:<10} {scene['beat']:<10} {scene['title']:<40} -> {mark}")
        outputs[out_dir / f"{i:02d}-{story['month'].lower()}.md"] = render_chapter(
            story, i, scenes[story["month"]], assignment)

    if args.check:
        dirty = []
        for path, content in outputs.items():
            if not path.exists() or path.read_text(encoding="utf-8") != content:
                dirty.append(str(path.relative_to(repo)))
                if args.verbose and path.exists():
                    diff = difflib.unified_diff(
                        path.read_text(encoding="utf-8").splitlines(),
                        content.splitlines(), lineterm="")
                    print("\n".join(list(diff)[:40]))
        if dirty:
            print("stale imports (re-run tools/import_dodge_and_reena.py):")
            print("\n".join(f"  {p}" for p in dirty))
            return 1
        print(f"ok: {len(outputs)} files match the source repo")
        return 0

    out_dir.mkdir(parents=True, exist_ok=True)
    img_dir.mkdir(parents=True, exist_ok=True)
    for path, content in outputs.items():
        path.write_text(content, encoding="utf-8")
    copied = 0
    for src in sorted((source / "images" / "generated").glob("*.jpg")):
        shutil.copy2(src, img_dir / src.name)
        copied += 1
    for name in ("front-cover.jpg", "back-cover.jpg"):
        src = source / "images" / name
        if src.exists():
            shutil.copy2(src, img_dir / name)
            copied += 1
    print(f"wrote {len(outputs)} pages, copied {copied} images -> {out_dir.relative_to(repo)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
