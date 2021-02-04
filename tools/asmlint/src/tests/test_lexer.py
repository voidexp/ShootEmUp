from asmlint.lexer import Lexer, TokenType


def test_empty_lines():
    lex = Lexer('''\n      \nnon_empty\nanother_one\n   \n \n''')

    tokens = list(lex)
    assert len(tokens) == 8
    assert len([t for t in tokens if t.type == TokenType.EOL]) == 6


def test_indentation():
    lex = Lexer('''
        level_one
                level_two
                level_two
                        level_three
        level_one
                level_two
        level_one
                        level_three
    ''')

    indents = [t for t in lex if t.type in (TokenType.INDENT, TokenType.DEDENT)]
    expected = [
        (8,     TokenType.INDENT),
        (16,    TokenType.INDENT),
        (24,    TokenType.INDENT),
        (16,    TokenType.DEDENT),
        (8,     TokenType.DEDENT),
        (16,    TokenType.INDENT),
        (8,     TokenType.DEDENT),
        (16,    TokenType.INDENT),
        (24,    TokenType.INDENT),
    ]
    assert len(indents) == len(expected)
    for i, (column, token) in enumerate(expected):
        assert indents[i].char == column
        assert indents[i].type == token


def test_comments():
    lex = Lexer('''
        ;
        ; this is a comment
        ;;;;;;;;;;;;;;;;;;;;
    ''')

    comments = [t for t in lex if t.type == TokenType.COMMENT]

    comment = comments[0]
    assert comment.line == 2
    assert not comment.value

    comment = comments[1]
    assert comment.line == 3
    assert comment.value == ' this is a comment'

    comment = comments[2]
    assert comment.line == 4
    assert comment.value == ';' * 19


def test_commands():
    lex = Lexer('''
        .proc some_procedure:
                ; some assembly
        .endproc
    ''')

    tokens = [t for t in lex if t.type in (TokenType.CTRL, TokenType.COLON, TokenType.IDENTIFIER)]

    assert tokens[0].type == TokenType.CTRL
    assert tokens[0].line == 2
    assert tokens[1].type == TokenType.IDENTIFIER
    assert tokens[1].value == 'proc'
    assert tokens[1].line == 2

    assert tokens[2].type == TokenType.IDENTIFIER
    assert tokens[2].value == 'some_procedure'
    assert tokens[2].line == 2

    assert tokens[3].type == TokenType.COLON
    assert tokens[3].line == 2

    assert tokens[4].type == TokenType.CTRL
    assert tokens[4].line == 4
    assert tokens[5].type == TokenType.IDENTIFIER
    assert tokens[5].value == 'endproc'
    assert tokens[5].line == 4
