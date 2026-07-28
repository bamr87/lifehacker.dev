#!/usr/bin/env python3
"""claude_svg_banner — the `claude` rung of the preview-image capability ladder.

Claude AUTHORS a content-aware SVG banner for a Jekyll article (no raster
model, no rasterizer): the article's title/description/body excerpt plus the
site's configured art direction go to the Messages API, and the returned
vector drawing — sanitized, accessibility-labelled, banner-sized — is
committed as `assets/images/previews/<slug>.svg` with the `preview:` front
matter stamped, exactly like the zer0-image-generator engine's own output.

This file is a COMPANION to that engine, not a fork of it: it locates the
gem's single-file engine (`preview_generator.py`) and imports it as a library,
reusing its credential chain (CLAUDE_CODE_OAUTH_TOKEN → ANTHROPIC_AUTH_TOKEN →
ANTHROPIC_API_KEY → logged-in `claude` CLI), its SVG sanitizer, its slug and
front-matter writers, and its retry/thinking/effort request shape — so a
banner produced here is byte-contract-compatible with one produced by the
engine's `local` provider, just drawn by Claude instead of a template.

Why it exists: the published engine (<= 0.6.x) has no `claude` renderer and
error-exits on the `provider: auto` capability ladder documented in
`_config.yml preview_images:`. Until the ladder lands upstream
(bamr87/zer0-image-generator), the wrapper script resolves the ladder and
dispatches the claude rung here. The same file is vendored, unchanged, under
`scripts/` in every fleet content repo and org hub — keep the copies
identical.

Usage (from the Jekyll site root):
    python3 scripts/claude_svg_banner.py --file pages/_posts/hacks/my-post.md
    python3 scripts/claude_svg_banner.py --changed          # git-new/modified .md
    python3 scripts/claude_svg_banner.py --scan --collection posts
    python3 scripts/claude_svg_banner.py --scan --dry-run --verbose

Engine discovery (first hit wins): --engine PATH, $ZER0_IMAGE_ENGINE,
`bundle info zer0-image-generator`, `gem contents zer0-image-generator`,
scripts/lib/preview_generator.py.

Exit codes: 0 ok (or nothing to do) · 1 one or more banners failed ·
3 no Claude credential (callers fall back to the engine's `local` provider) ·
4 engine not found.
"""

from __future__ import annotations

import argparse
import importlib.util
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional

EXIT_FAILED = 1
EXIT_NO_CREDENTIAL = 3
EXIT_NO_ENGINE = 4

DEFAULT_MODEL = "claude-sonnet-4-6"
DEFAULT_OUTPUT_DIR = "assets/images/previews"
DEFAULT_FRONT_MATTER_KEY = "preview"
DEFAULT_STYLE = (
    "clean flat vector illustration, bold geometric shapes, "
    "high contrast, limited palette"
)
MAX_SVG_CHARS = 300_000  # refuse pathological responses before parsing

BANNER_SYSTEM = (
    "You are an expert vector illustrator producing an SVG preview banner for "
    "a website article. You respond with ONE complete, standalone SVG "
    "document and nothing else — no prose, no explanation."
)

BANNER_BRIEF = """\
Draw the preview banner for this article as a single complete SVG document.

ARTICLE
  Title: {title}
  Description: {description}
  Tags: {tags}
  Body excerpt:
---
{excerpt}
---

ART DIRECTION
  Style: {style}
  Modifiers: {modifiers}

HARD REQUIREMENTS
- One `<svg>` root with xmlns="http://www.w3.org/2000/svg" and
  viewBox="0 0 {width} {height}" (landscape banner).
- Pure vector: only shapes, paths, gradients, text. NO <script>, NO
  <foreignObject>, NO <image>, NO external references of any kind
  (no http(s) hrefs, no url() pointing outside the document).
- Accessibility: set role="img" on the root and make the FIRST child a
  <title> element naming the artwork.
- Include the article title as legible headline text inside the banner
  (wrap onto multiple lines if needed; keep generous margins).
- The composition must read clearly both as a 300px-wide card and a
  full-width article header: bold shapes, strong contrast, no fine detail
  that only works large.
- Make the artwork ABOUT the article's specific subject — depict its
  concrete objects/ideas, not a generic tech collage.

Respond with ONLY the SVG document (a ```svg fenced block is fine).
"""


def log(msg: str) -> None:
    print(f"[claude-svg] {msg}")


def warn(msg: str) -> None:
    print(f"[claude-svg] WARN: {msg}", file=sys.stderr)


