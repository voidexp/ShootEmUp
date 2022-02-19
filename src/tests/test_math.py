import pathlib

import pytest


@pytest.fixture
def math(compiler):
    yield compiler.compile(pathlib.Path('src/math.asm'))


@pytest.mark.parametrize('rect1,rect2,collision', (
    #  +---+
    #  |   |
    #  +---+
    #  +---+
    #  |   |
    #  +---+
    ((20, 30, 50, 60), (20, 61, 50, 90), False),
    ((20, 61, 50, 90), (20, 30, 50, 60), False),
    #  +---+ +---+
    #  |   | |   |
    #  +---+ +---+
    ((20, 30, 50, 60), (51, 30, 80, 60), False),
    ((51, 30, 80, 60), (20, 30, 50, 60), False),
    #  +---+
    #  |   |
    #  +---+
    #       +---+
    #       |   |
    #       +---+
    ((20, 30, 50, 60), (51, 61, 80, 90), False),
    ((51, 61, 80, 90), (20, 30, 50, 60), False),
    #  +---------+
    #  |         |
    #  |   +-+   |
    #  |   | |   |
    #  |   +-+   |
    #  |         |
    #  +---------+
    ((20, 30, 50, 60), (25, 35, 40, 50), True),
    ((25, 35, 40, 50), (20, 30, 50, 60), True),
    #  +---+--+---+
    #  |   |  |   |
    #  +---+--+---+
    ((20, 30, 50, 60), (25, 30, 45, 60), True),
    ((25, 30, 45, 60), (20, 30, 50, 60), True),
    #  +---+
    #  |   |
    #  +---+
    #  |   |
    #  +---+
    #  |   |
    #  +---+
    ((20, 30, 50, 60), (20, 50, 50, 90), True),
    ((20, 50, 50, 90), (20, 30, 50, 60), True),
    # +-----+
    # |     |
    # |  +----+
    # |  | |  |
    # +--|-+  |
    #    |    |
    #    +----+
    ((20, 30, 50, 60), (30, 40, 60, 70), True),
    ((30, 40, 60, 70), (20, 30, 50, 60), True),
))
def test_check_rect_intersection(cpu, math, rect1, rect2, collision):
    arg_prep_code = '\n'.join(
        f'lda #{val}\n'
        f'sta var{i + 1}\n'
        for i, val in enumerate(rect1 + rect2))

    test_code = f'''
        .include "globals.asm"
        .import check_rect_intersection
        {arg_prep_code}
        jsr check_rect_intersection
        brk
    '''

    cpu.compile_and_run(test_code, link_with=[math])

    result = bool(cpu.p & cpu.CARRY)
    assert collision == result
