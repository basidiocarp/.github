#!/usr/bin/env python3

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOC_PATHS = [ROOT / "docs", ROOT / "profile" / "README.md"]
MARKDOWN_SUFFIXES = {".md", ".markdown"}
LINK_RE = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
FENCE_RE = re.compile(r"^```(?P<lang>[A-Za-z0-9_-]+)?\s*$")

# Keep this intentionally narrow: catch stale names and examples that should not
# re-enter the docs set.
DISALLOWED_PATTERNS = {
    r"^\s*hyphae export-training-data\b": "Use `hyphae export-training`; `export-training-data` should only appear as a compatibility note in prose.",
    r"\bcapture-errors\.js\b": "Basidiocarp docs should describe the current Cortina-first lifecycle path, not legacy JS capture scripts.",
    r"\bcapture-corrections\.js\b": "Basidiocarp docs should describe the current Cortina-first lifecycle path, not legacy JS capture scripts.",
    r"\bcapture-test-results\.js\b": "Basidiocarp docs should describe the current Cortina-first lifecycle path, not legacy JS capture scripts.",
    r"\bsession-summary\.sh\b": "Basidiocarp docs should describe the current Cortina/Hyphae session path, not legacy shell helpers.",
}


def iter_markdown_files() -> list[Path]:
    files: list[Path] = []
    for item in DOC_PATHS:
        if item.is_file():
            files.append(item)
            continue
        files.extend(sorted(p for p in item.rglob("*") if p.suffix.lower() in MARKDOWN_SUFFIXES))
    return files


def validate_relative_links(path: Path, text: str, errors: list[str]) -> None:
    for match in LINK_RE.finditer(text):
        raw_target = match.group(1).strip()
        if not raw_target or raw_target.startswith(("#", "http://", "https://", "mailto:")):
            continue
        if raw_target.startswith("<") and raw_target.endswith(">"):
            raw_target = raw_target[1:-1]
        target = raw_target.split("#", 1)[0]
        if not target:
            continue
        if target.startswith("/"):
            # Try as absolute filesystem path first (links created with machine-specific paths)
            abs_path = Path(target)
            if abs_path.exists():
                continue  # absolute path exists on this machine, skip
            resolved = (ROOT / target.lstrip("/")).resolve()
        else:
            resolved = (path.parent / target).resolve()
        if not resolved.exists():
            errors.append(f"{path.relative_to(ROOT)}: broken relative link target `{raw_target}`")


def validate_fences(path: Path, text: str, errors: list[str]) -> None:
    in_fence = False
    fence_lang = ""
    mermaid_open_line = 0
    for lineno, line in enumerate(text.splitlines(), start=1):
        fence = FENCE_RE.match(line)
        if not fence:
            continue
        if not in_fence:
            in_fence = True
            fence_lang = (fence.group("lang") or "").strip().lower()
            if fence_lang == "mermaid":
                mermaid_open_line = lineno
        else:
            in_fence = False
            fence_lang = ""
            mermaid_open_line = 0
    if in_fence:
        if fence_lang == "mermaid":
            errors.append(
                f"{path.relative_to(ROOT)}:{mermaid_open_line}: unclosed ```mermaid block"
            )
        else:
            errors.append(f"{path.relative_to(ROOT)}: unclosed fenced code block")


def validate_stale_patterns(path: Path, text: str, errors: list[str]) -> None:
    for pattern, message in DISALLOWED_PATTERNS.items():
        regex = re.compile(pattern, re.MULTILINE)
        for match in regex.finditer(text):
            line = text.count("\n", 0, match.start()) + 1
            errors.append(f"{path.relative_to(ROOT)}:{line}: {message}")


def main() -> int:
    errors: list[str] = []
    for path in iter_markdown_files():
        text = path.read_text(encoding="utf-8")
        validate_relative_links(path, text, errors)
        validate_fences(path, text, errors)
        validate_stale_patterns(path, text, errors)

    if errors:
        print("Docs validation failed:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    print("Docs validation passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
