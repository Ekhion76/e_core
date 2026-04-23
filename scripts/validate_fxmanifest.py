#!/usr/bin/env python3
"""
Ellenőrzi, hogy az fxmanifest.lua-ban felsorolt helyi fájlok / glob minták
létező fájlokra mutassanak (FiveM indulás előtti „early fail” a CI-ben).

Kihagyja a @resource/... külső függőség útvonalakat.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

# A `files { }` blokkban: opcionális asset (üres mappa / nincs még .png) – FiveM így is indul.
_OPTIONAL_EMPTY_FILE_GLOBS = frozenset({"html/img/*.png"})


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def _extract_braced_block(content: str, block_name: str) -> str | None:
    m = re.search(rf"\b{re.escape(block_name)}\s*\{{", content)
    if not m:
        return None
    start = m.end()
    depth = 1
    i = start
    while i < len(content) and depth > 0:
        ch = content[i]
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        i += 1
    if depth != 0:
        return None
    return content[start : i - 1]


def _quoted_paths(block: str) -> list[str]:
    return re.findall(r"['\"]([^'\"]+)['\"]", block)


def _validate_path_pattern(root: Path, pattern: str, *, block: str) -> list[str]:
    errs: list[str] = []
    if pattern.startswith("@"):
        return errs
    if "*" in pattern or "?" in pattern:
        matches = sorted(root.glob(pattern))
        if not matches:
            if block == "files" and pattern in _OPTIONAL_EMPTY_FILE_GLOBS:
                return errs
            errs.append(f"[{block}] glob nem talált fájlt: {pattern!r}")
        else:
            for p in matches:
                if not p.is_file():
                    errs.append(f"[{block}] nem fájl: {p.as_posix()}")
        return errs
    rel = root / pattern
    if not rel.is_file():
        errs.append(f"[{block}] hiányzó fájl: {pattern}")
    return errs


def _validate_ui_page(content: str, root: Path) -> list[str]:
    errs: list[str] = []
    m = re.search(r"\bui_page\s+['\"]([^'\"]+)['\"]", content)
    if not m:
        return errs
    p = m.group(1).strip()
    if p.startswith("@") or "*" in p or "?" in p:
        return errs
    if not (root / p).is_file():
        errs.append(f"[ui_page] hiányzó fájl: {p}")
    return errs


def main() -> int:
    root = _repo_root()
    manifest = root / "fxmanifest.lua"
    if not manifest.is_file():
        print("validate_fxmanifest: hiányzik az fxmanifest.lua", file=sys.stderr)
        return 2

    text = manifest.read_text(encoding="utf-8", errors="replace")

    blocks = ("shared_scripts", "client_scripts", "server_scripts", "files")
    errors: list[str] = []
    for name in blocks:
        body = _extract_braced_block(text, name)
        if body is None:
            errors.append(f"nem található vagy hibás blokk: {name} {{ ... }}")
            continue
        for pat in _quoted_paths(body):
            errors.extend(_validate_path_pattern(root, pat.strip(), block=name))

    errors.extend(_validate_ui_page(text, root))

    if errors:
        print("fxmanifest útvonal-ellenőrzés: HIBA", file=sys.stderr)
        for e in errors:
            print(f"  {e}", file=sys.stderr)
        return 1

    print("fxmanifest útvonal-ellenőrzés: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
