"""Package native SVG renders into a Windows multi-resolution ICO, unchanged."""
from pathlib import Path
import struct

root = Path(__file__).resolve().parents[1]
sizes = [16, 24, 32, 48, 64, 128, 256]
images = [(size, (root / f"tmp/icons/maai-{size}.png").read_bytes()) for size in sizes]
offset = 6 + 16 * len(images)
header = struct.pack("<HHH", 0, 1, len(images))
entries = []
for size, image in images:
    entries.append(struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32, len(image), offset))
    offset += len(image)
(root / "art/branding/maai.ico").write_bytes(header + b"".join(entries) + b"".join(data for _, data in images))
print("Windows icon: seven resolutions, 16–256 px")
