import click
from PIL import Image


@click.command()
@click.argument('in_file', type=click.File('rb'))
@click.argument('out_file', type=click.File('wb'))
def bmp2chr(in_file, out_file):
    """
    Convert a BMP file to a NES-compatible CHR file.

    The input BMP file must be 128x128 pixels and have at most 4 colors in order
    to be properly indexed.

    Indices are generated so that the darkest colors will have lower indices.
    """

    im = Image.open(in_file).convert('L')
    if im.size != (128, 128):
        raise click.UsageError('A 128x128 BMP file must be supplied!')

    rawdata = im.tobytes()

    levels = list(sorted(set(rawdata)))
    if len(levels) > 4:
        raise click.UsageError('The BMP file must have at most 4 colors!')

    chrdata = bytearray(4096)

    for p, px in enumerate(rawdata):
        # find the (x,y) coordinate of the pixel
        y = p // 128
        x = p % 128

        # find the (c,r) index of the tile
        c = x // 8
        r = y // 8

        # compute the byte offset in the buffer
        offset = r * 256 + c * 16 + (y % 8)
        # number of bits to shift to left based on the x coord
        shift = 7 - (x % 8)
        # indexed color, 0 = background/transparent
        color = levels.index(px)

        # store the bit on the relative planes
        if color == 1:
            chrdata[offset] |= 1 << shift
        elif color == 2:
            chrdata[offset + 8] |= 1 << shift
        elif color == 3:
            chrdata[offset] |= 1 << shift
            chrdata[offset + 8] |= 1 << shift

    out_file.write(chrdata)


if __name__ == '__main__':
    bmp2chr()  # pylint: disable=no-value-for-parameter
