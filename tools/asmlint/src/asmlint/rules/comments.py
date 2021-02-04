from asmlint.rules import Message, MessageLevel
from asmlint.lexer import Token, TokenType
from typing import List, Any, Tuple


TMPL_NO_SUBROUTINE_COMMENT = 'no doc comment for subroutine "{}"'


def find_token_sequences(tokens: List[Token], pattern: List[Tuple[Token, Any]]):
    cursor = 0
    end = len(pattern)

    for i, tok in enumerate(tokens):
        exp_type, exp_value = pattern[cursor]
        if tok.type == exp_type and (exp_value is None or tok.value == exp_value):
            cursor += 1

            if cursor == end:
                yield i - (end - 1)
                cursor = 0
        else:
            cursor = 0


def check_subroutine_doc(tokens: List[Token]):
    pattern = [
        (TokenType.CTRL, None),
        (TokenType.IDENTIFIER, 'proc'),
        (TokenType.WHITESPACE, None),
        (TokenType.IDENTIFIER, None),
        (TokenType.COLON, None),
    ]

    for i in find_token_sequences(tokens, pattern):
        has_comment = False
        if i > 0:
            j = i
            while j:
                j -= 1
                tok = tokens[j]
                if tok.type in (TokenType.EOL, TokenType.WHITESPACE, TokenType.INDENT):
                    continue
                if tok.type == TokenType.COMMENT:
                    has_comment = len(tok.value.strip()) > 1
                    break
                else:
                    break

        if not has_comment:
            name = tokens[i + 3]
            yield Message(
                name.line,
                name.char,
                MessageLevel.ERROR,
                TMPL_NO_SUBROUTINE_COMMENT.format(name.value))
