@tool
extends EditorScript

## 编辑器一键脚本：文件 → 运行 → 选此文件，生成 farm_ground.tres

func _run() -> void:
	FarmTerrainTilesetBuilder.save_tileset()
	print("完成！请在 main.tscn 的 TileMapLayerGround 上确认 tile_set 指向 res://resources/tilesets/farm_ground.tres")
