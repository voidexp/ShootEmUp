import re
from enum import Enum
from typing import Optional, Tuple

import click

INSTR_SET_6502 = {
    'ADC', 'AND', 'ASL', 'BCC', 'BCS', 'BEQ', 'BIT', 'BMI', 'BNE', 'BPL',
    'BRK', 'BVC', 'BVS', 'CLC', 'CLD', 'CLI', 'CLV', 'CMP', 'CPX', 'CPY',
    'DEC', 'DEX', 'DEY', 'EOR', 'INC', 'INX', 'INY', 'JMP', 'JSR', 'LDA',
    'LDX', 'LDY', 'LSR', 'NOP', 'ORA', 'PHA', 'PHP', 'PLA', 'PLP', 'ROL',
    'ROR', 'RTI', 'RTS', 'SBC', 'SEC', 'SED', 'SEI', 'STA', 'STX', 'STY',
    'TAX', 'TAY', 'TSX', 'TXA', 'TXS', 'TYA',
}

TAB_SIZE = 4
LABEL_COLUMN_WIDTH = TAB_SIZE * 3
CODE_COLUMN_WIDTH = TAB_SIZE * 6


class State(Enum):
    DEFAULT = 'default'
    INSTRUCTION = 'instruction'
    COMMAND = 'command'


def adjust_comment_padding(line: str, width: int) -> str:
    pass


def adjust_indent_level(line: str, indents: int) -> str:
    pass


def parse_instruction(line) -> Optional[Tuple[str, str, str]]:
    """
    Parse an instruction line.

    Returns a tuple in form (label, instruction, comment) if it's a valid
    instruction line, otherwise None.
    """
    line = re.sub(r'\s+', ' ', line).strip()
    label_mo = re.search(r'^([@_A-z0-9]*:)', line)
    label = (label_mo.groups()[0] if label_mo else '')

    comment_mo = re.search(r'(;.*)$', line)
    comment = (comment_mo.groups()[0] if comment_mo else '')

    instruction = line[len(label):].strip()
    if comment:
        index = instruction.index(';')
        instruction = instruction[:index].strip()

    if instruction[:3].upper() in INSTR_SET_6502:
        return label, instruction, comment


def parse_command(line) -> Optional[Tuple[str, str]]:
    """
    Parse a ca65 assembler preprocessor command.

    Returns a tuple in form (command, arguments) if it's a valid command line.
    """
    line = line.strip()
    cmd_mo = re.search(r'^(\.(?:\w|\d))+', line)
    if cmd_mo:
        cmd = cmd_mo.groups()[0]
        args = line[len(cmd):]
        return cmd, args


def calc_min_tab_width(width, tab_size):
    return width + (tab_size - width % tab_size)


def lint(file_path, autofix=False, print_only=False):
    result = []
    lines = []
    with open(file_path) as fp:
        lines.extend(fp.readlines())

    state = State.DEFAULT
    block = []

    while lines:
        line = lines[0]

        if state is State.DEFAULT:
            if parse_instruction(line):
                state = State.INSTRUCTION
                continue

            # if parse_command(line):
            #     state = State.COMMAND
            #     continue

            else:
                result.append(line)
                lines.pop(0)

        elif state is State.INSTRUCTION:
            instr_tuple = parse_instruction(line)
            if instr_tuple:
                block.append(instr_tuple)
                lines.pop(0)
            else:
                for instr_tuple in block:
                    label, instr, comment = instr_tuple
                    label_padding = ' ' * (LABEL_COLUMN_WIDTH - len(label))
                    comment_padding = ' ' * (CODE_COLUMN_WIDTH - len(instr))
                    result.append(label + label_padding + (instr + comment_padding + comment).strip() + '\n')

                state = State.DEFAULT
                block.clear()

    if autofix:
        if print_only:
            print(''.join(result))
        else:
            with open(file_path, 'w') as fp:
                fp.writelines(result)


@click.command()
@click.argument('files', type=click.Path(exists=True, dir_okay=False, file_okay=True, readable=True, writable=True), nargs=-1)
@click.option('-f/--format', is_flag=True, default=False, help='Auto format the code')
@click.option('-p/--print', is_flag=True, default=False, help='Just print without overwriting the file')
def asmfmt(files, f, p):
    for f in files:
        lint(f, autofix=f, print_only=p)


if __name__ == '__main__':
    asmfmt()
