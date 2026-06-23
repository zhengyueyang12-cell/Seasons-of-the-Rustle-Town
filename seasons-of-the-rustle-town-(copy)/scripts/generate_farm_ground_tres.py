#!/usr/bin/env python3
"""
三层地形 TileSet：草(0) ↔ 土(1) ↔ 耕地(2)
  草/土过渡 → spring_outdoorsTileSheet..png (source 0)
  耕地 wang  → hoeDirt..png (source 1)，外侧邻接土

── 如何注册新瓦片 ──────────────────────────────────────────
在 build_tiles() 里加一行即可，坐标见 art/.../_labeled_terrain.png：

  草填充:     m(0, 6)
  草接土边:   m(4, 7, {"bottom_side": SOIL, ...})
  土填充:     s(3, 6)
  土接草边:   s(2, 7, {"top_side": MEADOW})
  土接耕地:   s(3, 6, {"right_side": TILLED}, alt=3)
  耕地块:     f(2, 1)                              # hoeDirt 图集

同一 atlas 坐标多种 peering → 用 alt=1,2,3 区分（Godot alternative 瓦片）

改完后运行:  python scripts/generate_farm_ground_tres.py
脚本会自动为 spring(25×79) 与 hoeDirt(8×4) 图集每个坐标补 alt=0 默认瓦片；
手工 peering 优先保留，装饰格（树/水/空）也会注册，涂地图时自行避开即可。

Peering 值 = 邻居格的地形 ID：MEADOW(0) / SOIL(1) / TILLED(2)
未写的方向默认等于当前瓦片自己的 terrain（见 peering() 函数）
─────────────────────────────────────────────────────────────
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "resources" / "tilesets" / "farm_ground.tres"
SPRING_IMG = ROOT / "art/world/TerrainFeatures/spring_outdoorsTileSheet..png"
HOE_IMG = ROOT / "art/world/TerrainFeatures/hoeDirt..png"
TILE_SIZE = 16
SPRING_COLS, SPRING_ROWS = 25, 79
HOE_COLS, HOE_ROWS = 8, 4

SPRING_TEX = "uid://b13qln87nxuyf"
SPRING_PATH = "res://art/world/TerrainFeatures/spring_outdoorsTileSheet..png"
HOE_TEX = "uid://nova8fa1iayc"
HOE_PATH = "res://art/world/TerrainFeatures/hoeDirt..png"

MEADOW, SOIL, TILLED = 0, 1, 2
SIDES = ("right_side", "bottom_side", "left_side", "top_side")
CORNERS = {
    "top_left_corner": ("top_side", "left_side"),
    "top_right_corner": ("top_side", "right_side"),
    "bottom_left_corner": ("bottom_side", "left_side"),
    "bottom_right_corner": ("bottom_side", "right_side"),
}

# (source, x, y, alt)
TileRef = tuple[int, int, int, int]


def _corner(side_vals: dict, terrain: int, a: str, b: str) -> int:
    va, vb = side_vals[a], side_vals[b]
    if va == vb:
        return va
    if terrain == MEADOW:
        return MEADOW
    if terrain == SOIL:
        if MEADOW in (va, vb):
            return MEADOW
        return TILLED if TILLED in (va, vb) else SOIL
    if SOIL in (va, vb):
        return SOIL
    return TILLED if TILLED in (va, vb) else MEADOW


def peering(terrain: int, overrides: dict | None = None) -> dict:
    overrides = overrides or {}
    sides = {s: overrides.get(s, terrain) for s in SIDES}
    bits = dict(sides)
    for corner, (a, b) in CORNERS.items():
        bits[corner] = overrides.get(corner, _corner(sides, terrain, a, b))
    return bits


def tile(
    source: int,
    x: int,
    y: int,
    alt: int,
    terrain: int,
    overrides: dict | None = None,
) -> tuple[TileRef, int, dict]:
    return ((source, x, y, alt), terrain, peering(terrain, overrides))


def m(x: int, y: int, overrides: dict | None = None, alt: int = 0) -> tuple[TileRef, int, dict]:
    return tile(0, x, y, alt, MEADOW, overrides)


def s(x: int, y: int, overrides: dict | None = None, alt: int = 0) -> tuple[TileRef, int, dict]:
    return tile(0, x, y, alt, SOIL, overrides)


def f(x: int, y: int, overrides: dict | None = None, alt: int = 0) -> tuple[TileRef, int, dict]:
    return tile(1, x, y, alt, TILLED, overrides)


def _is_grass_pixel(r: int, g: int, b: int, a: int) -> bool:
    return a > 32 and g > r + 15 and g > b + 8


def _is_soil_pixel(r: int, g: int, b: int, a: int) -> bool:
    return a > 32 and r > 85 and g > 45 and b < 95 and r >= g - 35


def classify_spring_terrain(img, x: int, y: int) -> int:
    """按像素主色推断默认地形：草多→meadow，土多→soil，其余→meadow。"""
    tile = img.crop((x * TILE_SIZE, y * TILE_SIZE, (x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE))
    px = tile.load()
    grass = soil = opaque = 0
    for py in range(TILE_SIZE):
        for px_x in range(TILE_SIZE):
            r, g, b, a = px[px_x, py]
            if a < 32:
                continue
            opaque += 1
            if _is_grass_pixel(r, g, b, a):
                grass += 1
            elif _is_soil_pixel(r, g, b, a):
                soil += 1
    if opaque < 8:
        return MEADOW
    return SOIL if soil > grass else MEADOW


def fill_all_atlas_cells(
    manual: list[tuple[TileRef, int, dict]],
    source: int,
    cols: int,
    rows: int,
    terrain_at,
) -> list[tuple[TileRef, int, dict]]:
    """为图集中每个 (x,y) 确保至少有 alt=0 瓦片；已有手工 peering 的坐标保留。"""
    existing = {(src, x, y, alt) for (src, x, y, alt), _, _ in manual}
    tiles = list(manual)
    for y in range(rows):
        for x in range(cols):
            if (source, x, y, 0) in existing:
                continue
            terrain = terrain_at(x, y)
            tiles.append(tile(source, x, y, 0, terrain, None))
    return tiles


def build_manual_tiles() -> list[tuple[TileRef, int, dict]]:
    tiles: list[tuple[TileRef, int, dict]] = []
    g, soil = MEADOW, SOIL

    # --- 草：纯填充 ---
    for coord in ((0, 6), (1, 6), (2, 6), (0, 7), (6, 6)):
        tiles.append(m(*coord))

    # --- 草：草土过渡（row 6–10 凡同时含草/土的格子）---
    tiles += [
        # row 6 树根区草土边
        m(7, 6, {"top_side": SOIL, "right_side": SOIL, "top_right_corner": SOIL}),
        m(8, 6, {"top_side": SOIL, "left_side": SOIL, "top_left_corner": SOIL}),
        # row 7 横/斜向草边
        m(4, 7, {"bottom_side": SOIL, "bottom_left_corner": SOIL, "bottom_right_corner": SOIL}),
        m(5, 7, {"bottom_side": SOIL, "bottom_left_corner": SOIL, "bottom_right_corner": SOIL}),
        m(0, 7, {"top_left_corner": SOIL}, alt=1),
        m(6, 7, {"bottom_right_corner": SOIL}),
        m(7, 7, {"bottom_left_corner": SOIL}),
        # row 8 wang 草侧内角/边
        m(0, 8, {"bottom_right_corner": SOIL}),
        m(1, 8, {"bottom_side": SOIL, "bottom_left_corner": SOIL, "bottom_right_corner": SOIL}),
        m(2, 8, {"right_side": SOIL, "top_right_corner": SOIL, "bottom_right_corner": SOIL}),
        m(3, 8, {"bottom_side": SOIL, "bottom_left_corner": SOIL}),
        m(4, 8, {"right_side": SOIL, "top_right_corner": SOIL}),
        m(5, 8, {"bottom_side": SOIL, "bottom_left_corner": SOIL, "bottom_right_corner": SOIL}),
        m(6, 8, {"top_side": SOIL, "top_left_corner": SOIL, "top_right_corner": SOIL}, alt=1),
        m(7, 8, {"left_side": SOIL, "top_left_corner": SOIL, "bottom_left_corner": SOIL}, alt=1),
        # row 9 草在上
        m(4, 9, {"bottom_side": SOIL, "bottom_left_corner": SOIL, "bottom_right_corner": SOIL}),
        m(5, 9, {"bottom_side": SOIL, "bottom_left_corner": SOIL, "bottom_right_corner": SOIL}),
        # row 10 草土/崖边过渡
        m(0, 10, {"right_side": SOIL, "top_right_corner": SOIL}),
        m(3, 10, {"top_left_corner": SOIL}),
    ]

    # --- 土：纯填充 ---
    tiles += [
        s(3, 6), s(4, 6), s(1, 9), s(2, 9),
        s(6, 8), s(7, 8),
    ]

    # --- 土：草在外侧（块状 wang row 7–9）---
    tiles += [
        s(1, 7, {"top_side": g, "left_side": g}),
        s(1, 7, {"bottom_side": g, "left_side": g}, alt=1),
        s(2, 7, {"top_side": g}),
        s(3, 7, {"top_side": g, "right_side": g}),
        s(3, 7, {"top_side": g, "left_side": g}, alt=1),
        s(6, 7, {"left_side": g}, alt=1),
        s(5, 6, {"bottom_side": g}),
        s(8, 8, {"right_side": g}),
        # row 8 wang 土侧外角/边
        s(0, 8, {"top_side": g, "left_side": g}, alt=1),
        s(1, 8, {"top_side": g}, alt=1),
        s(2, 8, {"top_side": g}, alt=1),
        s(3, 8, {"top_side": g, "right_side": g}, alt=1),
        # row 9 wang 土块底边外角
        s(0, 9, {"bottom_side": g, "left_side": g}),
        s(3, 9, {"top_side": g, "left_side": g}),
        # row 10 土侧崖边
        s(1, 10, {"top_side": g, "left_side": g, "right_side": g}),
        s(2, 10, {
            "top_side": g, "bottom_side": g, "left_side": g, "right_side": g,
            "top_left_corner": g, "top_right_corner": g, "bottom_right_corner": g,
        }),
    ]

    # --- 土：横/竖长条（草在两侧）---
    tiles += [
        s(1, 9, {"top_side": g, "bottom_side": g, "left_side": g}, alt=1),
        s(2, 9, {"top_side": g, "bottom_side": g}, alt=1),
        s(2, 9, {"top_side": g, "bottom_side": g, "right_side": g}, alt=2),
        s(3, 6, {"left_side": g, "right_side": g, "top_side": g}, alt=1),
        s(4, 6, {"left_side": g, "right_side": g}, alt=1),
        s(3, 6, {"left_side": g, "right_side": g, "bottom_side": g}, alt=2),
        s(7, 7, {"top_side": g, "bottom_side": g, "left_side": g}, alt=1),
        s(7, 7, {"left_side": g, "right_side": g}, alt=2),
        s(7, 7, {"top_side": g, "bottom_side": g, "right_side": g}, alt=3),
    ]

    # --- 土：耕地在外侧 ---
    tiles += [
        s(3, 6, {"right_side": TILLED}, alt=3),
        s(4, 6, {"left_side": TILLED}, alt=2),
        s(3, 6, {"bottom_side": TILLED}, alt=4),
        s(4, 6, {"top_side": TILLED}, alt=3),
        s(3, 6, {"top_side": TILLED, "left_side": TILLED}, alt=5),
        s(4, 6, {"top_side": TILLED, "right_side": TILLED}, alt=4),
    ]

    # --- 耕地：hoeDirt，四周为土 ---
    tiles.append(f(0, 0, {side: soil for side in SIDES}))
    tiles += [
        f(1, 0, {"top_side": soil, "left_side": soil}),
        f(2, 0, {"top_side": soil}),
        f(3, 0, {"top_side": soil, "right_side": soil}),
        f(1, 1, {"left_side": soil}),
        f(2, 1, {}),
        f(3, 1, {"right_side": soil}),
        f(1, 2, {"bottom_side": soil, "left_side": soil}),
        f(2, 2, {"bottom_side": soil}),
        f(3, 2, {"bottom_side": soil, "right_side": soil}),
        f(1, 3, {"top_side": soil, "bottom_side": soil, "left_side": soil}),
        f(2, 3, {"top_side": soil, "bottom_side": soil}),
        f(3, 3, {"top_side": soil, "bottom_side": soil, "right_side": soil}),
        f(0, 1, {"left_side": soil, "right_side": soil, "top_side": soil}),
        f(0, 2, {"left_side": soil, "right_side": soil}),
        f(0, 3, {"left_side": soil, "right_side": soil, "bottom_side": soil}),
    ]

    return tiles


def build_tiles() -> list[tuple[TileRef, int, dict]]:
    manual = build_manual_tiles()
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("需要 Pillow：pip install Pillow") from exc

    spring_img = Image.open(SPRING_IMG).convert("RGBA")
    tiles = fill_all_atlas_cells(
        manual,
        0,
        SPRING_COLS,
        SPRING_ROWS,
        lambda x, y: classify_spring_terrain(spring_img, x, y),
    )
    tiles = fill_all_atlas_cells(
        tiles,
        1,
        HOE_COLS,
        HOE_ROWS,
        lambda _x, _y: TILLED,
    )
    return tiles


def peering_lines(source: int, x: int, y: int, alt: int, terrain: int, bits: dict) -> list[str]:
    prefix = f"{x}:{y}/{alt}"
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
    seen: dict[TileRef, int] = {}
    for ref, _terrain, _bits in tiles:
        seen[ref] = seen.get(ref, 0) + 1
    dupes = [ref for ref, n in seen.items() if n > 1]
    if dupes:
        raise SystemExit(f"Duplicate tile refs (fix alt indices): {sorted(dupes)}")

    spring_defs: list[tuple[int, int, int, int, dict]] = []
    hoe_defs: list[tuple[int, int, int, int, dict]] = []

    for (src, x, y, alt), terrain, bits in tiles:
        entry = (x, y, alt, terrain, bits)
        if src == 0:
            spring_defs.append(entry)
        else:
            hoe_defs.append(entry)

    lines = [
        '[gd_resource type="TileSet" load_steps=5 format=3 uid="uid://wn5ayu46emb5"]',
        "",
        f'[ext_resource type="Texture2D" uid="{SPRING_TEX}" path="{SPRING_PATH}" id="1_spring"]',
        f'[ext_resource type="Texture2D" uid="{HOE_TEX}" path="{HOE_PATH}" id="2_hoe"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_spring"]',
        'texture = ExtResource("1_spring")',
        "texture_region_size = Vector2i(16, 16)",
    ]
    for x, y, alt, terrain, bits in sorted(spring_defs, key=lambda e: (e[1], e[0], e[2])):
        lines.extend(peering_lines(0, x, y, alt, terrain, bits))

    lines += [
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_hoe"]',
        'texture = ExtResource("2_hoe")',
        "texture_region_size = Vector2i(16, 16)",
    ]
    for x, y, alt, terrain, bits in sorted(hoe_defs, key=lambda e: (e[1], e[0], e[2])):
        lines.extend(peering_lines(1, x, y, alt, terrain, bits))

    lines += [
        "",
        "[resource]",
        "terrain_set_0/mode = 1",
        'terrain_set_0/terrain_0/name = "meadow"',
        "terrain_set_0/terrain_0/color = Color(0.45, 0.72, 0.28, 1)",
        'terrain_set_0/terrain_1/name = "soil"',
        "terrain_set_0/terrain_1/color = Color(0.72, 0.55, 0.32, 1)",
        'terrain_set_0/terrain_2/name = "tilled"',
        "terrain_set_0/terrain_2/color = Color(0.45, 0.32, 0.18, 1)",
        'sources/0 = SubResource("TileSetAtlasSource_spring")',
        'sources/1 = SubResource("TileSetAtlasSource_hoe")',
        "",
    ]
    OUT.write_text("\n".join(lines), encoding="utf-8")
    spring_coords = len({(x, y) for x, y, _alt, _t, _b in spring_defs})
    hoe_coords = len({(x, y) for x, y, _alt, _t, _b in hoe_defs})
    print("Wrote", OUT)
    print(f"  spring: {len(spring_defs)} tiles, {spring_coords}/{SPRING_COLS * SPRING_ROWS} coords")
    print(f"  hoe: {len(hoe_defs)} tiles, {hoe_coords}/{HOE_COLS * HOE_ROWS} coords")
    if spring_coords < SPRING_COLS * SPRING_ROWS or hoe_coords < HOE_COLS * HOE_ROWS:
        raise SystemExit("Atlas fill incomplete — check fill_all_atlas_cells()")


if __name__ == "__main__":
    main()
