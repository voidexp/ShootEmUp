import re
from dataclasses import dataclass
from enum import IntEnum


class TokenType(IntEnum):

    EOL = 1
    COMMENT = 2
    IDENTIFIER = 3
    CTRL = 4
    WHITESPACE = 5
    INDENT = 6
    DEDENT = 7
    COLON = 8


@dataclass
class Token:

    type: TokenType
    line: int
    char: int
    value: str = ''


class State(IntEnum):

    DEFAULT = 0
    WHITESPACE = 1
    COMMENT = 2
    IDENTIFIER = 3
    INDENT = 4



RE_WHITESPACE = re.compile(r'\s')
RE_IDENTIFIER_BEGIN = re.compile(r'[A-z_]')
RE_IDENTIFIER = re.compile(r'[A-z0-9_]')


class Lexer:

    def __init__(self, source):
        self.__source = source

    def __iter__(self):
        l = 1
        c = 0
        token = None
        state = State.DEFAULT
        indent_width = 0
        indent = ''
        indent_level = 0

        for char in self.__source:
            if char == '\n':
                if token is not None:
                    yield token
                    token = None
                state = State.DEFAULT
                c = 0
                l += 1
                yield Token(TokenType.EOL, l, c)
                continue
            else:
                c += 1

            if state == State.COMMENT:
                token.value += char

            if state == State.IDENTIFIER:
                if RE_IDENTIFIER.match(char):
                    token.value += char
                else:
                    yield token
                    token = None
                    state = State.DEFAULT

            if state == State.WHITESPACE:
                if RE_WHITESPACE.match(char):
                    token.value += char
                else:
                    yield token
                    token = None
                    state = State.DEFAULT

            if state == State.INDENT:
                if RE_WHITESPACE.match(char):
                    indent += char
                else:
                    new_level = len(indent)

                    # on first indent ever, save the base width
                    if indent_width == 0:
                        indent_width = indent_level = new_level
                        yield Token(TokenType.INDENT, l, indent_width, indent)
                    else:
                        if new_level % indent_width:
                            raise IndentationError(f'{l}: mismatching indentation')

                        if new_level > indent_level:
                            while indent_level != new_level:
                                yield Token(TokenType.INDENT, l, indent_level + indent_width, indent)
                                indent_level += indent_width
                        elif new_level < indent_level:
                            while indent_level != new_level:
                                yield Token(TokenType.DEDENT, l, indent_level - indent_width, indent)
                                indent_level -= indent_width

                    state = State.DEFAULT

            if state == State.DEFAULT:
                if c == 1 and RE_WHITESPACE.match(char):
                    state = State.INDENT
                    indent = char
                    continue

                if char == ';':
                    state = State.COMMENT
                    token = Token(TokenType.COMMENT, l, c)

                elif char == '.':
                    yield Token(TokenType.CTRL, l, c)

                elif char == ':':
                    yield Token(TokenType.COLON, l, c)

                elif RE_WHITESPACE.match(char):
                    state = State.WHITESPACE
                    token = Token(TokenType.WHITESPACE, l, c, char)

                elif RE_IDENTIFIER_BEGIN.match(char):
                    state = State.IDENTIFIER
                    token = Token(TokenType.IDENTIFIER, l, c, char)