# ── Engine discovery / import ────────────────────────────────────────────────

def find_engine(explicit: Optional[str]) -> Optional[Path]:
    candidates: List[Optional[str]] = [explicit, os.environ.get("ZER0_IMAGE_ENGINE")]
    for cand in candidates:
        if cand and Path(cand).is_file():
            return Path(cand)
    for tool, args in (("bundle", ["info", "zer0-image-generator", "--path"]),):
        if shutil.which(tool):
            try:
                out = subprocess.run([tool, *args], capture_output=True, text=True,
                                     timeout=60)
                if out.returncode == 0 and out.stdout.strip():
                    path = (Path(out.stdout.strip()) / "lib" / "zer0_image_generator"
                            / "preview_generator.py")
                    if path.is_file():
                        return path
            except (OSError, subprocess.TimeoutExpired):
                pass
    if shutil.which("gem"):
        try:
            out = subprocess.run(["gem", "contents", "zer0-image-generator"],
                                 capture_output=True, text=True, timeout=60)
            for line in out.stdout.splitlines():
                if line.strip().endswith("preview_generator.py"):
                    return Path(line.strip())
        except (OSError, subprocess.TimeoutExpired):
            pass
    here = Path(__file__).resolve().parent
    for cand_path in (here / "lib" / "preview_generator.py",
                      here.parent / "lib" / "preview_generator.py"):
        if cand_path.is_file():
            return cand_path
    return None


def load_engine(path: Path):
    spec = importlib.util.spec_from_file_location("zer0_image_engine", path)
    if spec is None or spec.loader is None:
        raise ImportError(f"cannot load engine from {path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    for symbol in ("AnthropicClient", "sanitize_svg", "generate_filename",
                   "update_front_matter", "read_config", "find_project_root",
                   "SvgError", "SVG_WIDTH", "SVG_HEIGHT"):
        if not hasattr(module, symbol):
            raise ImportError(f"engine at {path} lacks {symbol}; "
                              "need zer0-image-generator >= 0.4")
    return module


# ── Config / discovery ───────────────────────────────────────────────────────

def preview_config(site_config: Dict[str, Any]) -> Dict[str, Any]:
    block = site_config.get("preview_images")
    return block if isinstance(block, dict) else {}


def front_matter_value(output_dir: str, assets_prefix: str, filename: str) -> str:
    """Mirror the engine's preview_front_matter_path: the stamped value omits
    the assets prefix (the theme's Liquid adds it back)."""
    out = output_dir.strip("/")
    prefix = assets_prefix.strip("/")
    if prefix and (out == prefix or out.startswith(prefix + "/")):
        out = out[len(prefix):].strip("/")
    return f"/{out}/{filename}" if out else f"/{filename}"


def parse_front_matter(text: str) -> Dict[str, str]:
    """Tiny forgiving scalar-only front-matter reader (title/description/…)."""
    fields: Dict[str, str] = {}
    match = re.match(r"\A---\s*\n(.*?)\n---\s*\n", text, re.S)
    if not match:
        return fields
    for line in match.group(1).splitlines():
        kv = re.match(r"^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$", line)
        if kv:
            fields[kv.group(1)] = kv.group(2).strip().strip("'\"")
    return fields


def body_excerpt(text: str, limit: int = 1500) -> str:
    body = re.sub(r"\A---\s*\n.*?\n---\s*\n", "", text, count=1, flags=re.S)
    body = re.sub(r"```.*?```", "", body, flags=re.S)   # drop code blocks
    body = re.sub(r"\n{3,}", "\n\n", body).strip()
    return body[:limit]


def git_changed_markdown(root: Path, exclude_re: Optional[str]) -> List[Path]:
    try:
        out = subprocess.run(["git", "status", "--porcelain"], cwd=root,
                             capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.TimeoutExpired) as exc:
        warn(f"git status failed: {exc}")
        return []
    files: List[Path] = []
    for line in out.stdout.splitlines():
        if len(line) < 4 or line[:2] in ("D ", " D"):
            continue
        path = line[3:]
        if " -> " in path:                      # rename: take the new side
            path = path.split(" -> ", 1)[1]
        path = path.strip().strip('"')
        if not path.endswith((".md", ".markdown")):
            continue
        if exclude_re and re.search(exclude_re, line):
            continue
        candidate = root / path
        if candidate.is_file():
            files.append(candidate)
    return files


