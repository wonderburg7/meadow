"""Render the first 32×32 Meadow terrain tile without filtering or antialiasing."""

from pathlib import Path

from PIL import Image, ImageDraw

TRANSPARENT = (0, 0, 0, 0)
SOIL_DARK = (92, 52, 34, 255)
SOIL_MID = (130, 75, 43, 255)
SOIL_LIGHT = (177, 111, 60, 255)
GRASS_SHADE = (51, 111, 49, 255)
GRASS_BASE = (67, 142, 56, 255)
GRASS_LIGHT = (100, 174, 69, 255)
GRASS_SUN = (137, 193, 83, 255)


def top_bounds(y: int) -> tuple[int, int] | None:
    """Return the unoutlined, 32-pixel-wide flat-topped hex span for a row."""
    if not 0 <= y <= 25:
        return None
    if y <= 7:
        return 8 - y, 23 + y
    if y <= 17:
        return 0, 31
    return y - 17, 48 - y


def on_top(x: int, y: int) -> bool:
    bounds = top_bounds(y)
    return bounds is not None and bounds[0] <= x <= bounds[1]


def draw_sprite(output_path: Path) -> None:
    image = Image.new("RGBA", (32, 32), TRANSPARENT)
    draw = ImageDraw.Draw(image)

    # Only the lower three edges expose soil; same-level adjacent grass uses
    # transition variants instead of a visible outline.
    draw.polygon(
        [(0, 17), (8, 25), (23, 25), (31, 17), (31, 22), (23, 31), (8, 31), (0, 22)],
        fill=SOIL_MID,
    )
    for x in range(8, 24):
        image.putpixel((x, 30), SOIL_DARK)
    for x, y in [(3, 20), (6, 23), (10, 27), (14, 29), (19, 28), (25, 25), (28, 21)]:
        image.putpixel((x, y), SOIL_LIGHT)
    for x, y in [(2, 21), (5, 24), (12, 28), (17, 30), (22, 27), (27, 23), (29, 20)]:
        image.putpixel((x, y), SOIL_DARK)

    for y in range(26):
        bounds = top_bounds(y)
        assert bounds is not None
        for x in range(bounds[0], bounds[1] + 1):
            image.putpixel((x, y), GRASS_BASE)

    def mark(x: int, y: int, color: tuple[int, int, int, int]) -> None:
        if on_top(x, y):
            image.putpixel((x, y), color)

    # Fine mottling and low plant clusters stay away from the edges, so this
    # base tile can blend with future dry/wet/snow transition variants.
    for x, y in [(11, 4), (16, 5), (7, 10), (13, 9), (20, 10), (25, 11), (4, 15), (10, 16), (17, 15), (23, 16), (28, 15), (8, 20), (14, 21), (21, 20)]:
        mark(x, y, GRASS_LIGHT)
    for x, y in [(12, 5), (18, 7), (5, 13), (15, 11), (21, 13), (26, 14), (9, 18), (18, 18), (24, 19), (13, 23)]:
        mark(x, y, GRASS_SHADE)
    for x, y in [(14, 4), (9, 11), (19, 12), (6, 16), (16, 17), (25, 17), (11, 21), (20, 21)]:
        mark(x, y, GRASS_SUN)

    def blade(x: int, y: int) -> None:
        for px, py, color in [(x, y, GRASS_SHADE), (x + 1, y - 1, GRASS_LIGHT), (x + 1, y - 2, GRASS_SUN), (x - 1, y, GRASS_SHADE), (x - 2, y - 1, GRASS_LIGHT)]:
            mark(px, py, color)

    for origin in [(11, 9), (21, 8), (6, 16), (16, 15), (26, 16), (11, 21), (20, 21)]:
        blade(*origin)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    image.save(output_path)


if __name__ == "__main__":
    draw_sprite(Path(__file__).parent.parent / "assets" / "sprites" / "environment" / "grass_base.png")
