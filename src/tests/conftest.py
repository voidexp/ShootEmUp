import os
import pathlib
import subprocess as sp
import tempfile
from typing import List, Sequence

import pytest
from py65.devices.mpu6502 import MPU

INC_DIR = pathlib.Path(os.getcwd()).joinpath('src')
ROM_CFG = pathlib.Path(__file__).parent.joinpath(f'test_rom.cfg')
ORG = 0xC000


class CompileError(Exception):
    pass


class LinkError(Exception):
    pass


def ca65(srcfile, dstfile):
    try:
        sp.run([
            'ca65',
            '-I',
            str(INC_DIR),
            str(srcfile),
            '-o',
            str(dstfile)
        ]).check_returncode()
    except sp.CalledProcessError as err:
        output = str(err.output)
        if srcfile.exists():
            output += srcfile.read_text()
        raise CompileError(output)


def cl65(input_files, out_file):
    args = [
        'cl65',
        '-C',
        str(ROM_CFG),
    ] + [
        str(path) for path in input_files
    ] + [
        '-o',
        str(out_file)
    ]
    try:
        sp.run(args).check_returncode()
    except sp.CalledProcessError as err:
        raise LinkError(str(err))


class Compiler:

    def __init__(self, build_dir):
        self.build_dir = build_dir

    def compile(self, srcfile: pathlib.Path) -> pathlib.Path:
        name = srcfile.stem
        dstfile = self.build_dir.joinpath(f'{name}.o')

        if not dstfile.exists():
            ca65(srcfile, dstfile)

        return dstfile

    def link(self, obj_files: List[pathlib.Path], rom_name: str) -> pathlib.Path:
        rom_file = self.build_dir.joinpath(rom_name)
        cl65(obj_files, rom_file)
        return rom_file


class CPU(MPU):

    def __init__(self, compiler):
        super().__init__()
        self.compiler = compiler
        self.org = ORG
        self.bss = 0x200

    def compile_and_run(self, code: str, link_with: Sequence[pathlib.Path]=()):
        self.reset()

        with tempfile.NamedTemporaryFile(suffix='.asm', delete=False) as srcfile:
            srcfile.write(code.encode('utf8'))

        objfiles = [self.compiler.compile(pathlib.Path(srcfile.name))]
        objfiles.extend(link_with)

        pathlib.Path(srcfile.name).unlink()

        test_name = os.environ.get('PYTEST_CURRENT_TEST').split()[0].split(':')[-1]
        romfile = self.compiler.link(objfiles, f'{test_name}.nes')

        with open(romfile, 'rb') as rom:
            mem = rom.read()
            self.memory[ORG:ORG + len(mem)] = mem

        self.pc = ORG

        while not self.p & self.INTERRUPT:
            self.step()


@pytest.fixture(scope='session')
def compiler():
    with tempfile.TemporaryDirectory() as build_dir:
        yield Compiler(pathlib.Path(build_dir))


@pytest.fixture(scope='session')
def cpu(compiler):
    yield CPU(compiler)
