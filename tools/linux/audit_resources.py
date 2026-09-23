"""Check literal resource paths and case collisions before exporting to Linux."""
from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[2]
tracked = subprocess.check_output(["git", "ls-files"], cwd=root, text=True).splitlines()
exact = set(tracked)
folded = {}
errors = []
for name in tracked:
    previous = folded.setdefault(name.casefold(), name)
    if previous != name:
        errors.append(f"Case collision: {previous} / {name}")
for name in tracked:
    if not name.endswith((".gd", ".tscn", ".tres", ".godot")) or name.startswith("tests/"):
        continue
    for value in re.findall(r'"res://([^"\n]+)"', (root / name).read_text(encoding="utf-8")):
        if "%" in value or value.endswith("/") or value.startswith("test-results/"):
            continue
        # Concatenated prefixes are not complete resource references.
        if not Path(value).suffix:
            continue
        if value not in exact:
            errors.append(f"{name}: missing or case-mismatched resource {value}")
if errors:
    raise SystemExit("\n".join(errors))
print("LINUX_RESOURCE_AUDIT_OK: no case collisions or missing literal runtime resources")
