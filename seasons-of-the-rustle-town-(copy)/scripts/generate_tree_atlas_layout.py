#!/usr/bin/env python3
"""分析 TerrainFeatures 树木图集并导出切分区域（无需手动截图）。

用法:
  python scripts/generate_tree_atlas_layout.py
  python scripts/generate_tree_atlas_layout.py --export art/world/TerrainFeatures/tree1_spring..png out/tree1
"""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path

try:
    from PIL import Image
except ImportError as exc:  # pragma: no cover
    raise SystemExit("需要 Pillow: pip install Pillow") from exc

ROOT = Path(__file__).resolve().parents[1]
TERRAIN_DIR = ROOT / "art" / "world" / "TerrainFeatures"


def _is_pixel_opaque(px: tuple[int, int, int, int]) -> bool:
    return px[3] > 20 and sum(px[:3]) > 15


def _region_bbox(im: Image.Image, y0: int, y1: int) -> tuple[int, int, int, int]:
    w, _h = im.size
    minx, miny, maxx, maxy = w, y1, 0, y0
    for y in range(y0, y1 + 1):
        for x in range(w):
            if _is_pixel_opaque(im.getpixel((x, y))):
                minx = min(minx, x)
                miny = min(miny, y)
                maxx = max(maxx, x)
                maxy = max(maxy, y)
    return minx, miny, maxx - minx + 1, maxy - miny + 1


def _find_bands(im: Image.Image) -> list[tuple[int, int]]:
    w, h = im.size
    bands: list[tuple[int, int]] = []
    start: int | None = None
    for y in range(h):
        has_pixel = any(_is_pixel_opaque(im.getpixel((x, y))) for x in range(w))
        if has_pixel and start is None:
            start = y
        elif not has_pixel and start is not None:
            bands.append((start, y - 1))
            start = None
    if start is not None:
        bands.append((start, h - 1))
    return bands


def _find_blobs(im: Image.Image, y0: int, y1: int) -> list[tuple[int, int, int, int, int]]:
    w, _h = im.size
    visited: set[tuple[int, int]] = set()
    blobs: list[tuple[int, int, int, int, int]] = []

    def neighbors(x: int, y: int):
        for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and y0 <= ny <= y1:
                yield nx, ny

    for y in range(y0, y1 + 1):
        for x in range(w):
            if (x, y) in visited:
                continue
            if not _is_pixel_opaque(im.getpixel((x, y))):
                continue
            stack = [(x, y)]
            visited.add((x, y))
            pts = [(x, y)]
            while stack:
                cx, cy = stack.pop()
                for nx, ny in neighbors(cx, cy):
                    if (nx, ny) in visited:
                        continue
                    if not _is_pixel_opaque(im.getpixel((nx, ny))):
                        continue
                    visited.add((nx, ny))
                    stack.append((nx, ny))
                    pts.append((nx, ny))
            xs = [p[0] for p in pts]
            ys = [p[1] for p in pts]
            blobs.append((min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1, len(pts)))
    blobs.sort(key=lambda b: (b[1], b[0]))
    return blobs


def analyze_tree_sheet(path: Path) -> dict:
    im = Image.open(path).convert("RGBA")
    bands = _find_bands(im)
    if len(bands) < 2:
        raise ValueError(f"无法识别图集分区: {path}")

    mature_top, mature_bottom = bands[0]
    middle_top, middle_bottom = bands[1]
    blobs = _find_blobs(im, middle_top, middle_bottom)

    # 树干在树根展开之前截断；树桩用底部一排独立贴图（16×16）
    body_end = mature_bottom
    for y in range(mature_top + 50, mature_bottom):
        xs = [x for x in range(im.size[0]) if im.getpixel((x, y))[3] > 20]
        if not xs:
            continue
        width = max(xs) - min(xs) + 1
        if width >= 20:
            body_end = y
            break

    body = (0, mature_top, im.size[0], body_end - mature_top)
    stump_stand = (16, 144, 16, 16)

    stage_small = blobs[0][:4] if blobs else (0, middle_top, 15, 30)
    seed_blob = next((b for b in blobs if b[2] <= 12 and b[3] <= 12 and b[1] > middle_top + 20), None)
    sprout_blob = next((b for b in blobs if 6 <= b[2] <= 10 and 8 <= b[3] <= 14), seed_blob)
    felled_blob = max(blobs, key=lambda b: b[2] * b[3]) if blobs else stage_small
    leaf_blobs = [b[:4] for b in blobs if b[4] < 80]

    return {
        "sheet": f"res://art/world/TerrainFeatures/{path.name}",
        "size": list(im.size),
        "body_region": list(body),
        "stump_stand_region": list(stump_stand),
        "felled_stump_region": list(felled_blob[:4]),
        "stage_regions": [
            list(seed_blob[:4]) if seed_blob else list(stage_small),
            list(sprout_blob[:4]) if sprout_blob else list(stage_small),
            list(stage_small),
            list(_region_bbox(im, middle_top, middle_bottom)),
            [],
        ],
        "leaf_regions": [list(b) for b in leaf_blobs[:6]],
    }


def export_slices(path: Path, out_dir: Path, layout: dict) -> None:
    im = Image.open(path).convert("RGBA")
    out_dir.mkdir(parents=True, exist_ok=True)

    def save_rect(name: str, rect: list[int]) -> None:
        if not rect:
            return
        x, y, w, h = rect
        crop = im.crop((x, y, x + w, y + h))
        crop.save(out_dir / f"{name}.png")

    save_rect("body", layout["body_region"])
    save_rect("stump_stand", layout["stump_stand_region"])
    save_rect("felled_stump", layout["felled_stump_region"])
    for i, rect in enumerate(layout["stage_regions"]):
        if rect:
            save_rect(f"stage_{i + 1}", rect)
    for i, rect in enumerate(layout["leaf_regions"]):
        save_rect(f"leaf_{i + 1}", rect)


def main() -> None:
    parser = argparse.ArgumentParser(description="自动分析树木图集切分区域")
    parser.add_argument("--sheet", type=Path, help="指定单个图集 PNG")
    parser.add_argument("--export", type=Path, help="导出切分预览图到目录")
    parser.add_argument("--json", type=Path, help="写出 JSON 配置")
    args = parser.parse_args()

    sheets = [args.sheet] if args.sheet else sorted(TERRAIN_DIR.glob("tree*_spring..png"))
    sheets += sorted(TERRAIN_DIR.glob("tree_palm..png"))

    results: dict[str, dict] = {}
    for sheet in sheets:
        key = sheet.stem.replace("..", "").rsplit("_", 1)[0]
        layout = analyze_tree_sheet(sheet)
        results[key] = layout
        print(f"[{key}] {sheet.name}")
        print(json.dumps(layout, indent=2, ensure_ascii=False))
        if args.export:
            export_slices(sheet, args.export / key, layout)

    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(results, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"已写入 {args.json}")


if __name__ == "__main__":
    main()
