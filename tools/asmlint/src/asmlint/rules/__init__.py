from dataclasses import dataclass
from enum import Enum


class MessageLevel(Enum):

    WARNING = 'warning'
    ERROR = 'error'


@dataclass
class Message:

    line: int
    char: int
    level: MessageLevel
    message: str
