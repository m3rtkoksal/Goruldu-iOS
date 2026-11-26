#!/usr/bin/env python3
"""Checks that every localization key used in Swift exists in the string catalog in both
languages, that no catalog entry is unused, and that format arguments match across languages.

Run from the repository root: python3 scripts/check-strings.py
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SOURCE_DIRS = ["App", "DesignSystem", "Features", "Models", "Services"]
LITERAL = re.compile(r'"((?:[a-z][A-Za-z0-9]*\.)+[A-Za-z0-9]+)"')
DYNAMIC = re.compile(r'"((?:[a-z][A-Za-z0-9]*\.)*[A-Za-z0-9.]*\\\([^)]*\)[A-Za-z0-9.]*)"')
ARGUMENT = re.compile(r"%(\d)\$@")

catalog = json.loads((ROOT / "Resources" / "Localizable.xcstrings").read_text(encoding="utf-8"))["strings"]
namespaces = {key.split(".")[0] for key in catalog}
problems = []
used = set()
patterns = []
for folder in SOURCE_DIRS:
    for path in sorted((ROOT / folder).rglob("*.swift")):
        text = path.read_text(encoding="utf-8")
        for key in LITERAL.findall(text):
            if key in catalog:
                used.add(key)
            elif key.split(".")[0] in namespaces:
                problems.append(f"{path.relative_to(ROOT)}: missing key {key}")
        for template in DYNAMIC.findall(text):
            patterns.append(re.compile("^" + re.sub(r"\\\\\\\([^)]*\\\)", "[A-Za-z0-9]+", re.escape(template)) + "$"))

for key, entry in catalog.items():
    values = {}
    for language in ("en", "tr"):
        value = entry.get("localizations", {}).get(language, {}).get("stringUnit", {}).get("value")
        if not value:
            problems.append(f"{key}: no {language} text")
        values[language] = value or ""
    if sorted(set(ARGUMENT.findall(values["en"]))) != sorted(set(ARGUMENT.findall(values["tr"]))):
        problems.append(f"{key}: arguments differ between en and tr")
    if key not in used and not any(pattern.match(key) for pattern in patterns):
        problems.append(f"{key}: not used in code")

for problem in problems:
    print(problem)
print(f"{len(catalog)} keys, {len(problems)} problems")
sys.exit(1 if problems else 0)
