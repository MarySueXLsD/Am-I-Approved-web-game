"""Gray out menu_image.png except the Cool Math Bank building."""
from PIL import Image, ImageDraw

SRC_COLOR = r"static/Main_Menu/menu_image_preview_check.png"
OUT = r"static/Main_Menu/menu_image.png"
PREVIEW = r"static/Main_Menu/_bank_mask_preview.png"

# Bank footprint on the 1535x1024 menu art.
BANK_BOX_RATIOS = (0.365, 0.248, 0.635, 0.738)


def to_gray(rgba):
    r, g, b, a = rgba
    if a == 0:
        return (0, 0, 0, 0)
    gray = int(0.299 * r + 0.587 * g + 0.114 * b)
    return (gray, gray, gray, a)


def is_sky(r, g, b):
    return b > 170 and r < 140 and g > 130


def is_foliage(r, g, b):
    return g > r + 20 and g > b + 10 and g > 90


def keep_bank_pixel(x, y, rgba, box, w, h):
    if rgba[3] == 0:
        return False

    if x < box[0] or x > box[2] or y < box[1] or y > box[3]:
        return False

    r, g, b, _a = rgba
    ny = y / h

    if is_sky(r, g, b):
        return False

    # Background trees visible through the portico and beside the facade.
    if is_foliage(r, g, b) and ny < 0.69:
        return False

    return True


def gray_except_bank(img):
    w, h = img.size
    box = tuple(int(v * (w if i % 2 == 0 else h)) for i, v in enumerate(BANK_BOX_RATIOS))
    src_px = img.load()
    out = Image.new("RGBA", (w, h))

    for y in range(h):
        for x in range(w):
            rgba = src_px[x, y]
            if keep_bank_pixel(x, y, rgba, box, w, h):
                out.putpixel((x, y), rgba)
            else:
                out.putpixel((x, y), to_gray(rgba))

    return out, box


def main():
    img = Image.open(SRC_COLOR).convert("RGBA")
    preview = img.copy()
    result, box = gray_except_bank(img)

    draw = ImageDraw.Draw(preview)
    draw.rectangle(box, outline=(255, 0, 0, 255), width=4)
    preview.save(PREVIEW)
    result.save(OUT)
    print(f"Updated {OUT}")
    print(f"Bank box: {box}")


if __name__ == "__main__":
    main()
