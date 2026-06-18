#!/usr/bin/env python3
"""
双图集草地 ↔ 泥土地形融合 TileSet
  meadow → art/world/TileMaps/tilemap (19).png  (source 0)
  dirt   → art/world/TileMaps/tilemap (25).png  (source 1)
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[1] / "resources" / "tilesets" / "farm_ground.tres"

GRASS_TEX = "uid://76hemld5cudj"
GRASS_PATH = "res://art/world/TileMaps/tilemap (19).png"
DIRT_TEX = "uid://d1fb2uw4c0jbg"
DIRT_PATH = "res://art/world/TileMaps/tilemap (25).png"

MEADOW, DIRT = 0, 1
SIDES = ("right_side", "bottom_side", "left_side", "top_side")
CORNERS = {
    "top_left_corner": ("top_side", "left_side"),
    "top_right_corner": ("top_side", "right_side"),
    "bottom_left_corner": ("bottom_side", "left_side"),
    "bottom_right_corner": ("bottom_side", "right_side"),
}

# (source_id, x, y)
TileRef = tuple[int, int, int]


def _corner(side_vals: dict, terrain: int, a: str, b: str) -> int:
    va, vb = side_vals[a], side_vals[b]
    if va == vb:
        return va
    if terrain == MEADOW:
        return MEADOW
    return DIRT if DIRT in (va, vb) else MEADOW


def peering(terrain: int, overrides: dict | None = None) -> dict:
    overrides = overrides or {}
    sides = {s: overrides.get(s, terrain) for s in SIDES}
    bits = dict(sides)
    for corner, (a, b) in CORNERS.items():
        bits[corner] = overrides.get(corner, _corner(sides, terrain, a, b))
    return bits


def t(source: int, x: int, y: int, terrain: int, overrides: dict | None = None) -> tuple[TileRef, int, dict]:
    return ((source, x, y), terrain, peering(terrain, overrides))


def m(x: int, y: int, overrides: dict | None = None) -> tuple[TileRef, int, dict]:
    return t(0, x, y, MEADOW, overrides)


def m1(x: int, y: int, overrides: dict | None = None) -> tuple[TileRef, int, dict]:
    """草地贴图在泥土图集 (source 1) 上，用于圆坑周围草叶。"""
    return t(1, x, y, MEADOW, overrides)


def d(x: int, y: int, overrides: dict | None = None) -> tuple[TileRef, int, dict]:
    return t(1, x, y, DIRT, overrides)


def build_tiles() -> list[tuple[TileRef, int, dict]]:
    tiles: list[tuple[TileRef, int, dict]] = []
    meadow = MEADOW
    dirt = DIRT

    # --- tilemap (19) 纯草地填充 ---
    meadow_fill = [
        (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0),
        (2, 1), (3, 1), (4, 1), (5, 1), (6, 1), (7, 1),
        (1, 2), (2, 2), (4, 2), (5, 2), (6, 2), (7, 2),
        (1, 3), (2, 3), (3, 3), (4, 3), (5, 3), (6, 3), (7, 3),
        (0, 4), (1, 4), (2, 4), (3, 4), (4, 4), (5, 4), (6, 4), (7, 4),
        (1, 5), (2, 5), (4, 5), (5, 5), (6, 5), (7, 5),
    ]
    for coord in meadow_fill:
        tiles.append(m(*coord))

    # 整片草地 (0,6)-(3,11)
    for y in range(6, 12):
        for x in range(4):
            tiles.append(m(x, y))

    # --- tilemap (19) 草地边缘（泥土在外侧，石质边框）---
    tiles += [
        m(0, 0, {s: dirt for s in SIDES}),
        m(1, 0, {s: dirt for s in SIDES}),
        m(0, 1, {s: dirt for s in SIDES}),
        m(1, 1, {s: dirt for s in SIDES}),
        m(0, 2, {"top_side": dirt, "left_side": dirt}),
        m(1, 2, {"top_side": dirt}),
        m(2, 2, {"top_side": dirt}),
        m(3, 2, {"top_side": dirt, "right_side": dirt}),
        m(0, 3, {"left_side": dirt}),
        m(3, 3, {"right_side": dirt}),
        m(0, 4, {"left_side": dirt}),
        m(0, 5, {"bottom_side": dirt, "left_side": dirt}),
        m(1, 5, {"bottom_side": dirt}),
        m(2, 5, {"bottom_side": dirt}),
        m(3, 5, {"bottom_side": dirt, "right_side": dirt}),
    ]

    # --- tilemap (25) 单格圆坑：四周全是草地时用 (0,0) ---
    tiles.append(d(0, 0, {s: meadow for s in SIDES}))

    # --- tilemap (25) 内角草叶（对角草地格，一角邻泥土）---
    tiles += [
        m1(2, 0, {"bottom_right_corner": dirt}),
        m1(3, 0, {"bottom_left_corner": dirt}),
        m1(2, 1, {"top_right_corner": dirt}),
        m1(3, 1, {"top_left_corner": dirt}),
    ]

    # --- tilemap (25) 融合土路 4×4（相邻坑连成线/块）---
    tiles += [
        d(0, 2, {"top_side": meadow, "left_side": meadow}),
        d(1, 2, {"top_side": meadow}),
        d(2, 2, {"top_side": meadow}),
        d(3, 2, {"top_side": meadow, "right_side": meadow}),
        d(0, 3, {"left_side": meadow}),
        d(1, 3, {}),
        d(2, 3, {}),
        d(3, 3, {"right_side": meadow}),
        d(0, 4, {"left_side": meadow}),
        d(1, 4, {}),
        d(2, 4, {}),
        d(3, 4, {"right_side": meadow}),
        d(0, 5, {"bottom_side": meadow, "left_side": meadow}),
        d(1, 5, {"bottom_side": meadow}),
        d(2, 5, {"bottom_side": meadow}),
        d(3, 5, {"bottom_side": meadow, "right_side": meadow}),
    ]

    return tiles


def peering_lines(source: int, x: int, y: int, terrain: int, bits: dict) -> list[str]:
    prefix = f"{x}:{y}/0"
    lines = [
        f"{prefix} = 0",
        f"{prefix}/terrain_set = 0",
        f"{prefix}/terrain = {terrain}",
    ]
    for name in (
        "right_side", "bottom_right_corner", "bottom_side", "bottom_left_corner",
        "left_side", "top_left_corner", "top_side", "top_right_corner",
    ):
        lines.append(f"{prefix}/terrains_peering_bit/{name} = {bits[name]}")
    return lines


def main() -> None:
    tiles = build_tiles()
    grass_by_xy: dict[tuple[int, int], tuple[int, dict]] = {}
    dirt_by_xy: dict[tuple[int, int], tuple[int, dict]] = {}

    for (src, x, y), terrain, bits in tiles:
        if src == 0:
            grass_by_xy[(x, y)] = (terrain, bits)
        else:
            dirt_by_xy[(x, y)] = (terrain, bits)

    grass_defs = [(x, y, ter, bits) for (x, y), (ter, bits) in grass_by_xy.items()]
    dirt_defs = [(x, y, ter, bits) for (x, y), (ter, bits) in dirt_by_xy.items()]

    lines = [
        '[gd_resource type="TileSet" load_steps=5 format=3 uid="uid://wn5ayu46emb5"]',
        "",
        f'[ext_resource type="Texture2D" uid="{GRASS_TEX}" path="{GRASS_PATH}" id="1_grass"]',
        f'[ext_resource type="Texture2D" uid="{DIRT_TEX}" path="{DIRT_PATH}" id="2_dirt"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_grass"]',
        'texture = ExtResource("1_grass")',
        "texture_region_size = Vector2i(16, 16)",
    ]
    for x, y, terrain, bits in sorted(grass_defs, key=lambda e: (e[1], e[0])):
        lines.extend(peering_lines(0, x, y, terrain, bits))

    lines += [
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_dirt"]',
        'texture = ExtResource("2_dirt")',
        "texture_region_size = Vector2i(16, 16)",
    ]
    for x, y, terrain, bits in sorted(dirt_defs, key=lambda e: (e[1], e[0])):
        lines.extend(peering_lines(1, x, y, terrain, bits))

    lines += [
        "",
        "[resource]",
        "terrain_set_0/mode = 1",
        'terrain_set_0/terrain_0/name = "meadow"',
        "terrain_set_0/terrain_0/color = Color(0.45, 0.72, 0.28, 1)",
        'terrain_set_0/terrain_1/name = "dirt"',
        "terrain_set_0/terrain_1/color = Color(0.55, 0.42, 0.28, 1)",
        'sources/0 = SubResource("TileSetAtlasSource_grass")',
        'sources/1 = SubResource("TileSetAtlasSource_dirt")',
        "",
    ]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print("Wrote", OUT)
    print("  grass tiles:", len(grass_defs), "dirt tiles:", len(dirt_defs))


if __name__ == "__main__":
    main()
