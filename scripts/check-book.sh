#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import re
import sys

root = Path.cwd()
src = root / "src"
summary = src / "SUMMARY.md"

if not summary.is_file():
    sys.exit("src/SUMMARY.md がありません")

text = summary.read_text(encoding="utf-8")
targets = re.findall(r"\[[^\]]+\]\(([^)]+\.md)(?:#[^)]+)?\)", text)
missing = [target for target in targets if not (src / target).is_file()]

if missing:
    sys.exit("SUMMARY.md の参照先がありません:\n" + "\n".join(f"- {p}" for p in missing))

errors = []
markdown_files = sorted(src.rglob("*.md"))
for path in markdown_files:
    body = path.read_text(encoding="utf-8")
    if body.count("```") % 2:
        errors.append(f"{path.relative_to(root)}: バッククォートのコードフェンスが閉じていません")
    if body.count("~~~") % 2:
        errors.append(f"{path.relative_to(root)}: チルダのコードフェンスが閉じていません")

if errors:
    sys.exit("\n".join(errors))

print(f"OK: SUMMARY.md の参照 {len(targets)} 件と Markdown {len(markdown_files)} ファイルを確認しました")
PY
