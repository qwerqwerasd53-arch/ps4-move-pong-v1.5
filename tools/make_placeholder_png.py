#!/usr/bin/env python3
"""
سازنده‌ی ساده‌ی PNG بدون هیچ وابستگی خارجی (فقط zlib و struct از کتابخانه‌ی
استاندارد پایتون) برای ساختن آیکون/تصویر جایگزین موقت که فرمت پکیج PS4
(icon0.png, pic1.png) بهش نیاز داره. یه مربع تک‌رنگ ساده تولید می‌کنه.

استفاده:
    python3 make_placeholder_png.py <output.png> <width> <height> [R G B]
"""
import struct
import sys
import zlib


def write_png(path, width, height, color=(20, 60, 90)):
    def chunk(tag, data):
        return (
            struct.pack(">I", len(data))
            + tag
            + data
            + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
        )

    signature = b"\x89PNG\r\n\x1a\n"
    # color type 2 = truecolor (RGB), bit depth 8
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)

    row = bytes(color) * width
    raw = b"".join(b"\x00" + row for _ in range(height))  # filter type 0 per scanline
    idat = zlib.compress(raw, 9)

    png = signature + chunk(b"IHDR", ihdr) + chunk(b"IDAT", idat) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


if __name__ == "__main__":
    out_path = sys.argv[1]
    w = int(sys.argv[2])
    h = int(sys.argv[3])
    rgb = (20, 60, 90)
    if len(sys.argv) >= 7:
        rgb = (int(sys.argv[4]), int(sys.argv[5]), int(sys.argv[6]))
    write_png(out_path, w, h, rgb)
    print(f"Wrote {out_path} ({w}x{h})")
