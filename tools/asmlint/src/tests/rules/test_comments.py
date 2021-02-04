from asmlint.lexer import Lexer
from asmlint.rules import MessageLevel
from asmlint.rules.comments import check_subroutine_doc, TMPL_NO_SUBROUTINE_COMMENT


def test_subroutine_without_doc_comment():
    lex = Lexer('''
        .proc undocumented_subroutine:
        .endproc
    ''')

    tokens = list(lex)

    messages = list(check_subroutine_doc(tokens))

    assert messages
    assert messages[0].level == MessageLevel.ERROR
    assert messages[0].line == 2
    assert messages[0].message == TMPL_NO_SUBROUTINE_COMMENT.format('undocumented_subroutine')


def test_subroutine_with_doc_comment():
    lex = Lexer('''
        ; A simple subroutine which does nothing
        .proc a_better_subroutine:
                ; do nothing
        .endproc
    ''')

    tokens = list(lex)

    messages = list(check_subroutine_doc(tokens))

    assert not messages
