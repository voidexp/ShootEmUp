import os
import pathlib
import shutil
import subprocess as sp
import sys

import click


SRC_DIR = 'src'
BIN_DIR = 'assets'
OUT_DIR = 'build'
ROM = 'game.nes'
LINKER_CFG = 'rom.cfg'
MAIN = 'main.asm'

ASSEMBLER = 'ca65.exe'
LINKER = 'ld65.exe'


def run(args):
    return sp.run(args, capture_output=True, env=os.environ)


def executable_path(path):
    p = pathlib.Path(path)
    if not p.exists():
        raise ValueError('not found')
    if not p.is_file():
        raise ValueError('not a file')

    return p


def run_assembler(assembler, src, dst):
    args = [
        str(assembler),
        '-I', os.path.join(os.getcwd(), 'src'),
        '-o', str(dst),
        str(src),
    ]
    print(' '.join(args))
    return run(args)


def run_linker(linker, cfg_file, input_files, out_file):
    args = [
        str(linker),
        '-C', str(cfg_file),
        '-o', str(out_file),
    ]
    args.extend([str(i) for i in input_files])
    print(' '.join(args))
    return run(args)


def run_bmp2chr(tool, src, dst):
    args = [
        sys.executable, str(tool),
        str(src),
        str(dst),
    ]
    print(' '.join(args[1:]))
    return sp.run(args, capture_output=True)


def run_bmp2lvl(tool, src, dst):
    args = [
        sys.executable, str(tool),
        str(src),
        str(dst),
    ]
    print(' '.join(args[1:]))
    return sp.run(args, capture_output=True)


def prepare_folder_structure(out_dir):
    out_dir_path = pathlib.Path(out_dir)
    out_dir_path.mkdir(exist_ok=True, parents=True)
    out_dir_path.joinpath('levels').mkdir(exist_ok=True, parents=True)


def is_up_to_date(src: pathlib.Path, dst: pathlib.Path()):
    return dst.exists() and dst.stat().st_mtime >= src.stat().st_mtime


@click.command()
@click.option('-l', '--linker', type=click.Path(file_okay=True, dir_okay=False))
@click.option('-a', '--assembler', type=click.Path(file_okay=True, dir_okay=False))
def build(linker, assembler):
    prepare_folder_structure(OUT_DIR)

    linker = linker or LINKER
    assembler = assembler or ASSEMBLER
    bmp2chr = pathlib.Path('.').joinpath('.', 'tools', 'bmp2chr.py')
    bmp2lvl = pathlib.Path('.').joinpath('.', 'tools', 'bmp2lvl.py')

    success = True
    relink = False

    # collect bitmap files and convert them to CHR files
    for bmp_file in pathlib.Path(BIN_DIR).glob('*.bmp'):
        o_file = pathlib.Path(OUT_DIR).joinpath(f'{bmp_file.stem}.chr')

        if is_up_to_date(bmp_file, o_file):
            continue

        try:
            run_bmp2chr(bmp2chr, bmp_file, o_file).check_returncode()
            relink = True
        except sp.CalledProcessError as err:
            msg = (err.stdout or err.stderr).decode('utf8').strip()
            print(f'{bmp_file}: {msg}')
            success = False
            break

    # collect level files and convert them to CHR files
    if success:
        for bmp_file in pathlib.Path(BIN_DIR).joinpath('levels').glob('*.bmp'):
            o_file = pathlib.Path(OUT_DIR).joinpath(
                'levels', f'{bmp_file.stem}.lvl')

            if is_up_to_date(bmp_file, o_file):
                continue

            try:
                run_bmp2lvl(bmp2lvl, bmp_file, o_file).check_returncode()
                relink = True
            except sp.CalledProcessError as err:
                msg = (err.stdout or err.stderr).decode('utf8').strip()
                print(f'{bmp_file}: {msg}')
                success = False
                break

    # compile assembly files
    if success:
        for asm_file in pathlib.Path(SRC_DIR).rglob('*.asm'):
            prefix = pathlib.Path(OUT_DIR).joinpath(asm_file.parent)
            prefix.mkdir(parents=True, exist_ok=True)
            o_file = prefix.joinpath(f'{asm_file.stem}.o')

            if is_up_to_date(asm_file, o_file):
                continue

            try:
                run_assembler(assembler, asm_file, o_file).check_returncode()
                relink = True
            except sp.CalledProcessError as err:
                msg = (err.stdout or err.stderr).decode('utf8').strip()
                print(f'{asm_file}: {msg}')
                success = False
            except FileNotFoundError:
                print(f'{assembler} not found')
                success = False

    if success and relink:
        obj_files = pathlib.Path(OUT_DIR).rglob('*.o')
        cfg_file = pathlib.Path('.').joinpath(LINKER_CFG)
        rom_file = pathlib.Path(OUT_DIR).joinpath(ROM)
        try:
            run_linker(linker, cfg_file, obj_files,
                       rom_file).check_returncode()
        except sp.CalledProcessError as err:
            msg = (err.stdout or err.stderr).decode('utf8').strip()
            print(f'{rom_file}: {msg}')
            success = False
        except FileNotFoundError:
            print(f'{linker} not found')
            success = False

    if success:
        if relink:
            print('done')
        else:
            print('up to date')
    else:
        print('failed')


if __name__ == '__main__':
    build()
