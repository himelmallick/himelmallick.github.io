#!/usr/bin/env python3
"""Holds back posts that are dated in the future.

The publishing workflow runs this before `quarto render`. A post whose `date:` is
later than today is treated as a draft for that build, so it stays off the site
until its date arrives. The workflow also runs once a night, which is what
publishes the post on the day. While a post is held back, any line in another
post that links to it is left out as well, so nothing points to a missing page.

Nothing in the repository is changed: the edit happens in the temporary copy that
GitHub builds from. On your own computer the script only reports what it would
hold back, so `quarto preview` keeps showing future posts while you write them.
"""
import datetime
import os
import pathlib
import re
import zoneinfo

TIMEZONE = "America/New_York"   # "today" is decided in this time zone

today = datetime.datetime.now(zoneinfo.ZoneInfo(TIMEZONE)).date()
if os.environ.get("SITE_TODAY"):                      # for testing: SITE_TODAY=2026-10-11
    today = datetime.date.fromisoformat(os.environ["SITE_TODAY"])
on_github = os.environ.get("GITHUB_ACTIONS") == "true"

held, names = [], []
posts = sorted(pathlib.Path("post").glob("*/index.qmd"))
for path in posts:
    text = path.read_text(encoding="utf-8")
    block = re.match(r"---\r?\n(.*?)\r?\n---\r?\n", text, re.S)
    if not block:
        continue
    front = block.group(1)
    date = re.search(r"^date:\s*[\"']?(\d{4}-\d{2}-\d{2})", front, re.M)
    if not date or datetime.date.fromisoformat(date.group(1)) <= today:
        continue
    held.append(f"{path.parent.name} (dated {date.group(1)})")
    names.append(path.parent.name)
    if on_github and not re.search(r"^draft:\s*true\b", front, re.M):
        front = re.sub(r"^draft:.*\r?\n?", "", front, flags=re.M).rstrip() + "\ndraft: true"
        path.write_text("---\n" + front + "\n---\n" + text[block.end():], encoding="utf-8")

# Leave out lines in the other posts that link to a held-back post
for path in posts:
    if not on_github or path.parent.name in names:
        continue
    lines = path.read_text(encoding="utf-8").split("\n")
    kept = [l for l in lines if not any(f"](../{n}/" in l for n in names)]
    if len(kept) != len(lines):
        path.write_text("\n".join(kept), encoding="utf-8")

verb = "Held back" if on_github else "Would be held back on GitHub"
print(f"Today is {today}. {verb}: {', '.join(held) if held else 'nothing'}.")
