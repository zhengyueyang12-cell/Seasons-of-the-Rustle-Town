from pathlib import Path

p = Path(__file__).resolve().parents[1] / "Scenes" / "main.tscn"
lines = p.read_text(encoding="utf-8").splitlines(keepends=True)

start = end = None
for i, line in enumerate(lines):
    if line.startswith('[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_gt3je"]'):
        start = i
    if start is not None and line.startswith('[sub_resource type="ShaderMaterial"'):
        end = i
        break

if start is None or end is None:
    raise SystemExit(f"block not found start={start} end={end}")

new_lines = lines[:start] + lines[end:]

out: list[str] = []
skip_ids = {"7_hibaj", "8_pdsj5", "9_ee4r6"}
inserted = False
for line in new_lines:
    if not inserted and line.startswith("[sub_resource"):
        out.append(
            '[ext_resource type="TileSet" uid="uid://c8farmground01" '
            'path="res://resources/tilesets/farm_ground.tres" id="16_farmts"]\n'
        )
        out.append(
            '[ext_resource type="Script" path="res://systems/terrain_system/terrain_map_bootstrap.gd" id="17_boot"]\n'
        )
        out.append("\n")
        inserted = True
    if any(f'id="{sid}"' in line for sid in skip_ids):
        continue
    out.append(line)

text = "".join(out)
text = text.replace('tile_set = SubResource("TileSet_272bh")', 'tile_set = ExtResource("16_farmts")')
text = text.replace(
    '[node name="TileMapLayerGround" type="TileMapLayer" parent="World" unique_id=325808929]\nposition = Vector2(58, 80)',
    '[node name="TileMapLayerGround" type="TileMapLayer" parent="World" unique_id=325808929]\nposition = Vector2(58, 80)\nscript = ExtResource("17_boot")',
)
p.write_text(text, encoding="utf-8")
print(f"patched {p}, removed {end - start} lines")