def scan_collections(root: Path, collections_dir: str,
                     collections: List[str]) -> List[Path]:
    files: List[Path] = []
    base = root / collections_dir if collections_dir else root
    for name in collections:
        cdir = base / f"_{name}"
        if cdir.is_dir():
            files.extend(sorted(cdir.rglob("*.md")))
            files.extend(sorted(cdir.rglob("*.markdown")))
    return files


def preview_exists(fields: Dict[str, str], root: Path, assets_prefix: str) -> bool:
    preview = fields.get("preview") or fields.get("image") or ""
    if not preview:
        return False
    if preview.startswith(("http://", "https://")):
        return True
    clean = preview.lstrip("/")
    return (root / clean).is_file() or (root / "assets" / clean).is_file()


# ── SVG extraction ───────────────────────────────────────────────────────────

def extract_svg(response: str) -> Optional[str]:
    fenced = re.search(r"```(?:svg|xml)?\s*\n(.*?)```", response, re.S)
    if fenced and "<svg" in fenced.group(1):
        response = fenced.group(1)
    match = re.search(r"<svg\b.*</svg\s*>", response, re.S)
    return match.group(0) if match else None


def ensure_accessible(svg: str, title: str) -> str:
    """Guarantee role="img" + a first-child <title> (the sanitizer keeps both)."""
    if 'role="img"' not in svg.split(">", 1)[0]:
        svg = svg.replace("<svg", '<svg role="img"', 1)
    if "<title" not in svg:
        safe = title.replace("&", "&amp;").replace("<", "&lt;")
        head, sep, tail = svg.partition(">")
        svg = f"{head}{sep}<title>{safe}</title>{tail}"
    return svg


# ── Main ─────────────────────────────────────────────────────────────────────

def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="claude_svg_banner",
        description="Claude-authored SVG preview banners for Jekyll articles "
                    "(the `claude` rung of the preview capability ladder).")
    parser.add_argument("-f", "--file", action="append", default=[],
                        help="article to illustrate (repeatable)")
    parser.add_argument("--changed", action="store_true",
                        help="illustrate git-new/modified markdown files")
    parser.add_argument("--scan", action="store_true",
                        help="illustrate configured collections' files that "
                             "lack a preview")
    parser.add_argument("-c", "--collection", action="append", default=[],
                        help="restrict --scan to these collections")
    parser.add_argument("--collections-dir", default=None,
                        help="override Jekyll collections_dir for --scan")
    parser.add_argument("--exclude-re", default=os.environ.get("HUB_OWNED_EXCLUDE_RE"),
                        help="git-status regex to skip in --changed mode "
                             "(default: $HUB_OWNED_EXCLUDE_RE)")
    parser.add_argument("--engine", default=None,
                        help="path to the zer0-image-generator preview_generator.py")
    parser.add_argument("--model", default=None, help="Claude model for authoring")
    parser.add_argument("--style", default=None, help="art-direction style")
    parser.add_argument("--style-modifiers", default=None,
                        help="art-direction modifiers")
    parser.add_argument("--output-dir", default=None,
                        help="banner output dir (default from _config.yml)")
    parser.add_argument("--front-matter-key", default=None,
                        help="front-matter key to stamp (default: preview)")
    parser.add_argument("--batch", type=int, default=0,
                        help="max files to illustrate (0 = no limit)")
    parser.add_argument("--force", action="store_true",
                        help="regenerate even when a preview exists")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("-v", "--verbose", action="store_true")
    return parser


