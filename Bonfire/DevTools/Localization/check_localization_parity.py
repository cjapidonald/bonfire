#!/usr/bin/env python3
"""Utility to verify localization key parity across languages."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, Mapping

COMMENT_PATTERN = re.compile(r"//.*?$|/\*.*?\*/", re.DOTALL | re.MULTILINE)
KEY_PATTERN = re.compile(r'"((?:\\.|[^"\\])*)"\s*=')


@dataclass
class LocalizationReport:
    path: Path
    missing: list[str]
    extra: list[str]
    duplicates: list[str]

    @property
    def has_issues(self) -> bool:
        return bool(self.missing or self.extra or self.duplicates)


def strip_comments(text: str) -> str:
    return re.sub(COMMENT_PATTERN, "", text)


def extract_keys(path: Path) -> tuple[list[str], list[str]]:
    text = strip_comments(path.read_text(encoding="utf-8"))
    keys = KEY_PATTERN.findall(text)
    seen: dict[str, int] = {}
    duplicates: list[str] = []

    for key in keys:
        seen[key] = seen.get(key, 0) + 1
        if seen[key] == 2:
            duplicates.append(key)

    return keys, duplicates


def compare_keys(base_keys: Iterable[str], target_keys: Iterable[str]) -> tuple[list[str], list[str]]:
    base_set = set(base_keys)
    target_set = set(target_keys)
    missing = sorted(base_set - target_set)
    extra = sorted(target_set - base_set)
    return missing, extra


def check_resource(base: Path, targets: Mapping[str, Path]) -> list[LocalizationReport]:
    base_keys, base_duplicates = extract_keys(base)

    reports: list[LocalizationReport] = []
    if base_duplicates:
        reports.append(
            LocalizationReport(
                path=base,
                missing=[],
                extra=[],
                duplicates=sorted(base_duplicates),
            )
        )

    for language, path in targets.items():
        if not path.exists():
            reports.append(
                LocalizationReport(
                    path=path,
                    missing=["<file missing>"] + sorted(set(base_keys)),
                    extra=[],
                    duplicates=[],
                )
            )
            continue

        keys, duplicates = extract_keys(path)
        missing, extra = compare_keys(base_keys, keys)
        reports.append(LocalizationReport(path=path, missing=missing, extra=extra, duplicates=sorted(duplicates)))

    return reports


def build_target_paths(root: Path, languages: Iterable[str], resource: str) -> dict[str, Path]:
    return {language: root / f"{language}.lproj" / resource for language in languages}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path("Bonfire"), help="Root directory that contains language folders")
    parser.add_argument("--base", default="en", help="Language code to use as the source of truth")
    parser.add_argument("--languages", nargs="*", default=["vi"], help="Language codes to verify against the base language")
    parser.add_argument(
        "--resources",
        nargs="*",
        default=["Localizable.strings", "InfoPlist.strings"],
        help="Resource files to compare across languages",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    root: Path = args.root
    base_language: str = args.base
    languages: list[str] = args.languages
    resources: list[str] = args.resources

    exit_code = 0

    for resource in resources:
        base_path = root / f"{base_language}.lproj" / resource
        if not base_path.exists():
            print(f"⚠️  Base resource missing: {base_path}")
            exit_code = 1
            continue

        target_paths = build_target_paths(root, languages, resource)
        reports = check_resource(base_path, target_paths)

        for report in reports:
            if report.has_issues:
                exit_code = 1
                print(f"❌ {resource} issues in {report.path}")
                if report.missing:
                    print(f"   Missing keys: {', '.join(report.missing)}")
                if report.extra:
                    print(f"   Extra keys: {', '.join(report.extra)}")
                if report.duplicates:
                    print(f"   Duplicate keys: {', '.join(report.duplicates)}")
            else:
                print(f"✅ {resource} matches for {report.path}")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
