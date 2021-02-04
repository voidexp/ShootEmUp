from itertools import chain
import click
from asmlint.lexer import Lexer
from asmlint.rules.comments import check_subroutine_doc


CHECKS = [
    check_subroutine_doc,
]


@click.command()
@click.argument('src', nargs=-1, type=click.File(mode='r'))
def lint(src):
    for fp in src:
        lex = Lexer(fp.read())
        tokens = list(lex)
        messages = chain.from_iterable(check(tokens) for check in CHECKS)
        for msg in messages:
            print(f'{fp.name} {msg.line},{msg.char}: {msg.message}')


if __name__ == '__main__':
    lint()  # pylint: disable=no-value-for-parameter