def main(argv: Optional[List[str]] = None) -> int:
    args = build_parser().parse_args(argv)

    engine_path = find_engine(args.engine)
    if engine_path is None:
        warn("zer0-image-generator engine not found — install the gem "
             "(gem install zer0-image-generator) or pass --engine/"
             "$ZER0_IMAGE_ENGINE")
        return EXIT_NO_ENGINE
    try:
        engine = load_engine(engine_path)
    except ImportError as exc:
        warn(str(exc))
        return EXIT_NO_ENGINE
    if args.verbose:
        log(f"engine: {engine_path}")

    client = engine.AnthropicClient()
    if not client.available():
        if not args.dry_run:
            warn("no Claude credential (CLAUDE_CODE_OAUTH_TOKEN / "
                 "ANTHROPIC_AUTH_TOKEN / ANTHROPIC_API_KEY / claude CLI) — "
                 "callers should fall back to the engine's `local` provider")
            return EXIT_NO_CREDENTIAL
        log("no Claude credential (dry-run continues)")
    else:
        log(f"Claude credential: {client.describe()}")

    root = engine.find_project_root()
    site_config = engine.read_config(root)
    cfg = preview_config(site_config)

    style = (args.style or os.environ.get("IMAGE_STYLE")
             or cfg.get("style") or DEFAULT_STYLE)
    modifiers = (args.style_modifiers or os.environ.get("IMAGE_STYLE_MODIFIERS")
                 or cfg.get("style_modifiers") or "")
    model = (args.model or os.environ.get("CLAUDE_SVG_MODEL")
             or cfg.get("claude_model") or DEFAULT_MODEL)
    output_dir = (args.output_dir or cfg.get("output_dir") or DEFAULT_OUTPUT_DIR)
    fm_key = (args.front_matter_key or cfg.get("front_matter_key")
              or DEFAULT_FRONT_MATTER_KEY)
    assets_prefix = str(cfg.get("assets_prefix") or "/assets")
    effort = str(cfg.get("claude_effort") or "low")

    # ---- target selection ---------------------------------------------------
    targets: List[Path] = []
    for name in args.file:
        path = Path(name)
        if not path.is_absolute():
            path = root / path
        if path.is_file():
            targets.append(path)
        else:
            warn(f"no such file: {name}")
    if args.changed:
        targets.extend(git_changed_markdown(root, args.exclude_re))
    if args.scan:
        collections_dir = (args.collections_dir
                           if args.collections_dir is not None
                           else str(cfg.get("collections_dir")
                                    or site_config.get("collections_dir") or ""))
        collections = args.collection or [
            str(c) for c in (cfg.get("collections") or ["posts"])
            if isinstance(c, str)
        ]
        targets.extend(scan_collections(root, collections_dir.strip("/"),
                                        collections))
    # de-dup, stable order
    seen = set()
    targets = [t for t in targets if not (t in seen or seen.add(t))]
    if not targets:
        log("nothing to illustrate")
        return 0

    out_dir = root / output_dir
    generated = failed = skipped = 0
    for path in targets:
        if args.batch and generated >= args.batch:
            break
        try:
            text = path.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as exc:
            warn(f"{path}: unreadable ({exc})")
            failed += 1
            continue
        fields = parse_front_matter(text)
        title = fields.get("title") or path.stem.replace("-", " ").title()
        if not args.force and preview_exists(fields, root, assets_prefix):
            if args.verbose:
                log(f"skip (preview exists): {path.relative_to(root)}")
            skipped += 1
            continue
        slug = engine.generate_filename(title)
        if not slug:
            warn(f"{path}: cannot derive slug from title")
            failed += 1
            continue

        if args.dry_run:
            log(f"[DRY RUN] would illustrate {path.relative_to(root)} → "
                f"{output_dir}/{slug}.svg (model {model})")
            generated += 1
            continue

        brief = BANNER_BRIEF.format(
            title=title,
            description=fields.get("description", ""),
            tags=fields.get("tags", fields.get("categories", "")),
            excerpt=body_excerpt(text),
            style=style,
            modifiers=modifiers,
            width=engine.SVG_WIDTH,
            height=engine.SVG_HEIGHT,
        )
        log(f"illustrating: {title}")
        try:
            response = client.complete(BANNER_SYSTEM, brief, model=model,
                                       effort=effort)
        except Exception as exc:  # noqa: BLE001 — every failure is per-file
            warn(f"{path.name}: Claude call failed: {exc}")
            failed += 1
            continue
        raw = extract_svg(response or "")
        if not raw or len(raw) > MAX_SVG_CHARS:
            warn(f"{path.name}: response contained no usable SVG")
            failed += 1
            continue
        try:
            clean, notes = engine.sanitize_svg(ensure_accessible(raw, title))
        except engine.SvgError as exc:
            warn(f"{path.name}: SVG rejected: {exc}")
            failed += 1
            continue
        for note in notes:
            if args.verbose:
                log(f"  sanitizer: {note}")

        out_dir.mkdir(parents=True, exist_ok=True)
        svg_path = out_dir / f"{slug}.svg"
        svg_path.write_text(clean, encoding="utf-8")
        stamp = front_matter_value(output_dir, assets_prefix, svg_path.name)
        if engine.update_front_matter(path, stamp, key=fm_key):
            log(f"  ✓ {svg_path.relative_to(root)}")
            generated += 1
        else:
            warn(f"{path.name}: banner written but front matter not stamped")
            failed += 1

    log(f"done: {generated} generated, {skipped} skipped, {failed} failed")
    return EXIT_FAILED if failed else 0


if __name__ == "__main__":
    sys.exit(main())
