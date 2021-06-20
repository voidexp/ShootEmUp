import os
import pathlib
import subprocess as sp
import tempfile
from typing import List

import pytest
from py65.devices.mpu6502 import MPU

ROM_CFG = pathlib.Path(__file__).parent.joinpath(f'test_rom.cfg')
ORG = 0xC000


class CompileError(Exception):
    pass


class LinkError(Exception):
    pass


def ca65(srcfile, dstfile):
    try:
        sp.run(['ca65', str(srcfile), '-o', str(dstfile)]).check_returncode()
    except sp.CalledProcessError as err:
        raise CompileError(str(err.output))


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

    def compile_and_run(self, code):
        self.reset()

        with tempfile.NamedTemporaryFile(suffix='.asm', delete=False) as srcfile:
            srcfile.write(code.encode('utf8'))

        objfile = self.compiler.compile(pathlib.Path(srcfile.name))

        test_name = os.environ.get('PYTEST_CURRENT_TEST').split()[0].split(':')[-1]
        romfile = self.compiler.link([objfile], f'{test_name}.nes')

        with open(romfile, 'rb') as rom:
            mem = rom.read()
            self.memory[ORG:ORG + len(mem)] = mem

        self.pc = ORG

        while not self.p & self.INTERRUPT:
            self.step()


@pytest.fixture(scope='session')
def cpu(request):
    with tempfile.TemporaryDirectory() as build_dir:
        compiler = Compiler(pathlib.Path(build_dir))
        yield CPU(compiler)
