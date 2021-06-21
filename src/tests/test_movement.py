from dataclasses import dataclass
from itertools import chain
from os import getcwd
from pathlib import Path
from struct import pack, unpack

import pytest


@dataclass
class MovementComponent:

    owner: int = 0
    xVel: int = 0
    yVel: int = 0

    def pack(self) -> bytes:
        return pack('<Hbb', self.owner, self.xVel, self.yVel)

    def unpack(self, data):
        self.owner, self.xVel, self.yVel = unpack('<Hbb', data)

    @classmethod
    def sizeof(cls):
        return 4


@pytest.fixture(scope='session')
def deps(compiler):
    src_dir = Path(getcwd()).joinpath('src')

    yield [
        compiler.compile(src_dir.joinpath(Path(p))) for p in [
            'components/movement.asm',
        ]
    ]


def test_component_creation(cpu, deps):
    components = [
        MovementComponent(0xdead, 3, -2),
        MovementComponent(0xbeef, 5, 0),
        MovementComponent(0x0, 0, 0),
        MovementComponent(0xbabe, -1, -1),
    ]

    # inject the components to BSS memory segment
    components_array = bytes(chain.from_iterable(cmp.pack() for cmp in components))
    cpu.memory[cpu.bss:cpu.bss + len(components_array)] = components_array

    cpu.compile_and_run('''
    .import init_movement_components
    .import create_movement_component

    .exportzp address_1, address_2

    .zeropage
        address_1: .res 2
        address_2: .res 2

    .code
        jsr init_movement_components

        lda #$ba
        sta address_1
        lda #$ab
        sta address_1 + 1
        jsr create_movement_component
        brk
    ''', link_with=deps)

    # unpack the third movement component from BSS memory
    comp = MovementComponent()
    addr = cpu.bss + MovementComponent.sizeof() * 2
    data = bytes(cpu.memory[addr:addr+MovementComponent.sizeof()])
    comp.unpack(data)
    # mamma mia, here I go again, my, my, how can I resist you?
    assert comp.owner == 0xabba
