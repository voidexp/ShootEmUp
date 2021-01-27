import click
from PIL import Image


@click.command()
@click.argument('in_file', type=click.File('rb'))
@click.argument('out_file', type=click.File('wb'))
def bmp2lvl(in_file, out_file):
    """
    Convert a BMP file to a LVL file.

    The input BMP file must be 32x30 pixels.

    Colors are converted to grayscale and then mapped to tile indices, the
    darker being the lower.
    """

    im = Image.open(in_file).convert('L')
    if im.size != (32, 30):
        raise click.UsageError('A 32x30 BMP file must be supplied!')

    rawdata = im.tobytes()

    levels = list(sorted(set(rawdata)))

    lvldata = bytearray(960)
    for i, px in enumerate(rawdata):
        lvldata[i] = levels.index(px)

    out_file.write(lvldata)


if __name__ == '__main__':
    bmp2lvl()  # pylint: disable=no-value-for-parameter
