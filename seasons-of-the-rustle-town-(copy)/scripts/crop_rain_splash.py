"""从 rain..png 裁出水花帧（第 2–4 帧）与雨丝帧（第 1 帧）。"""
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    raise SystemExit("需要 Pillow: pip install pillow")

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art/items/TileSheets/rain..png"
SPLASH_DST = ROOT / "art/items/TileSheets/rain_splash.png"
DROP_DST = ROOT / "art/items/TileSheets/rain_drop.png"

img = Image.open(SRC)
w, h = img.size
frame_w = w // 4
SPLASH_DST.parent.mkdir(parents=True, exist_ok=True)
img.crop((frame_w, 0, w, h)).save(SPLASH_DST)
img.crop((0, 0, frame_w, h)).save(DROP_DST)
print(f"source={w}x{h} frame={frame_w}x{h}")
print(f"splash->{SPLASH_DST.name} drop->{DROP_DST.name}")
