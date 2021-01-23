"""ROM build tool"""
import argparse
import subprocess as sp
import pathlib
import os
import shutil


SRC_DIR = 'src'
OUT_DIR = 'build'
ROM = 'game.nes'
LINKER_CFG = 'rom.cfg'

ASSEMBLER = 'ca65.exe'
LINKER = 'ld65.exe'


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
    return sp.run(args, capture_output=True)


def run_linker(linker, cfg_file, input_files, out_file):
    args = [
        str(linker),
        '-C', str(cfg_file),
        '-o', str(out_file),
    ]
    args.extend([str(i) for i in input_files])

    return sp.run(args, capture_output=True)


def prepare_folder_structure(out_dir):
    out_dir_path = pathlib.Path(out_dir)
    if out_dir_path.exists():
        shutil.rmtree(out_dir_path)

    os.mkdir(out_dir_path)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('-l', type=executable_path, dest='linker')
    parser.add_argument('-a', type=executable_path, dest='assembler')

    args = parser.parse_args()

    prepare_folder_structure(OUT_DIR)

    assembler = args.assembler or ASSEMBLER
    linker = args.linker or LINKER

    # collect asm files and compile them
    success = True
    for asm_file in pathlib.Path(SRC_DIR).glob('*.asm'):
        o_file = pathlib.Path(OUT_DIR).joinpath(f'{asm_file.stem}.o')

        try:
            run_assembler(assembler, asm_file, o_file).check_returncode()
        except sp.CalledProcessError as err:
            msg = (err.stdout or err.stderr).decode('utf8').strip()
            print(f'{asm_file}: {msg}')
            success = False

        print(o_file)

    if success:
        obj_files = pathlib.Path(OUT_DIR).glob('*.o')
        cfg_file = pathlib.Path('.').joinpath(LINKER_CFG)
        rom_file = pathlib.Path(OUT_DIR).joinpath(ROM)
        try:
            run_linker(linker, cfg_file, obj_files, rom_file).check_returncode()
            print(rom_file)
        except sp.CalledProcessError as err:
            msg = (err.stdout or err.stderr).decode('utf8').strip()
            print(f'{rom_file}: {msg}')
            success = False

    print('done' if success else 'failed')


if __name__ == '__main__':
    main()
