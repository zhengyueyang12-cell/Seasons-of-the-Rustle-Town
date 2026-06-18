#!/usr/bin/env python3
"""Generate crop, seed, and produce .tres resources."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CROPS_TEX = "res://art/items/TileSheets/crops..png"
CROPS_UID = "uid://bb8d66icyr2b3"
CROP_SCRIPT = "res://resources/crop_resource.gd"
SEED_SCRIPT = "res://resources/seed_resource.gd"
ITEM_SCRIPT = "res://resources/item_resource.gd"

CROPS = [
    {
        "id": "parsnip",
        "name": "防风草",
        "row": 3,
        "cols": range(0, 7),
        "seasons": [0, 2],  # spring, fall
        "harvest_price": 35,
        "seed_price": 20,
    },
    {
        "id": "cauliflower",
        "name": "花椰菜",
        "row": 1,
        "cols": range(0, 7),
        "seasons": [0],
        "harvest_price": 175,
        "seed_price": 80,
    },
    {
        "id": "corn",
        "name": "玉米",
        "row": 5,
        "cols": range(0, 6),
        "seasons": [1],  # summer
        "harvest_price": 50,
        "seed_price": 150,
    },
    {
        "id": "wheat",
        "name": "小麦",
        "row": 11,
        "cols": range(8, 14),
        "seasons": [2],
        "harvest_price": 25,
        "seed_price": 10,
    },
    {
        "id": "tomato",
        "name": "番茄",
        "row": 4,
        "cols": range(8, 16),
        "seasons": [1],
        "harvest_price": 60,
        "seed_price": 50,
    },
]

TS = 16


def atlas_region(x: int, y: int) -> str:
    return f"Rect2({x * TS}, {y * TS}, {TS}, {TS})"


def atlas_sub(id_suffix: str, x: int, y: int) -> list[str]:
    return [
        f'[sub_resource type="AtlasTexture" id="AtlasTexture_{id_suffix}"]',
        f'atlas = ExtResource("1_crops")',
        f"region = {atlas_region(x, y)}",
        "",
    ]


def stage_coords(row: int, cols: range) -> str:
    parts = [f"Vector2i({c}, {row})" for c in cols]
    return "Array[Vector2i]([" + ", ".join(parts) + "])"


def seasons_array(seasons: list[int]) -> str:
    if not seasons:
        return "Array[int]([])"
    return "Array[int]([" + ", ".join(str(s) for s in seasons) + "])"


def write_crop(c: dict) -> None:
    cols = list(c["cols"])
    first_x, row = cols[0], c["row"]
    last_x = cols[-1]
    path = ROOT / "resources" / "crops" / f"{c['id']}.tres"
    lines = [
        '[gd_resource type="Resource" script_class="CropResource" load_steps=2 format=3]',
        "",
        f'[ext_resource type="Script" path="{CROP_SCRIPT}" id="1_script"]',
        "",
        "[resource]",
        'script = ExtResource("1_script")',
        f'id = &"{c["id"]}"',
        f'display_name = "{c["name"]}"',
        f"stage_atlas_coords = {stage_coords(row, c['cols'])}",
        "days_per_stage = 1",
        f'harvest_item_id = &"{c["id"]}"',
        "harvest_amount = 1",
        f"valid_seasons = {seasons_array(c['seasons'])}",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def write_produce(c: dict) -> None:
    cols = list(c["cols"])
    row = c["row"]
    icon_x = cols[-1]
    path = ROOT / "resources" / "items" / "produce" / f"{c['id']}.tres"
    lines = [
        '[gd_resource type="Resource" script_class="ItemResource" load_steps=4 format=3]',
        "",
        f'[ext_resource type="Texture2D" uid="{CROPS_UID}" path="{CROPS_TEX}" id="1_crops"]',
        f'[ext_resource type="Script" path="{ITEM_SCRIPT}" id="1_script"]',
        "",
        *atlas_sub("icon", icon_x, row),
        "[resource]",
        'script = ExtResource("1_script")',
        f'id = &"{c["id"]}"',
        f'display_name = "{c["name"]}"',
        f'description = "收获的{c["name"]}，可以出售或烹饪。"',
        'icon = SubResource("AtlasTexture_icon")',
        f"sell_price = {c['harvest_price']}",
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def write_seed(c: dict) -> None:
    cols = list(c["cols"])
    row = c["row"]
    icon_x = cols[0]
    path = ROOT / "resources" / "items" / "seeds" / f"{c['id']}_seed.tres"
    lines = [
        '[gd_resource type="Resource" script_class="SeedResource" load_steps=4 format=3]',
        "",
        f'[ext_resource type="Texture2D" uid="{CROPS_UID}" path="{CROPS_TEX}" id="1_crops"]',
        f'[ext_resource type="Script" path="{SEED_SCRIPT}" id="1_script"]',
        "",
        *atlas_sub("icon", icon_x, row),
        "[resource]",
        'script = ExtResource("1_script")',
        f'id = &"{c["id"]}_seed"',
        f'display_name = "{c["name"]}种子"',
        f'description = "种在锄过的耕地上，可长出{c["name"]}。"',
        'icon = SubResource("AtlasTexture_icon")',
        f"max_stack = 99",
        f"sell_price = {c['seed_price']}",
        f'crop_id = &"{c["id"]}"',
        "",
    ]
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    for crop in CROPS:
        write_crop(crop)
        write_produce(crop)
        write_seed(crop)
    print(f"Generated {len(CROPS) * 3} resources")


if __name__ == "__main__":
    main()
