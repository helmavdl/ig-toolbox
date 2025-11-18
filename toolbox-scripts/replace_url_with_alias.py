#!/usr/bin/env python3
import re
import sys
from pathlib import Path

ALIAS_LINE_RE = re.compile(r'^\s*Alias:\s+(\S+)\s*=\s*(\S+)\s*$')

def load_aliases(alias_file: Path):
    """
    Parse alias file and return mapping {url: alias_name}.
    """
    url_to_alias = {}
    with alias_file.open(encoding="utf-8") as f:
        for line in f:
            m = ALIAS_LINE_RE.match(line)
            if not m:
                continue
            alias_name, url = m.groups()
            url_to_alias[url] = alias_name
    return url_to_alias


def is_word_char(ch: str | None) -> bool:
    return ch is not None and (ch.isalnum() or ch == "_")


def replace_urls_in_text(text: str, url_to_alias: dict[str, str]) -> str:
    # 1) First, replace EXACT `"url"` with alias (no quotes)
    #    This is safe and simple, and handles the "just URL in quotes" case.
    for url, alias in sorted(url_to_alias.items(), key=lambda kv: len(kv[0]), reverse=True):
        text = text.replace(f'"{url}"', alias)

    # 2) Then replace bare URLs only OUTSIDE quotes, and only as whole tokens
    urls_sorted = sorted(url_to_alias.keys(), key=len, reverse=True)
    result = []
    in_quotes = False
    i = 0
    n = len(text)

    while i < n:
        ch = text[i]

        # Toggle on plain double quotes
        if ch == '"':
            in_quotes = not in_quotes
            result.append(ch)
            i += 1
            continue

        if not in_quotes:
            # Try to match any URL starting at this position (longest first)
            matched = False
            for url in urls_sorted:
                if text.startswith(url, i):
                    before = text[i - 1] if i > 0 else None
                    after = text[i + len(url)] if i + len(url) < n else None

                    # Require "token-like" boundaries: not surrounded by [0-9A-Za-z_]
                    if not is_word_char(before) and not is_word_char(after):
                        alias = url_to_alias[url]
                        result.append(alias)
                        i += len(url)
                        matched = True
                        break
            if matched:
                continue

        # Default: just copy the character
        result.append(ch)
        i += 1

    return "".join(result)


def replace_in_file(fpath: Path, url_to_alias: dict[str, str]) -> bool:
    text = fpath.read_text(encoding="utf-8")
    new_text = replace_urls_in_text(text, url_to_alias)
    if new_text != text:
        fpath.write_text(new_text, encoding="utf-8")
        return True
    return False


def main():
    if len(sys.argv) != 3:
        print("Usage: replace_url_with_alias.py <alias-file.fsh> <examples-dir>")
        sys.exit(1)

    alias_file = Path(sys.argv[1])
    examples_dir = Path(sys.argv[2])

    if not alias_file.is_file():
        print(f"Alias file not found: {alias_file}")
        sys.exit(1)
    if not examples_dir.is_dir():
        print(f"Examples directory not found: {examples_dir}")
        sys.exit(1)

    url_to_alias = load_aliases(alias_file)
    if not url_to_alias:
        print("No aliases found in alias file – nothing to do.")
        sys.exit(0)

    for fpath in examples_dir.glob("*.fsh"):
        # Skip the alias file itself if it lives in the same dir
        if fpath.resolve() == alias_file.resolve():
            continue
        if replace_in_file(fpath, url_to_alias):
            print(f"Updated {fpath}")

if __name__ == "__main__":
    main()
