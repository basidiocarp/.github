#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
import shutil
import sys
from pathlib import Path


ALLOWED_ROOT_DOC_NAMES = {
    "agents.md",
    "changelog.md",
    "claude.md",
    "contributing.md",
    "install.md",
    "lsp-guide.md",
    "protocol.md",
    "readme.md",
    "roadmap.md",
    "template.md",
}

EXCLUDED_PARTS = {
    ".codex",
    ".git",
    ".handoffs",
    ".project",
    ".claude",
    "dist",
    "node_modules",
    "target",
    "vendor",
}


def slug_part(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")


def should_include(root: Path, path: Path) -> bool:
    if not path.is_file() or path.suffix.lower() != ".md":
        return False

    rel = path.relative_to(root)
    parts = rel.parts
    rel_posix = rel.as_posix()

    if any(part in EXCLUDED_PARTS for part in parts):
        return False

    if rel_posix.startswith("lamella/resources/"):
        return False

    if any(part.startswith(".") for part in parts[:-1]):
        return False

    if any(part.lower() == "docs" for part in parts[:-1]):
        return True

    return path.name.lower() in ALLOWED_ROOT_DOC_NAMES


def destination_name(rel: Path) -> str:
    stem_parts = list(rel.parts)
    stem_parts[-1] = Path(stem_parts[-1]).stem
    return "-".join(filter(None, (slug_part(part) for part in stem_parts))) + ".md"


def collect_docs(root: Path) -> list[Path]:
    return sorted(path.relative_to(root) for path in root.rglob("*") if should_include(root, path))


def build_project_docs(root: Path, output_dir: Path, force: bool) -> int:
    docs = collect_docs(root)

    if output_dir.exists():
        if not force:
            raise SystemExit(
                f"{output_dir} already exists. Re-run with --force to replace it."
            )
        shutil.rmtree(output_dir)

    output_dir.mkdir(parents=True, exist_ok=True)

    seen: dict[str, Path] = {}
    for rel in docs:
        target_name = destination_name(rel)
        if target_name in seen:
            raise SystemExit(
                f"filename collision for {target_name}: {seen[target_name]} and {rel}"
            )
        seen[target_name] = rel
        shutil.copyfile(root / rel, output_dir / target_name)

    return len(docs)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Copy first-party documentation Markdown into a flat folder."
    )
    parser.add_argument(
        "--root",
        default=".",
        help="Workspace root to scan. Defaults to the current directory.",
    )
    parser.add_argument(
        "--output",
        default=".project",
        help="Output directory. Defaults to .project.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Remove the output directory first if it already exists.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root = Path(args.root).resolve()
    output_dir = (root / args.output).resolve()

    count = build_project_docs(root, output_dir, force=args.force)
    print(f"created {count} files in {output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
