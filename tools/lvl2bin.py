from os import path

import click
import yaml
from PIL import Image


def bmp_to_nametable(bmp_filename) -> bytes:
    """
    Convert a BMP file to a nametable map.

    The input BMP file must be 32x30 pixels.

    Colors are converted to grayscale and then mapped to tile indices, the
    darker being the lower.
    """

    im = Image.open(bmp_filename).convert('L')
    if im.size != (32, 30):
        raise click.UsageError('A 32x30 BMP file must be supplied!')

    rawdata = im.tobytes()

    levels = list(sorted(set(rawdata)))

    nametable = bytearray(960)
    for i, px in enumerate(rawdata):
        nametable[i] = levels.index(px)

    return nametable


@click.command()
@click.argument('level_yaml', type=click.File('r'))
@click.argument('level_bin', type=click.File('wb'))
def lvl2bin(level_yaml, level_bin):
    """
    Generate level binary data file from YAML metadata file.
    """

    level = yaml.load(level_yaml, yaml.Loader)

    level_dir = path.dirname(level_yaml.name)

    cache = {}

    for screen_filename in level['screens']:
        if screen_filename not in cache:
            nametable = bmp_to_nametable(path.join(level_dir, screen_filename))
            cache[screen_filename] = nametable

        level_bin.write(cache[screen_filename])


if __name__ == '__main__':
    lvl2bin()  # pylint: disable=no-value-for-parameter
