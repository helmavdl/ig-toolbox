#!/usr/bin/env python3
import re
import sys
from pathlib import Path


def main() -> None:
    makefile_path = Path(sys.argv[1]).resolve()
    lines = makefile_path.read_text(encoding="utf-8").splitlines()

    sections: dict[str, list[tuple[str, str]]] = {}
    current_section = "General"

    for line in lines:
        # Section headers: lines starting with "### "
        if line.startswith("### "):
            current_section = line[4:].strip()
            sections.setdefault(current_section, [])

            # print(f'\nSection found: {current_section}')
            continue

        # Targets with "##" description
        m = re.match(r'^([A-Za-z0-9_.-]+):.*?##\s*(.+)$', line)
        if m:
            target, desc = m.groups()
            sections.setdefault(current_section, []).append((target, desc))
            # print(f'\nTarget found: {target} - {desc}')

    print("\nAvailable commands:")

    for section, items in sections.items():
        if not items:
            continue

        print(f"\n{section}:")
        width = max(len(t) for t, _ in items) + 2
        for t, desc in sorted(items):
            print(f"  {t.ljust(width)}{desc}")

    print()


if __name__ == "__main__":
    main()
