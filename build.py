"""ROM build tool"""
import argparse
import subprocess as sp
import pathlib
import os
import shutil


SRC_DIR = 'src'
BIN_DIR = 'assets'
OUT_DIR = 'build'
ROM = 'game.nes'
LINKER_CFG = 'rom.cfg'

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
        'python', str(tool),
        str(src),
        str(dst),
    ]
    print(' '.join(args))
    return run(args)


def run_bmp2lvl(tool, src, dst):
    args = [
        'python', str(tool),
        str(src),
        str(dst),
    ]
    print(' '.join(args))
    return run(args)



def prepare_folder_structure(out_dir):
    out_dir_path = pathlib.Path(out_dir)
    if out_dir_path.exists():
        shutil.rmtree(out_dir_path)

    os.mkdir(out_dir_path)
    os.mkdir(out_dir_path.joinpath('levels'))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-l', type=executable_path, dest='linker')
    parser.add_argument('-a', type=executable_path, dest='assembler')

    args = parser.parse_args()

    prepare_folder_structure(OUT_DIR)

    assembler = args.assembler or ASSEMBLER
    linker = args.linker or LINKER
    bmp2chr = pathlib.Path('.').joinpath('.', 'tools', 'bmp2chr.py')
    bmp2lvl = pathlib.Path('.').joinpath('.', 'tools', 'bmp2lvl.py')

    success = True

    # collect bitmap files and convert them to CHR files
    for bmp_file in pathlib.Path(BIN_DIR).glob('*.bmp'):
        o_file = pathlib.Path(OUT_DIR).joinpath(f'{bmp_file.stem}.chr')

        try:
            run_bmp2chr(bmp2chr, bmp_file, o_file).check_returncode()
        except sp.CalledProcessError as err:
            msg = (err.stdout or err.stderr).decode('utf8').strip()
            print(f'{bmp_file}: {msg}')
            success = False
            break

    # collect level files and convert them to CHR files
    if success:
        for bmp_file in pathlib.Path(BIN_DIR).joinpath('levels').glob('*.bmp'):
            o_file = pathlib.Path(OUT_DIR).joinpath('levels', f'{bmp_file.stem}.lvl')

            try:
                run_bmp2lvl(bmp2lvl, bmp_file, o_file).check_returncode()
            except sp.CalledProcessError as err:
                msg = (err.stdout or err.stderr).decode('utf8').strip()
                print(f'{bmp_file}: {msg}')
                success = False
                break

    # collect asm files and compile them
    if success:
        for asm_file in pathlib.Path(SRC_DIR).glob('*.asm'):
            o_file = pathlib.Path(OUT_DIR).joinpath(f'{asm_file.stem}.o')

            try:
                run_assembler(assembler, asm_file, o_file).check_returncode()
            except sp.CalledProcessError as err:
                msg = (err.stdout or err.stderr).decode('utf8').strip()
                print(f'{asm_file}: {msg}')
                success = False
            except FileNotFoundError:
                print(f'{assembler} not found')
                success = False
                break

    if success:
        obj_files = pathlib.Path(OUT_DIR).glob('*.o')
        cfg_file = pathlib.Path('.').joinpath(LINKER_CFG)
        rom_file = pathlib.Path(OUT_DIR).joinpath(ROM)
        try:
            run_linker(linker, cfg_file, obj_files, rom_file).check_returncode()
        except sp.CalledProcessError as err:
            msg = (err.stdout or err.stderr).decode('utf8').strip()
            print(f'{rom_file}: {msg}')
            success = False
        except FileNotFoundError:
            print(f'{linker} not found')
            success = False

    print('done' if success else 'failed')


if __name__ == '__main__':
    main()
