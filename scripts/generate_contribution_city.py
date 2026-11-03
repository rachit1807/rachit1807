#!/usr/bin/env python3
"""Render the public GitHub contribution calendar as a small isometric city."""
from __future__ import annotations

import html
import argparse
import re
import urllib.request
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "contribution-city.svg"
SOURCE = "https://github.com/users/rachit1807/contributions"


def fetch_calendar(source_html: str | None = None) -> list[tuple[date, int]]:
    if source_html is None:
        request = urllib.request.Request(SOURCE, headers={"User-Agent": "rachit1807-contribution-city/1.0"})
        page = urllib.request.urlopen(request, timeout=30).read().decode("utf-8")
    else:
        page = source_html
    cells = re.findall(r'<td\b[^>]*data-date="(\d{4}-\d{2}-\d{2})"[^>]*data-level="([0-4])"', page)
    if not cells:
        raise RuntimeError("GitHub contribution calendar was not found in the public profile response")
    return [(date.fromisoformat(day), int(level)) for day, level in cells]


def render(cells: list[tuple[date, int]]) -> str:
    count = len(cells)
    width, height = 1160, 490
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width}" height="{height}" viewBox="0 0 {width} {height}" role="img" aria-labelledby="title desc">',
        '<title id="title">Rachit Tripathi’s contribution city</title>',
        '<desc id="desc">An isometric night city built from the real public GitHub contribution calendar, refreshed daily.</desc>',
        '<defs><linearGradient id="bg" x2="0" y2="1"><stop stop-color="#160b17"/><stop offset="1" stop-color="#0c080e"/></linearGradient><linearGradient id="front" x2="0" y2="1"><stop stop-color="#c77b9b"/><stop offset="1" stop-color="#451126"/></linearGradient><linearGradient id="side" x2="0" y2="1"><stop stop-color="#701a3d"/><stop offset="1" stop-color="#260d1b"/></linearGradient></defs>',
        f'<rect width="{width}" height="{height}" rx="20" fill="url(#bg)" stroke="#451126" stroke-width="2"/>',
        '<text x="34" y="42" fill="#e5b5c7" font-family="monospace" font-size="14" letter-spacing="2">CONTRIBUTION CITY  /  LAST YEAR</text>',
        '<text x="1124" y="42" fill="#754b5b" text-anchor="end" font-family="monospace" font-size="11">DAILY REBUILD</text>',
        '<path d="M26 58H1134" stroke="#3b202b"/>',
    ]
    # A 53-week isometric grid; each contribution day becomes a little lit tower.
    for index, (day, level) in enumerate(cells):
        week, weekday = divmod(index, 7)
        x = 70 + week * 14 + weekday * 7
        base_y = 385 - week * 6 + weekday * 6
        block_h = (4, 9, 15, 22, 30)[level]
        top_y = base_y - block_h
        # Three faces make each contribution block read as a tiny isometric building.
        top = f"{x},{top_y} {x + 7},{top_y - 4} {x + 14},{top_y} {x + 7},{top_y + 4}"
        left = f"{x},{top_y} {x + 7},{top_y + 4} {x + 7},{base_y + 4} {x},{base_y}"
        right = f"{x + 7},{top_y + 4} {x + 14},{top_y} {x + 14},{base_y} {x + 7},{base_y + 4}"
        color = ("#261827", "#56233e", "#843556", "#b4547d", "#f0b6ce")[level]
        title = html.escape(f"{day.isoformat()} · contribution intensity level {level}")
        parts.append(f'<g><title>{title}</title><polygon points="{left}" fill="url(#front)" opacity="{0.45 + level * 0.11:.2f}"/><polygon points="{right}" fill="url(#side)"/><polygon points="{top}" fill="{color}" stroke="#e5b5c7" stroke-opacity="{0.08 + level * 0.05:.2f}"/></g>')
    # Date labels and pink intensity key.
    parts.extend([
        f'<text x="42" y="{height - 26}" fill="#c77b9b" font-family="monospace" font-size="11">{cells[0][0].strftime("%b %Y")}</text>',
        f'<text x="{width - 40}" y="{height - 26}" text-anchor="end" fill="#c77b9b" font-family="monospace" font-size="11">{cells[-1][0].strftime("%b %Y")}</text>',
        '<text x="470" y="455" fill="#754b5b" font-family="monospace" font-size="10" letter-spacing="1">LESS</text>',
    ])
    for level, color in enumerate(("#261827", "#56233e", "#843556", "#b4547d", "#f0b6ce")):
        parts.append(f'<rect x="510" y="443" width="18" height="12" rx="2" fill="{color}"/><text x="{519 + level * 27}" y="0" visibility="hidden">{level}</text>')
        # Position the swatches evenly using a second compact overlay row.
        parts[-1] = f'<rect x="{510 + level * 24}" y="443" width="18" height="12" rx="2" fill="{color}"/>'
    parts.append('<text x="645" y="455" fill="#754b5b" font-family="monospace" font-size="10" letter-spacing="1">MORE</text>')
    parts.append('</svg>')
    return "\n".join(parts)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-html", help="Use a saved contribution-calendar page instead of fetching it")
    args = parser.parse_args()
    calendar = fetch_calendar(Path(args.source_html).read_text(encoding="utf-8") if args.source_html else None)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(render(calendar), encoding="utf-8")
    print(f"Wrote {OUT} from {len(calendar)} public contribution days")


if __name__ == "__main__":
    main()
