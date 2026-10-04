#!/usr/bin/env python3
"""Refreshes the download counts shown on the Software page.

    python3 assets/update-stats.py

This is the version GitHub runs before every build, so the downloads from
Bioconductor stay current by themselves. It leaves the citation counts as they
are: Google Scholar turns away requests from GitHub's servers, so citations are
refreshed on your own computer with assets/update-stats.R.

Both scripts write the "stats" block of _variables.yml, and the pages show those
values with {{< var stats.citations.maaslin >}} and {{< var stats.downloads.maaslin >}}.
The papers and packages to track are listed in assets/stats.json.

A number that cannot be refreshed keeps its last value, so the site always builds.
"""
import datetime
import json
import os
import pathlib
import re
import urllib.request
import zoneinfo

TIMEZONE = "America/New_York"
BIOCONDUCTOR = "https://bioconductor.org/packages/stats/bioc/{name}/{name}_stats.tab"

ROOT = pathlib.Path(__file__).resolve().parent.parent
VARIABLES = ROOT / "_variables.yml"
SETTINGS = json.loads((ROOT / "assets" / "stats.json").read_text(encoding="utf-8"))
PAPERS = SETTINGS["papers"]       # name used on the pages -> title on Google Scholar
PACKAGES = SETTINGS["packages"]   # name used on the pages -> package on Bioconductor
BIOCONDUCTOR = os.environ.get("STATS_BIOCONDUCTOR_URL", BIOCONDUCTOR)   # for testing
HEADER = "# The numbers under \"stats\" are written by assets/update-stats.R and assets/update-stats.py.\n"


def read_saved():
    """The values currently in _variables.yml."""
    saved = {"citations": {}, "downloads": {}, "citations_date": "", "downloads_date": ""}
    if not VARIABLES.exists():
        return saved
    section = None
    for line in VARIABLES.read_text(encoding="utf-8").splitlines():
        top = re.match(r'^  (citations_date|downloads_date):\s*"(.*)"\s*$', line)
        head = re.match(r"^  (citations|downloads):\s*$", line)
        item = re.match(r'^    ([A-Za-z0-9_]+):\s*"(.*)"\s*$', line)
        if top:
            saved[top.group(1)] = top.group(2)
        elif head:
            section = head.group(1)
        elif item and section:
            saved[section][item.group(1)] = item.group(2)
        elif not line.startswith("    "):
            section = None
    return saved


def bioconductor_downloads(package):
    """All-time downloads of one package, or None when Bioconductor does not answer."""
    try:
        request = urllib.request.Request(BIOCONDUCTOR.format(name=package),
                                         headers={"User-Agent": "personal-website-stats"})
        with urllib.request.urlopen(request, timeout=15) as response:
            text = response.read().decode("utf-8")
        total = 0
        for row in text.splitlines()[1:]:
            cells = row.split("\t")
            if len(cells) >= 4 and cells[1] != "all":
                total += int(cells[3])
        return total or None
    except Exception:
        return None


saved = read_saved()
now = datetime.datetime.now(zoneinfo.ZoneInfo(TIMEZONE)).date()
today = f"{now:%B} {now.day}, {now.year}"

downloads, downloads_date = dict(saved["downloads"]), saved["downloads_date"]
fresh = 0
for key, wanted in PACKAGES.items():
    totals = [bioconductor_downloads(p) for p in ([wanted] if isinstance(wanted, str) else wanted)]
    if None not in totals:                              # every package answered
        downloads[key] = f"{sum(totals):,}"
        fresh += 1
if fresh == len(PACKAGES):
    downloads_date = today

block = ["stats:",
         f'  citations_date: "{saved["citations_date"]}"',
         f'  downloads_date: "{downloads_date}"',
         "  citations:"]
block += [f'    {k}: "{saved["citations"].get(k, "")}"' for k in PAPERS]
block += ["  downloads:"]
block += [f'    {k}: "{downloads.get(k, "")}"' for k in PACKAGES]

old = VARIABLES.read_text(encoding="utf-8") if VARIABLES.exists() else HEADER
kept, skipping = [], False
for line in old.splitlines():
    if line.startswith("stats:"):
        skipping = True
        continue
    if skipping and (line.startswith(" ") or not line.strip()):
        continue
    skipping = False
    kept.append(line)
new = "\n".join(kept).rstrip("\n") + "\n" + "\n".join(block) + "\n"
if new != old:
    VARIABLES.write_text(new, encoding="utf-8")

print(f"Downloads: refreshed {fresh} of {len(PACKAGES)} counts from Bioconductor"
      + ("." if fresh == len(PACKAGES) else ", kept the saved numbers for the rest."))
print("Citations: kept as saved (refresh them with assets/update-stats.R on your own computer).")
print("_variables.yml " + ("updated." if new != old else "is already up to date."))
