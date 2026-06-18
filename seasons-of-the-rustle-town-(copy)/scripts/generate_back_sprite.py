"""Generate a back-view pixel art sprite from a reference sheet via Gemini."""
import base64
import json
import os
import sys
import urllib.request
from pathlib import Path

API_KEY = os.environ.get("GEMINI_API_KEY")
if not API_KEY:
    sys.exit("GEMINI_API_KEY not set")

INPUT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("art/characters/player/walkleft.png")
OUTPUT = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("art/characters/player/walkback.png")

image_bytes = INPUT.read_bytes()
image_b64 = base64.b64encode(image_bytes).decode("ascii")

prompt = (
    "This is a pixel art RPG character sprite sheet (side walk frames + front idle). "
    "Generate ONE new pixel art sprite of the SAME character viewed from directly BEHIND (back view, facing away from camera). "
    "Keep identical design: long teal/cyan hair flowing down the back, purple flat beret hat from behind, "
    "purple off-shoulder dress, elf ears slightly visible, same proportions and retro 16-bit pixel art style. "
    "Standing idle pose, black background, single sprite only (not a sheet). "
    "Match the scale of one sprite cell from the reference."
)

payload = {
    "contents": [
        {
            "parts": [
                {"text": prompt},
                {
                    "inline_data": {
                        "mime_type": "image/png",
                        "data": image_b64,
                    }
                },
            ]
        }
    ],
    "generationConfig": {
        "responseModalities": ["TEXT", "IMAGE"],
    },
}

models = [
    "gemini-2.5-flash-image",
    "gemini-3.1-flash-image",
    "gemini-3-pro-image",
    "imagen-4.0-fast-generate-001",
]

for model in models:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent?key={API_KEY}"
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except Exception as exc:
        print(f"{model}: failed - {exc}")
        continue

    candidates = data.get("candidates") or []
    if not candidates:
        print(f"{model}: no candidates - {data}")
        continue

    for part in candidates[0].get("content", {}).get("parts", []):
        inline = part.get("inlineData") or part.get("inline_data")
        if inline and inline.get("data"):
            OUTPUT.parent.mkdir(parents=True, exist_ok=True)
            OUTPUT.write_bytes(base64.b64decode(inline["data"]))
            print(f"Saved: {OUTPUT} (model: {model})")
            sys.exit(0)

    print(f"{model}: no image in response")

sys.exit("All models failed to return an image")
