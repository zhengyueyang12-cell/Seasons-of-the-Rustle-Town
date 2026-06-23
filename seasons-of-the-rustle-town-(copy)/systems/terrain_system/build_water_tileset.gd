@tool
extends EditorScript

## 文件 → 运行 → 选此脚本，生成 water_surface.tres


func _run() -> void:
	WaterTilesetBuilder.save_tileset()
	print("完成！在 TileMapLayerWater 上用占位水格绘制河道。")
