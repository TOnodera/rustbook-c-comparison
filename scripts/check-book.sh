#!/usr/bin/env bash
set -euo pipefail

python3 - <<'PY'
from pathlib import Path
import re
import sys

root = Path.cwd().resolve()
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
include_count = 0
markdown_files = sorted(src.rglob("*.md"))
for path in markdown_files:
    body = path.read_text(encoding="utf-8")
    if body.count("```") % 2:
        errors.append(f"{path.relative_to(root)}: バッククォートのコードフェンスが閉じていません")
    if body.count("~~~") % 2:
        errors.append(f"{path.relative_to(root)}: チルダのコードフェンスが閉じていません")
    for target in re.findall(r"\{\{#(?:rustdoc_)?include\s+([^}:]+)", body):
        include_count += 1
        include_path = (path.parent / target).resolve()
        try:
            include_path.relative_to(root)
        except ValueError:
            errors.append(
                f"{path.relative_to(root)}: include参照先がリポジトリ外です: {target}"
            )
            continue
        if not include_path.is_file():
            errors.append(
                f"{path.relative_to(root)}: include参照先がありません: {target}"
            )

if errors:
    sys.exit("\n".join(errors))

print(
    f"OK: SUMMARY.md の参照 {len(targets)} 件、Markdown {len(markdown_files)} "
    f"ファイル、include参照 {include_count} 件を確認しました"
)
PY
