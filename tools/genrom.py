import datetime
from os import path

import click
import yaml
from jinja2 import Environment, FileSystemLoader

_PREAMBLE = '''\
;
; DO NOT EDIT MANUALLY THIS FILE!
; AUTO-GENERATED ON {timestamp}
;
'''


@click.command()
@click.argument('cfg_yaml', type=click.File('r'))
@click.argument('out_asm', type=click.File('w'))
def build(cfg_yaml, out_asm):
    """
    Generate game data embedding boilerplate code.
    """
    cfg = yaml.load(cfg_yaml, yaml.Loader)

    # The path of the build config YAML file is considered to be the root of the
    # project
    cfg_dir = path.dirname(path.realpath(cfg_yaml.name))

    # Compute the location of `assets` directory relateive to the output file
    assets_dir = path.join(cfg_dir, 'assets')
    assets_reldir = path.relpath(assets_dir, path.dirname(path.realpath(out_asm.name)))
    assert path.exists(assets_reldir), f'{assets_reldir} not found'

    # Utility function for obtaining relative asset paths
    def asset_relpath(file_path):
        return path.relpath(
            path.normpath(path.join(assets_reldir, file_path)),
            path.dirname(path.realpath(out_asm.name)))

    # Level directory
    level_dir = asset_relpath(path.join(cfg_dir, cfg['level']))
    assert path.exists(level_dir), f'{level_dir} not found'

    # Utility function for obtaining paths relative to the output file from
    # paths relative to level directory
    def level_relpath(file_path):
        return path.normpath(path.join(level_dir, file_path))

    # Load level spec
    with open(level_relpath('level.yaml')) as level_yaml:
        level = yaml.load(level_yaml, yaml.Loader)

    assert len(level['tilesets']) == 2, f'Exactly two tilesets are supported currently!'

    tmplenv = Environment(loader=FileSystemLoader('.'))
    template = tmplenv.get_template('rom.asm.in')

    vars = {
        'preamble': _PREAMBLE.format(timestamp=datetime.datetime.now()),
        'tilesets': [level_relpath(filename) for filename in level['tilesets']],
        'level': path.join(level_dir, 'level.bin'),
    }

    out_asm.write(template.render(**vars))


if __name__ == '__main__':
    build()
