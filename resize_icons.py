#!/usr/bin/env python3
"""Generate Android mipmap icons from a source PNG using only Python stdlib."""
import struct
import zlib
import os

SIZES = {
    'mipmap-mdpi':    48,
    'mipmap-hdpi':    72,
    'mipmap-xhdpi':   96,
    'mipmap-xxhdpi':  144,
    'mipmap-xxxhdpi': 192,
}

RES_DIR = 'android/app/src/main/res'

def read_png(path):
    with open(path, 'rb') as f:
        data = f.read()
    assert data[:8] == b'\x89PNG\r\n\x1a\n', "Not a PNG file"

    pos = 8
    chunks = []
    while pos < len(data):
        length = struct.unpack('>I', data[pos:pos+4])[0]
        ctype = data[pos+4:pos+8]
        cdata = data[pos+8:pos+8+length]
        pos += 12 + length
        chunks.append((ctype, cdata))

    ihdr = chunks[0][1]
    width, height = struct.unpack('>II', ihdr[:8])
    bit_depth = ihdr[8]
    color_type = ihdr[9]
    assert bit_depth == 8, f"Only 8-bit depth supported, got {bit_depth}"

    # bpp by color type
    bpp_map = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}
    assert color_type in bpp_map, f"Unsupported color type {color_type}"
    bpp = bpp_map[color_type]

    # palette for indexed
    palette = None
    if color_type == 3:
        for ct, cd in chunks:
            if ct == b'PLTE':
                palette = [cd[i*3:(i+1)*3] for i in range(len(cd)//3)]
                break

    idat = b''.join(cd for ct, cd in chunks if ct == b'IDAT')
    raw = zlib.decompress(idat)

    stride = width * bpp
    rows = []
    prev = bytes(stride)
    i = 0
    for _ in range(height):
        ft = raw[i]; i += 1
        row = bytearray(raw[i:i+stride]); i += stride
        if ft == 1:
            for x in range(bpp, stride):
                row[x] = (row[x] + row[x-bpp]) & 0xFF
        elif ft == 2:
            for x in range(stride):
                row[x] = (row[x] + prev[x]) & 0xFF
        elif ft == 3:
            for x in range(stride):
                a = row[x-bpp] if x >= bpp else 0
                row[x] = (row[x] + (a + prev[x]) // 2) & 0xFF
        elif ft == 4:
            for x in range(stride):
                a = row[x-bpp] if x >= bpp else 0
                b = prev[x]
                c = prev[x-bpp] if x >= bpp else 0
                p = a + b - c
                pa, pb, pc = abs(p-a), abs(p-b), abs(p-c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                row[x] = (row[x] + pr) & 0xFF
        rows.append(bytes(row))
        prev = bytes(row)

    # Convert indexed to RGBA
    if color_type == 3 and palette:
        rgba_rows = []
        for row in rows:
            rgba = bytearray(width * 4)
            for x in range(width):
                p = palette[row[x]]
                rgba[x*4:x*4+3] = p
                rgba[x*4+3] = 255
            rgba_rows.append(bytes(rgba))
        return width, height, 4, 6, rgba_rows

    # Convert RGB to RGBA for consistency
    if color_type == 2:
        rgba_rows = []
        for row in rows:
            rgba = bytearray(width * 4)
            for x in range(width):
                rgba[x*4:x*4+3] = row[x*3:x*3+3]
                rgba[x*4+3] = 255
            rgba_rows.append(bytes(rgba))
        return width, height, 4, 6, rgba_rows

    return width, height, bpp, color_type, rows


def resize(rows, sw, sh, bpp, dw, dh):
    out = []
    for y in range(dh):
        sy = y * (sh - 1) / max(dh - 1, 1)
        y0 = int(sy); y1 = min(y0+1, sh-1); fy = sy - y0
        row = bytearray(dw * bpp)
        for x in range(dw):
            sx = x * (sw - 1) / max(dw - 1, 1)
            x0 = int(sx); x1 = min(x0+1, sw-1); fx = sx - x0
            for c in range(bpp):
                p00 = rows[y0][x0*bpp+c]
                p01 = rows[y0][x1*bpp+c]
                p10 = rows[y1][x0*bpp+c]
                p11 = rows[y1][x1*bpp+c]
                v = p00*(1-fx)*(1-fy) + p01*fx*(1-fy) + p10*(1-fx)*fy + p11*fx*fy
                row[x*bpp+c] = min(255, int(v + 0.5))
        out.append(bytes(row))
    return out


def write_png(path, rows, w, h, bpp, color_type):
    def chunk(ct, data):
        crc = zlib.crc32(ct + data) & 0xFFFFFFFF
        return struct.pack('>I', len(data)) + ct + data + struct.pack('>I', crc)

    ihdr = struct.pack('>IIBBBBB', w, h, 8, color_type, 0, 0, 0)
    raw = b''.join(b'\x00' + r for r in rows)
    compressed = zlib.compress(raw, 6)

    out = b'\x89PNG\r\n\x1a\n'
    out += chunk(b'IHDR', ihdr)
    out += chunk(b'IDAT', compressed)
    out += chunk(b'IEND', b'')
    with open(path, 'wb') as f:
        f.write(out)


def main():
    src = 'assets/icon/icon.png'
    print(f'Reading {src}...')
    sw, sh, bpp, ct, rows = read_png(src)
    print(f'  Source: {sw}x{sh}, bpp={bpp}, color_type={ct}')

    for dname, size in SIZES.items():
        out_dir = os.path.join(RES_DIR, dname)
        os.makedirs(out_dir, exist_ok=True)
        out_path = os.path.join(out_dir, 'ic_launcher.png')
        print(f'  Generating {size}x{size} → {out_path}')
        resized = resize(rows, sw, sh, bpp, size, size)
        write_png(out_path, resized, size, size, bpp, ct)
        # Also write ic_launcher_round.png (same image)
        round_path = os.path.join(out_dir, 'ic_launcher_round.png')
        write_png(round_path, resized, size, size, bpp, ct)

    print('Done.')

if __name__ == '__main__':
    main()
